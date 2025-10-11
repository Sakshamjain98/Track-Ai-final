import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> saveOnboardingData(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print(
        'OnboardingService: Saving onboarding data for user: ${currentUser.email}',
      );

      final onboardingDoc = {
        'userId': currentUser.uid,
        'email': currentUser.email,
        'gender': onboardingData['gender'] ?? '',
        'workoutFrequency': onboardingData['workoutFrequency'] ?? '',
        'heightFeet': onboardingData['heightFeet'] ?? 0,
        'heightInches': onboardingData['heightInches'] ?? 0,
        'heightCm': onboardingData['heightCm'] ?? 0,
        'weightLbs': onboardingData['weightLbs'] ?? 0.0,
        'weightKg': onboardingData['weightKg'] ?? 0.0,
        'isMetric': onboardingData['isMetric'] ?? false,
        'dateOfBirth': onboardingData['dateOfBirth'] != null
            ? Timestamp.fromDate(onboardingData['dateOfBirth'] as DateTime)
            : null,
        'goal': onboardingData['goal'] ?? '',
        'desiredWeight': onboardingData['desiredWeight'] ?? 0.0,
        'goalPace': onboardingData['goalPace'] ?? '',
        'dietPreference': onboardingData['dietPreference'] ?? '',
        'targetAmountKg': onboardingData['targetAmountKg'] ?? 0.0,
        'targetAmountLbs': onboardingData['targetAmountLbs'] ?? 0.0,
        'targetUnit': onboardingData['targetUnit'] ?? '',
        'targetTimeframe': onboardingData['targetTimeframe'] ?? 0,
        'completedAt': onboardingData['completedAt'] != null
            ? Timestamp.fromDate(onboardingData['completedAt'] as DateTime)
            : FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save onboarding details
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('profile')
          .set(onboardingDoc, SetOptions(merge: true));

      // ✅ Fix: update → set with merge
      await _firestore.collection('users').doc(currentUser.uid).set({
        'onboardingCompleted': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('OnboardingService: Onboarding data saved successfully');
    } catch (e) {
      print('OnboardingService: Error saving onboarding data: $e');
      rethrow;
    }
  }

  /// Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      return data['onboardingCompleted'] ?? false;
    } catch (e) {
      print('OnboardingService: Error checking onboarding status: $e');
      return false;
    }
  }

  /// Stream to check if user has completed onboarding
  static Stream<bool> onboardingCompletionStream() {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map<bool>((doc) {
          if (!doc.exists) {
            return false;
          }
          final data = doc.data();
          return data?['onboardingCompleted'] ?? false;
        })
        .handleError((error) {
          print('OnboardingService: Error in onboarding stream: $error');
          return Stream.value(false);
        });
  }

  /// Get onboarding data for current user
  static Future<Map<String, dynamic>?> getOnboardingData() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      final onboardingDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('profile')
          .get();

      if (!onboardingDoc.exists) {
        return null;
      }

      final data = onboardingDoc.data() as Map<String, dynamic>;

      // Convert Timestamp back to DateTime
      if (data['dateOfBirth'] != null) {
        data['dateOfBirth'] = (data['dateOfBirth'] as Timestamp).toDate();
      }
      if (data['completedAt'] != null) {
        data['completedAt'] = (data['completedAt'] as Timestamp).toDate();
      }
      if (data['createdAt'] != null) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      if (data['updatedAt'] != null) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
      }

      return data;
    } catch (e) {
      print('OnboardingService: Error getting onboarding data: $e');
      return null;
    }
  }

  /// Update specific onboarding data
  static Future<void> updateOnboardingData(Map<String, dynamic> updates) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('profile')
          .set(updates, SetOptions(merge: true)); // ✅ replaces update()

      print('OnboardingService: Onboarding data saved/updated successfully');
    } catch (e) {
      print('OnboardingService: Error updating onboarding data: $e');
      rethrow;
    }
  }

  /// Calculate BMI based on onboarding data
  static double? calculateBMI(Map<String, dynamic> onboardingData) {
    try {
      final bool isMetric = onboardingData['isMetric'] ?? false;

      if (isMetric) {
        final double? weightKg = onboardingData['weightKg']?.toDouble();
        final int? heightCm = onboardingData['heightCm'];

        if (weightKg != null && heightCm != null && heightCm > 0) {
          final heightM = heightCm / 100;
          return weightKg / (heightM * heightM);
        }
      } else {
        final double? weightLbs = onboardingData['weightLbs']?.toDouble();
        final int? heightFeet = onboardingData['heightFeet'];
        final int? heightInches = onboardingData['heightInches'];

        if (weightLbs != null && heightFeet != null && heightInches != null) {
          final totalInches = (heightFeet * 12) + heightInches;
          if (totalInches > 0) {
            return (weightLbs / (totalInches * totalInches)) * 703;
          }
        }
      }
      return null;
    } catch (e) {
      print('OnboardingService: Error calculating BMI: $e');
      return null;
    }
  }

  /// Calculate age from date of birth
  static int? calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;

    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  /// Reset onboarding data (for testing purposes)
  static Future<void> resetOnboardingData() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Delete onboarding details
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('onboardingDetails')
          .doc('profile')
          .delete();

      // Update main user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'onboardingCompleted': false,
        'onboardingCompletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('OnboardingService: Onboarding data reset successfully');
    } catch (e) {
      print('OnboardingService: Error resetting onboarding data: $e');
      rethrow;
    }
  }
}
