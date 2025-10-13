import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RecipeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'recipes';

  /// Create a new recipe
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
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadRecipeImage(imageFile);
      }

      final docRef = await _firestore.collection(_collection).add({
        'title': title.trim(),
        'description': description.trim(),
        'ingredients': ingredients.map((e) => e.trim()).toList(),
        'instructions': instructions.map((e) => e.trim()).toList(),
        'difficulty': difficulty,
        'prepTime': prepTime,
        'cookTime': cookTime,
        'servings': servings,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'views': 0,
        'likes': 0,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  /// Upload recipe image to Firebase Storage
  static Future<String> _uploadRecipeImage(XFile imageFile) async {
    try {
      final String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('recipes').child(fileName);
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get all recipes stream
  static Stream<List<Map<String, dynamic>>> getRecipesStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get all recipes (one-time fetch)
  static Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Get recipe by ID
  static Future<Map<String, dynamic>?> getRecipeById(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  /// Update recipe
  static Future<void> updateRecipe(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  /// Delete recipe
  static Future<void> deleteRecipe(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  /// Increment recipe views
  static Future<void> incrementViews(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Fail silently for view counting
      print('Failed to increment views: $e');
    }
  }

  /// Like/Unlike recipe
  static Future<void> toggleLike(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to update likes: $e');
    }
  }
}
