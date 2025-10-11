import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save calculated goals to Firebase
  static Future<void> saveGoals(Map<String, dynamic> goalsData) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final goalsDoc = {
        'userId': currentUser.uid,
        'calories': goalsData['calories'] ?? 0,
        'protein': goalsData['protein'] ?? 0,
        'carbs': goalsData['carbs'] ?? 0,
        'fat': goalsData['fat'] ?? 0,
        'fiber': goalsData['fiber'] ?? 0,
        'bmr': goalsData['bmr'] ?? 0,
        'tdee': goalsData['tdee'] ?? 0,
        'explanation': goalsData['explanation'] ?? '',
        'calculatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('goals')
          .set(goalsDoc, SetOptions(merge: true));

      print('GoalsService: Goals saved successfully');
    } catch (e) {
      print('GoalsService: Error saving goals: $e');
      rethrow;
    }
  }

  /// Get saved goals from Firebase
  static Future<Map<String, dynamic>?> getGoals() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final goalsDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('goals')
          .get();

      if (!goalsDoc.exists) return null;

      final data = goalsDoc.data() as Map<String, dynamic>;

      // Convert timestamps
      if (data['calculatedAt'] != null) {
        data['calculatedAt'] = (data['calculatedAt'] as Timestamp).toDate();
      }
      if (data['createdAt'] != null) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      if (data['updatedAt'] != null) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
      }

      return data;
    } catch (e) {
      print('GoalsService: Error getting goals: $e');
      return null;
    }
  }

  /// Check if goals exist
  static Future<bool> hasExistingGoals() async {
    try {
      final goalsData = await getGoals();
      return goalsData != null;
    } catch (e) {
      print('GoalsService: Error checking goals existence: $e');
      return false;
    }
  }

  /// Stream for goals updates
  static Stream<Map<String, dynamic>?> goalsStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('onboardingDetails')
        .doc('goals')
        .snapshots()
        .map<Map<String, dynamic>?>((doc) {
          if (!doc.exists) return null;

          final data = doc.data() as Map<String, dynamic>;

          // Convert timestamps
          if (data['calculatedAt'] != null) {
            data['calculatedAt'] = (data['calculatedAt'] as Timestamp).toDate();
          }
          if (data['createdAt'] != null) {
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
          }
          if (data['updatedAt'] != null) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
          }

          return data;
        })
        .handleError((error) {
          print('GoalsService: Error in goals stream: $error');
          return Stream.value(null);
        });
  }
}
