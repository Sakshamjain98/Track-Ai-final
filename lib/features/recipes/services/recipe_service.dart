import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../library/services/cloudinary_service.dart';

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'recipes';

  /// Create recipe: Upload image to Cloudinary, save data to Firestore
  static Future<String> createRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> instructions,
    required String difficulty,
    required int prepTime,
    required int cookTime,
    required int servings,
    XFile? imageFile,
  }) async {
    try {
      print('👨‍🍳 Creating recipe: $title');

      String? imageUrl;
      String? imagePublicId;

      // Upload image to Cloudinary
      if (imageFile != null) {
        try {
          print('📤 Uploading to Cloudinary...');
          final uploadResult = await CloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: 'recipes',
            tags: {
              'type': 'recipe',
              'difficulty': difficulty.toLowerCase(),
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );

          imageUrl = uploadResult.secureUrl;
          imagePublicId = uploadResult.publicId;
          print('✅ Image uploaded: $imageUrl');
        } catch (e) {
          print('❌ Cloudinary upload error: $e');
          // Continue without image
        }
      }

      // Validate data
      if (title.trim().isEmpty) {
        throw RecipeException('Recipe title is required.');
      }
      if (ingredients.isEmpty) {
        throw RecipeException('At least one ingredient is required.');
      }
      if (instructions.isEmpty) {
        throw RecipeException('Cooking instructions are required.');
      }

      // Save to Firestore
      final recipeData = {
        'title': title.trim(),
        'description': description.trim(),
        'ingredients': ingredients.map((e) => e.trim()).toList(),
        'instructions': instructions.map((e) => e.trim()).toList(),
        'difficulty': difficulty,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,

        // Cloudinary image data
        'imageUrl': imageUrl,
        'imagePublicId': imagePublicId,

        // Metadata with sorting timestamp
        'createdAt': FieldValue.serverTimestamp(),
        'sortTimestamp': DateTime.now().millisecondsSinceEpoch, // For manual sorting
        'createdBy': _auth.currentUser?.uid ?? 'anonymous',
        'createdByEmail': _auth.currentUser?.email ?? 'anonymous',
        'isActive': true,
        'views': 0,
        'likes': 0,
        'rating': 0.0,
        'platform': 'cloudinary',
        'uploadedFrom': 'mobile_app',
      };

      final docRef = await _firestore.collection(_collection).add(recipeData);
      print('✅ Recipe saved: ${docRef.id}');

      return docRef.id;
    } on RecipeException {
      rethrow;
    } catch (e) {
      print('❌ Recipe creation error: $e');
      throw RecipeException('Failed to create recipe: ${e.toString()}');
    }
  }

  /// SMART Get all recipes - Automatically handles index issues
  static Stream<List<Map<String, dynamic>>> getRecipesStream() {
    print('🔍 Starting smart recipes stream...');

    // Try optimized query first, fallback to simple query if index missing
    return _tryOptimizedQuery().handleError((error) {
      print('⚠️ Optimized query failed, using fallback: $error');
      return _getFallbackQuery();
    });
  }

  /// Try the optimized query with compound index
  static Stream<List<Map<String, dynamic>>> _tryOptimizedQuery() {
    print('🚀 Trying optimized query with index...');

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => _processRecipeSnapshots(snapshot))
        .handleError((error) {
      print('❌ Optimized query failed: $error');
      throw error; // This will trigger the fallback
    });
  }

  /// Fallback query without compound index requirement
  static Stream<List<Map<String, dynamic>>> _getFallbackQuery() {
    print('🔄 Using fallback query (no index required)...');

    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      print('📊 Fallback found ${snapshot.docs.length} recipes');

      // Sort manually by sortTimestamp (faster than createdAt comparison)
      final sortedDocs = snapshot.docs.toList();
      sortedDocs.sort((a, b) {
        final aTime = a.data()['sortTimestamp'] as int? ?? 0;
        final bTime = b.data()['sortTimestamp'] as int? ?? 0;
        return bTime.compareTo(aTime); // Descending order (newest first)
      });

      return _processRecipeList(sortedDocs);
    });
  }

  /// Process Firestore snapshots into recipe list
  static List<Map<String, dynamic>> _processRecipeSnapshots(QuerySnapshot snapshot) {
    print('📊 Processing ${snapshot.docs.length} recipes from optimized query');
    return _processRecipeList(snapshot.docs);
  }

  /// Process list of documents into recipe data
  static List<Map<String, dynamic>> _processRecipeList(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        print('📄 Processing recipe: ${data['title']}');

        // Generate Cloudinary URLs for cards
        if (data['imagePublicId'] != null) {
          try {
            data['cardImageUrl'] = CloudinaryService.getOptimizedUrl(
              data['imagePublicId'],
              width: 400,
              height: 300,
              quality: '80',
            );
            data['thumbnailUrl'] = CloudinaryService.getOptimizedUrl(
              data['imagePublicId'],
              width: 200,
              height: 150,
              quality: '60',
            );
            print('✅ Generated image URLs for: ${data['title']}');
          } catch (e) {
            print('❌ Error generating image URLs for ${data['title']}: $e');
            data['cardImageUrl'] = data['imageUrl']; // Fallback
            data['thumbnailUrl'] = data['imageUrl'];
          }
        } else {
          print('ℹ️ No image for recipe: ${data['title']}');
        }

        return data;
      } catch (e) {
        print('❌ Error processing recipe doc: $e');
        return <String, dynamic>{
          'id': doc.id,
          'title': 'Error loading recipe',
          'error': true,
        };
      }
    }).toList();
  }

  /// Get single recipe by ID
  static Future<Map<String, dynamic>?> getRecipeById(String id) async {
    try {
      print('🔍 Fetching recipe: $id');

      if (id.trim().isEmpty) {
        throw RecipeException('Invalid recipe ID.');
      }

      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) {
        throw RecipeException('Recipe not found. It may have been deleted.');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      print('✅ Found recipe: ${data['title']}');

      // Generate high-quality image URL for details
      if (data['imagePublicId'] != null) {
        try {
          data['highResImageUrl'] = CloudinaryService.getOptimizedUrl(
            data['imagePublicId'],
            width: 800,
            height: 600,
            quality: 'auto',
          );
        } catch (e) {
          print('❌ Error generating high-res image URL: $e');
          data['highResImageUrl'] = data['imageUrl'];
        }
      }

      return data;
    } catch (e) {
      print('❌ Error fetching recipe: $e');
      if (e is RecipeException) {
        rethrow;
      }
      throw RecipeException('Failed to load recipe details: ${e.toString()}');
    }
  }

  /// Increment recipe views
  static Future<void> incrementViews(String id) async {
    try {
      if (id.trim().isEmpty) return;

      await _firestore.collection(_collection).doc(id).update({
        'views': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      });
      print('✅ Incremented views for: $id');
    } catch (e) {
      print('❌ Failed to increment views: $e');
    }
  }

  /// Get recipes count
  static Future<int> getRecipesCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting recipe count: $e');
      return 0;
    }
  }

  /// Test connection
  static Future<bool> testConnection() async {
    try {
      print('🔥 Testing Recipe Service connections...');

      // Test Firestore
      await _firestore.collection('test').limit(1).get();
      print('✅ Firestore: Connected');

      // Test if recipes collection exists
      final recipesSnapshot = await _firestore.collection(_collection).limit(1).get();
      print('✅ Recipes collection: ${recipesSnapshot.docs.length} docs found');

      print('🎉 All services working!');
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}

/// Custom Recipe Exception
class RecipeException implements Exception {
  final String message;
  RecipeException(this.message);

  @override
  String toString() => message;
}
