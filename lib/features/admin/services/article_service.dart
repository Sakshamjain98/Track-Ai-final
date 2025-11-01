// lib/article_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../library/services/cloudinary_service.dart' show CloudinaryUploadResult, CloudinaryService;
import 'ManageReviewersScreen.dart';
// --- 1. ADD IMPORT FOR YOUR NEW SERVICE ---

class ArticleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'articles';

  // --- 2. REMOVED the old _uploadImageToCloud function ---
  // (The placeholder function is no longer needed)

  // --- 3. CREATE ARTICLE FUNCTION (UPDATED) ---
  static Future<String> createArticle({
    required String title,
    required String category,
    required String content,
    required Reviewer reviewer,
    XFile? imageFile,
    Function(double)? onProgress,
    required String takeaway,
    required List<String> references,
  }) async {
    try {
      if (imageFile == null) {
        throw Exception('A cover image is required.');
      }

      onProgress?.call(0.3); // 30% - Starting upload

      // --- 4. USE THE NEW CLOUDINARY SERVICE ---
      print('Uploading article image...');
      final CloudinaryUploadResult uploadResult =
      await CloudinaryService.uploadImage(
        imageFile: imageFile,
        folder: 'articles', // <-- Specify the folder
      );
      final String imageUrl = uploadResult.secureUrl;
      print('Article image uploaded: $imageUrl');
      // ------------------------------------------

      onProgress?.call(0.7); // 70% - Image uploaded, saving to DB

      final articleData = {
        'title': title,
        'category': category,
        'content': content,
        'imageUrl': imageUrl, // <-- Use the new URL
        'publishedAt': FieldValue.serverTimestamp(),
        'takeaway': takeaway,
        'references': references,
        'reviewer': {
          'id': reviewer.id,
          'name': reviewer.name,
          'title': reviewer.title,
          'imageUrl': reviewer.imageUrl,
          'location': reviewer.location,
          'linkedInUrl': reviewer.linkedInUrl,
          'quote': reviewer.quote,
          'expertise': reviewer.expertise,
          'education': reviewer.education,
          'awards': reviewer.awards,
        }
      };

      final docRef = await _firestore.collection(_collection).add(articleData);

      onProgress?.call(1.0); // 100% - Done
      return docRef.id;
    } catch (e) {
      // Re-throw the error to be caught by the UI
      rethrow;
    }
  }
}