import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WorkoutPlannerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate workout plan using Gemini API
  static Future<Map<String, dynamic>?> generateWorkoutPlan({
    required String fitnessGoals,
    required String fitnessLevel,
    required String workoutType,
    required String planDuration,
    Map<String, dynamic>? onboardingData,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found in environment variables');
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      // Build user context from onboarding data
      String userContext = '';
      if (onboardingData != null) {
        userContext = '''
User Profile:
- Age: ${_calculateAge(onboardingData['dateOfBirth'])} years
- Gender: ${onboardingData['gender'] ?? 'Not specified'}
- Weight: ${onboardingData['weightKg'] ?? 'Not specified'} kg
- Height: ${onboardingData['heightCm'] ?? 'Not specified'} cm
- Activity Level: ${onboardingData['workoutFrequency'] ?? 'Not specified'}
        ''';
      }

      final prompt = '''
You are a certified fitness trainer AI. Generate a comprehensive workout plan based on the following information:

$userContext

Workout Preferences:
- Fitness Goals: $fitnessGoals
- Current Fitness Level: $fitnessLevel
- Preferred Workout Type: $workoutType
- Plan Duration: $planDuration

Please provide a structured workout plan in the following JSON format:
{
  "title": "Workout Plan Title",
  "duration": "$planDuration",
  "workoutType": "$workoutType",
  "fitnessLevel": "$fitnessLevel",
  "overview": "Brief overview of the plan with warm-up and cool-down instructions",
  "schedule": [
    {
      "day": 1,
      "title": "Day 1 - Workout Name",
      "type": "workout",
      "exercises": [
        {
          "name": "Exercise Name",
          "sets": 3,
          "reps": "12-15",
          "rest": "60 seconds",
          "notes": "Form tips or modifications"
        }
      ]
    }
  ],
  "tips": [
    "Specific tip for this plan",
    "Another helpful tip",
    "Safety considerations"
  ]
}

Requirements:
1. Create a realistic plan for the specified duration (3, 5, 7, 14, or 21 days)
2. Include proper warm-up and cool-down instructions in the overview
3. Adjust intensity and complexity based on fitness level
4. Focus on the specified workout type:
   - "Home Workout": bodyweight exercises, minimal equipment
   - "Gym Workout": gym equipment, machines, free weights
   - "Any": mix of home and gym exercises with alternatives
5. Ensure exercises align with the fitness goals
6. Provide clear instructions and modifications for beginners
7. Include rest days for longer plans (7+ days) - mark these as {"day": X, "title": "Day X - Rest Day", "type": "rest"}
8. Make sure exercises are safe and appropriate for the fitness level
9. Include progressive overload suggestions for intermediate/advanced levels
10. Provide equipment alternatives for home workouts

Return only valid JSON without any markdown formatting or additional text.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      // Clean the response text
      String jsonString = response.text!.trim();

      // Remove markdown code block markers if present
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.substring(7);
      }
      if (jsonString.startsWith('```')) {
        jsonString = jsonString.substring(3);
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3);
      }

      jsonString = jsonString.trim();

      // Parse JSON
      final Map<String, dynamic> planData = json.decode(jsonString);

      // Add metadata
      planData['generatedAt'] = DateTime.now();
      planData['userId'] = _auth.currentUser?.uid;
      planData['fitnessGoals'] = fitnessGoals;
      planData['fitnessLevel'] = fitnessLevel;
      planData['workoutType'] = workoutType;
      planData['planDuration'] = planDuration;

      return planData;
    } catch (e) {
      print('Error generating workout plan: $e');
      return null;
    }
  }

  // Save workout plan to Firebase under users/{userId}/gymkitDetails collection
  static Future<void> saveWorkoutPlan(Map<String, dynamic> planData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gymkitDetails')
          .doc('workoutPlan')
          .set(planData, SetOptions(merge: false)); // Override existing plan

      print('Workout plan saved successfully');
    } catch (e) {
      print('Error saving workout plan: $e');
      throw Exception('Failed to save workout plan: ${e.toString()}');
    }
  }

  // Get saved workout plan from Firebase under users/{userId}/gymkitDetails collection
  static Future<Map<String, dynamic>?> getSavedWorkoutPlan() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gymkitDetails')
          .doc('workoutPlan')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Convert Firestore Timestamp to DateTime if needed
        if (data['generatedAt'] is Timestamp) {
          data['generatedAt'] = (data['generatedAt'] as Timestamp).toDate();
        }
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting saved workout plan: $e');
      return null;
    }
  }

  // Generate workout plan text for download
  static String generateWorkoutPlanText(Map<String, dynamic> planData) {
    final StringBuffer buffer = StringBuffer();

    // Header
    buffer.writeln('🏋️ ${planData['title'] ?? 'AI Generated Workout Plan'}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Plan Details
    buffer.writeln('📋 Plan Details:');
    buffer.writeln('• Duration: ${planData['duration'] ?? planData['planDuration']}');
    buffer.writeln('• Workout Type: ${planData['workoutType']}');
    buffer.writeln('• Fitness Level: ${planData['fitnessLevel']}');
    buffer.writeln('• Goals: ${planData['fitnessGoals']}');
    if (planData['generatedAt'] != null) {
      final date = planData['generatedAt'] is DateTime
          ? planData['generatedAt'] as DateTime
          : DateTime.now();
      buffer.writeln('• Generated: ${date.day}/${date.month}/${date.year}');
    }
    buffer.writeln();

    // Overview
    if (planData['overview'] != null) {
      buffer.writeln('📖 Overview:');
      buffer.writeln(planData['overview']);
      buffer.writeln();
    }

    // Schedule
    if (planData['schedule'] != null && planData['schedule'] is List) {
      buffer.writeln('📅 Workout Schedule:');
      buffer.writeln();

      final schedule = planData['schedule'] as List;
      for (var dayData in schedule) {
        buffer.writeln('${dayData['title'] ?? 'Day ${dayData['day']}'}');
        buffer.writeln('-' * 30);

        if (dayData['type'] == 'rest') {
          buffer.writeln('🛌 Rest Day - Take time to recover and let your muscles repair.');
          buffer.writeln('• Light stretching or walking is encouraged');
          buffer.writeln('• Stay hydrated and get adequate sleep');
          buffer.writeln('• Listen to your body');
          buffer.writeln();
        } else if (dayData['exercises'] != null && dayData['exercises'] is List) {
          final exercises = dayData['exercises'] as List;
          for (int i = 0; i < exercises.length; i++) {
            final exercise = exercises[i];
            buffer.writeln('${i + 1}. ${exercise['name']}');

            if (exercise['sets'] != null) {
              buffer.writeln('   Sets: ${exercise['sets']}');
            }
            if (exercise['reps'] != null) {
              buffer.writeln('   Reps: ${exercise['reps']}');
            }
            if (exercise['rest'] != null) {
              buffer.writeln('   Rest: ${exercise['rest']}');
            }
            if (exercise['notes'] != null) {
              buffer.writeln('   Notes: ${exercise['notes']}');
            }
            buffer.writeln();
          }
        }
        buffer.writeln();
      }
    }

    // Custom Tips from AI
    if (planData['tips'] != null && planData['tips'] is List) {
      buffer.writeln('💡 Plan-Specific Tips:');
      final tips = planData['tips'] as List;
      for (var tip in tips) {
        buffer.writeln('• $tip');
      }
      buffer.writeln();
    }

    // General Tips (hardcoded)
    buffer.writeln('💪 General Tips:');
    buffer.writeln('• Warm-up before each workout with light cardio and dynamic stretching.');
    buffer.writeln('• Cool-down with static stretches, holding each stretch for 20-30 seconds.');
    buffer.writeln('• Stay hydrated by drinking plenty of water throughout the day.');
    buffer.writeln('• Listen to your body and take rest days when needed.');
    buffer.writeln();

    buffer.writeln('Generated by TrackAI - Your AI Fitness Companion');

    return buffer.toString();
  }

  // Helper method to calculate age
  static int _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 25; // Default age

    DateTime birthDate;
    if (dateOfBirth is Timestamp) {
      birthDate = dateOfBirth.toDate();
    } else if (dateOfBirth is DateTime) {
      birthDate = dateOfBirth;
    } else {
      return 25; // Default age
    }

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}