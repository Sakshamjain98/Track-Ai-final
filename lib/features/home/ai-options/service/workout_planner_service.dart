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
    List<String>? focusAreas,
    int? durationPerWorkout,
    String? preferredTime,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
        ),
      );

      String userContext = '';
      if (onboardingData != null) {
        userContext = '''
User Profile:
- Age: ${_calculateAge(onboardingData['dateOfBirth'])} years
- Gender: ${onboardingData['gender'] ?? 'Not specified'}
- Weight: ${onboardingData['weightKg'] ?? 'Not specified'} kg
- Height: ${onboardingData['heightCm'] ?? 'Not specified'} cm
        ''';
      }

      final prompt = '''
You are a world-class certified fitness trainer AI. Generate a comprehensive, personalized workout plan.

$userContext

Workout Preferences:
- Fitness Goals: $fitnessGoals
- Current Fitness Level: $fitnessLevel
- Preferred Workout Type: $workoutType
- Plan Duration: $planDuration
- Focus Areas: ${focusAreas?.join(', ') ?? 'Full Body'}
- Duration per Workout: ${durationPerWorkout != null ? '$durationPerWorkout minutes' : 'Not specified'}
- Preferred Time of Day: ${preferredTime ?? 'Any'}

CRITICAL: You MUST respond with ONLY valid JSON. Do not include markdown, code blocks, or any text outside the JSON object.

Provide the plan in this EXACT JSON format:
{
  "planTitle": "Creative and Motivational Plan Title",
  "introduction": "A brief, encouraging introduction to the plan, including warm-up and cool-down advice.",
  "weeklySchedule": [
    {
      "day": "Day 1",
      "activity": "Workout Focus (e.g., Upper Body Strength)",
      "duration": "Estimated duration in minutes (e.g., 45 minutes)",
      "details": [
        {
          "name": "Exercise Name",
          "instruction": "Sets, reps, and rest info (e.g., 3 sets of 10-12 reps, 60s rest)"
        }
      ]
    },
    {
      "day": "Day 2",
      "activity": "Rest or Active Recovery",
      "duration": "20 minutes",
      "details": [
         {
          "name": "Light Stretching or Walking",
          "instruction": "Focus on flexibility and recovery."
        }
      ]
    }
  ],
  "generalTips": [
    "A specific, actionable tip for this plan.",
    "Another helpful tip related to nutrition or hydration.",
    "A tip about listening to your body or ensuring proper form."
  ]
}

Key Requirements:
1.  Adjust intensity based on the fitness level: '$fitnessLevel'.
2.  For '$workoutType', prioritize exercises accordingly (bodyweight for home, machines/weights for gym).
3.  Ensure exercises align with the '$fitnessGoals' and focus areas.
4.  For longer plans (7+ days), intelligently include rest or active recovery days.
5.  The 'instruction' field for each exercise must be a single, clear string.

REMEMBER: Output ONLY the JSON object. No markdown, no explanations, just pure JSON.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      String jsonString = response.text!.trim();
      jsonString = jsonString
          .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();

      if (!jsonString.startsWith('{') || !jsonString.endsWith('}')) {
        throw Exception('Invalid JSON format received from API');
      }

      final planData = json.decode(jsonString) as Map<String, dynamic>;

      if (!planData.containsKey('planTitle') || !planData.containsKey('weeklySchedule')) {
        throw Exception('Invalid workout plan structure: missing required fields');
      }

      // Add metadata for saving in Firebase (optional, but good practice)
      planData['generatedAt'] = Timestamp.now();
      planData['userId'] = _auth.currentUser?.uid;
      planData['fitnessGoals'] = fitnessGoals;
      planData['fitnessLevel'] = fitnessLevel;
      planData['workoutType'] = workoutType;
      planData['planDuration'] = planDuration;


      return planData;
    } catch (e, stackTrace) {
      print('Error generating workout plan: $e');
      print('Stack trace: $stackTrace');
      return _generateFallbackPlan(fitnessGoals, fitnessLevel, workoutType, planDuration);
    }
  }

  static Map<String, dynamic> _generateFallbackPlan(
      String fitnessGoals,
      String fitnessLevel,
      String workoutType,
      String planDuration,
      ) {
    int daysCount = int.tryParse(planDuration.split(' ').first) ?? 7;
    List<Map<String, dynamic>> schedule = [];

    for (int i = 1; i <= daysCount; i++) {
      if (i % 4 == 0 && daysCount >= 7) {
        schedule.add({
          'day': 'Day $i',
          'activity': 'Rest Day',
          'duration': 'N/A',
          'details': [{'name': 'Active Recovery', 'instruction': 'Light walk or stretching.'}],
        });
      } else {
        schedule.add({
          'day': 'Day $i',
          'activity': 'Full Body Workout',
          'duration': '45 minutes',
          'details': [
            {'name': 'Jumping Jacks', 'instruction': '3 sets of 60 seconds'},
            {'name': 'Push-ups', 'instruction': '3 sets of 10-15 reps (modify on knees if needed)'},
            {'name': 'Bodyweight Squats', 'instruction': '3 sets of 12-15 reps'},
            {'name': 'Plank', 'instruction': '3 sets of 30-60 seconds hold'},
            {'name': 'Lunges', 'instruction': '3 sets of 10 reps per leg'},
          ],
        });
      }
    }

    return {
      'planTitle': '$planDuration $workoutType Plan ($fitnessLevel)',
      'introduction': 'This is a foundational workout plan. Remember to always warm-up before and cool-down after each session. Listen to your body and focus on proper form.',
      'weeklySchedule': schedule,
      'generalTips': [
        'Stay hydrated by drinking plenty of water throughout the day.',
        'Focus on proper form to prevent injuries.',
        'Consistency is more important than intensity, especially when starting out.',
      ],
      'isFallback': true,
      // Add metadata to fallback plan as well
      'generatedAt': Timestamp.now(),
      'userId': _auth.currentUser?.uid,
      'fitnessGoals': fitnessGoals,
      'fitnessLevel': fitnessLevel,
      'workoutType': workoutType,
      'planDuration': planDuration,
    };
  }

  // ** ADDED THIS METHOD **
  // Save workout plan to Firebase
  static Future<void> saveWorkoutPlan(Map<String, dynamic> planData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure timestamp is in the correct format for Firebase
      if (planData['generatedAt'] is DateTime) {
        planData['generatedAt'] = Timestamp.fromDate(planData['generatedAt']);
      } else if (planData['generatedAt'] == null) {
        planData['generatedAt'] = Timestamp.now();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gymkitDetails')
          .doc('workoutPlan')
          .set(planData, SetOptions(merge: false)); // Use set without merge to overwrite

      print('Workout plan saved successfully to Firebase');
    } catch (e) {
      print('Error saving workout plan: $e');
      throw Exception('Failed to save workout plan: ${e.toString()}');
    }
  }

  // ** ADDED THIS METHOD **
  // Get saved workout plan from Firebase
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
        // Convert Firestore Timestamp to DateTime for easier use in the app
        if (data['generatedAt'] is Timestamp) {
          data['generatedAt'] = (data['generatedAt'] as Timestamp).toDate();
        }
        print('Successfully retrieved saved workout plan');
        return data;
      }

      print('No saved workout plan found');
      return null;
    } catch (e) {
      print('Error getting saved workout plan: $e');
      return null;
    }
  }

  // ** ADDED THIS METHOD **
  // Generate a shareable text string from the plan data
  static String generateWorkoutPlanText(Map<String, dynamic> planData) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('🏋️ ${planData['planTitle'] ?? 'AI Workout Plan'}');
    buffer.writeln('=' * 40);
    buffer.writeln();

    if (planData['introduction'] != null) {
      buffer.writeln('📖 Introduction:');
      buffer.writeln(planData['introduction']);
      buffer.writeln();
    }

    if (planData['weeklySchedule'] != null && planData['weeklySchedule'] is List) {
      buffer.writeln('📅 Workout Schedule:');
      buffer.writeln();

      for (var dayData in (planData['weeklySchedule'] as List)) {
        buffer.writeln('${dayData['day']}: ${dayData['activity']} (${dayData['duration']})');
        buffer.writeln('-' * 30);

        if (dayData['details'] != null && dayData['details'] is List) {
          for (var exercise in (dayData['details'] as List)) {
            buffer.writeln('  • ${exercise['name']}: ${exercise['instruction']}');
          }
        }
        buffer.writeln();
      }
    }

    if (planData['generalTips'] != null && planData['generalTips'] is List) {
      buffer.writeln('💡 General Tips:');
      for (var tip in (planData['generalTips'] as List)) {
        buffer.writeln('- $tip');
      }
      buffer.writeln();
    }

    buffer.writeln('Generated by TrackAI');
    return buffer.toString();
  }


  static int _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 25;
    DateTime birthDate;
    if (dateOfBirth is Timestamp) {
      birthDate = dateOfBirth.toDate();
    } else if (dateOfBirth is DateTime) {
      birthDate = dateOfBirth;
    } else {
      return 25;
    }
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}