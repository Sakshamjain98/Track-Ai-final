import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit feedback to Firestore
  static Future<bool> submitFeedback({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;

      await _firestore.collection('feedback').add({
        'email': email.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
        'userId': user?.uid,
        'userEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });

      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
}
