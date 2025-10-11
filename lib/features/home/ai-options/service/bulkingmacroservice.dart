import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BulkingMacrosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseAuth get _auth {
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('User not authenticated');
    }
    return FirebaseAuth.instance;
  }

  static Future<Map<String, dynamic>?> calculateBulkingMacros({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required double targetGain,
    required int timeframe,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      // Calculate basic metrics
      double bmr = _calculateBMR(gender, weight, height, age);
      double tdee = _calculateTDEE(bmr, activityLevel);
      double weeklyGainTarget = targetGain / timeframe;
      double dailyCaloricSurplus = _calculateCaloricSurplus(weeklyGainTarget);
      double totalCalories = tdee + dailyCaloricSurplus;

      Map<String, dynamic> macros = _calculateMacros(
        totalCalories,
        weight,
        gender,
        activityLevel,
      );

      // Get AI-powered recommendations
      List<String> recommendations = await _generateAIRecommendations(
        gender: gender,
        weight: weight,
        height: height,
        age: age,
        targetGain: targetGain,
        timeframe: timeframe,
        weeklyGainTarget: weeklyGainTarget,
        activityLevel: activityLevel,
      );

      List<Map<String, String>> mealTiming = _generateMealTiming();

      final result = {
        'bmr': bmr.round(),
        'tdee': tdee.round(),
        'surplus': dailyCaloricSurplus.round(),
        'calories': totalCalories.round(),
        'protein': macros['protein'].round(),
        'carbs': macros['carbs'].round(),
        'fat': macros['fat'].round(),
        'fiber': _calculateFiber(macros['carbs']).round(),
        'weeklyGainRate': weeklyGainTarget.toStringAsFixed(2),
        'recommendations': recommendations,
        'mealTiming': mealTiming,
        'calculatedAt': DateTime.now(),
        'userInput': {
          'gender': gender,
          'weight': weight,
          'height': height,
          'age': age,
          'activityLevel': activityLevel,
          'targetGain': targetGain,
          'timeframe': timeframe,
        },
      };

      // Save to Firebase
      await saveBulkingPlan(result);

      return result;
    } catch (e) {
      print('Error calculating bulking macros: $e');
      return null;
    }
  }

  static double _calculateBMR(
    String gender,
    double weight,
    double height,
    int age,
  ) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  static double _calculateTDEE(double bmr, String activityLevel) {
    final activityMultipliers = {
      'Sedentary (desk job, no exercise)': 1.2,
      'Lightly Active (light exercise 1-3 days/week)': 1.375,
      'Moderately Active (moderate exercise 3-5 days/week)': 1.55,
      'Very Active (hard exercise 6-7 days/week)': 1.725,
      'Super Active (very hard exercise, physical job)': 1.9,
    };

    double multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  static double _calculateCaloricSurplus(double weeklyGainTarget) {
    return (weeklyGainTarget * 7700) / 7; // Updated to 7700 cal per kg (more accurate)
  }

  static Map<String, double> _calculateMacros(
    double totalCalories,
    double weight,
    String gender,
    String activityLevel,
  ) {
    // Protein: 2.2g per kg for bulking (higher for muscle synthesis)
    double proteinGrams = weight * 2.2;
    double proteinCalories = proteinGrams * 4;

    // Fat: 25-30% of total calories (optimal for hormone production)
    double fatCalories = totalCalories * 0.28;
    double fatGrams = fatCalories / 9;

    // Carbs: Fill remaining calories
    double remainingCalories = totalCalories - proteinCalories - fatCalories;
    double carbGrams = remainingCalories / 4;

    return {
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  static double _calculateFiber(double carbGrams) {
    // Recommend 14g fiber per 1000 calories, roughly 25-35g daily
    return carbGrams * 0.15; // Approximately 15% of carbs should be fiber
  }

  static Future<List<String>> _generateAIRecommendations({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required double targetGain,
    required int timeframe,
    required double weeklyGainTarget,
    required String activityLevel,
  }) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        return _getFallbackRecommendations(
          gender, weight, targetGain, timeframe, weeklyGainTarget,
        );
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      final prompt = '''
As a nutrition AI expert, provide 6-8 personalized bulking recommendations for:
- ${gender}, ${age} years old, ${weight}kg, ${height}cm
- Goal: Gain ${targetGain}kg in ${timeframe} weeks (${weeklyGainTarget.toStringAsFixed(2)}kg/week)
- Activity: $activityLevel

Focus on:
1. Realistic expectations and healthy gain rate
2. Nutrient timing and meal frequency
3. Food quality and sources
4. Hydration and recovery
5. Training synergy
6. Potential challenges and solutions

Keep each recommendation concise (1-2 sentences) and actionable.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        return response.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
            .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
            .where((line) => line.isNotEmpty)
            .take(8)
            .toList();
      }
    } catch (e) {
      print('Error generating AI recommendations: $e');
    }

    return _getFallbackRecommendations(
      gender, weight, targetGain, timeframe, weeklyGainTarget,
    );
  }

  static List<String> _getFallbackRecommendations(
    String gender,
    double weight,
    double targetGain,
    int timeframe,
    double weeklyGainTarget,
  ) {
    List<String> recommendations = [];

    recommendations.add(
      'Aim for 2.2g of protein per kg of body weight to optimize muscle protein synthesis during your bulking phase.',
    );

    if (weeklyGainTarget > 0.7) {
      recommendations.add(
        'Your target of ${weeklyGainTarget.toStringAsFixed(2)}kg/week is aggressive. Consider 0.25-0.5kg/week for leaner gains with less fat accumulation.',
      );
    } else if (weeklyGainTarget < 0.2) {
      recommendations.add(
        'Your conservative target allows for high-quality muscle gains while minimizing fat storage.',
      );
    } else {
      recommendations.add(
        'Your weekly gain target of ${weeklyGainTarget.toStringAsFixed(2)}kg is in the optimal range for lean muscle growth.',
      );
    }

    recommendations.add(
      'Distribute protein across 4-6 meals with 25-40g per meal to maximize muscle protein synthesis throughout the day.',
    );

    recommendations.add(
      'Time 40-60g of carbohydrates around your workouts to fuel performance and support recovery.',
    );

    recommendations.add(
      'Maintain 3.5-4L of water daily as increased food intake and training demand higher hydration.',
    );

    recommendations.add(
      'Prioritize 7-9 hours of quality sleep nightly for optimal growth hormone release and muscle recovery.',
    );

    recommendations.add(
      'Focus on compound movements with progressive overload to maximize the muscle-building stimulus from your increased calories.',
    );

    recommendations.add(
      'Monitor body composition weekly rather than just weight to ensure muscle-to-fat gain ratio stays optimal.',
    );

    return recommendations;
  }

  static List<Map<String, String>> _generateMealTiming() {
    return [
      {
        'time': '7:00 AM',
        'description': 'Breakfast: High-protein meal with oats/whole grains',
        'macroFocus': 'Protein + Complex Carbs',
      },
      {
        'time': '10:00 AM',
        'description': 'Mid-morning: Protein shake with banana',
        'macroFocus': 'Protein + Simple Carbs',
      },
      {
        'time': '1:00 PM',
        'description': 'Lunch: Lean protein, rice/quinoa, vegetables',
        'macroFocus': 'Balanced Macros',
      },
      {
        'time': '4:00 PM',
        'description': 'Pre-workout: Light carbs + caffeine',
        'macroFocus': 'Fast Carbs',
      },
      {
        'time': '6:30 PM',
        'description': 'Post-workout: Protein shake + simple carbs',
        'macroFocus': 'Protein + Simple Carbs',
      },
      {
        'time': '8:30 PM',
        'description': 'Dinner: Protein, healthy fats, vegetables',
        'macroFocus': 'Protein + Fats',
      },
    ];
  }

  static String generateBulkingPlanText(Map<String, dynamic> results) {
    final buffer = StringBuffer();

    buffer.writeln('=== AI BULKING MACRO PLAN ===');
    buffer.writeln('Generated: ${results['calculatedAt']}');
    buffer.writeln();

    buffer.writeln('🎯 DAILY MACRO TARGETS:');
    buffer.writeln('Calories: ${results['calories']} kcal');
    buffer.writeln('Protein: ${results['protein']}g');
    buffer.writeln('Carbohydrates: ${results['carbs']}g');
    buffer.writeln('Fat: ${results['fat']}g');
    buffer.writeln('Fiber: ${results['fiber']}g (minimum)');
    buffer.writeln();

    buffer.writeln('📊 METABOLIC BREAKDOWN:');
    buffer.writeln('Basal Metabolic Rate: ${results['bmr']} kcal/day');
    buffer.writeln('Total Daily Energy Expenditure: ${results['tdee']} kcal/day');
    buffer.writeln('Caloric Surplus: ${results['surplus']} kcal/day');
    buffer.writeln('Expected Weekly Gain: ${results['weeklyGainRate']} kg/week');
    buffer.writeln();

    buffer.writeln('📝 YOUR PROFILE:');
    final userInput = results['userInput'] as Map<String, dynamic>;
    buffer.writeln('Gender: ${userInput['gender']}');
    buffer.writeln('Current Weight: ${userInput['weight']}kg');
    buffer.writeln('Height: ${userInput['height']}cm');
    buffer.writeln('Age: ${userInput['age']} years');
    buffer.writeln('Activity Level: ${userInput['activityLevel']}');
    buffer.writeln('Goal: Gain ${userInput['targetGain']}kg in ${userInput['timeframe']} weeks');
    buffer.writeln();

    buffer.writeln('🤖 AI RECOMMENDATIONS:');
    final recommendations = results['recommendations'] as List<String>;
    for (int i = 0; i < recommendations.length; i++) {
      buffer.writeln('${i + 1}. ${recommendations[i]}');
    }
    buffer.writeln();

    buffer.writeln('⏰ OPTIMAL MEAL TIMING:');
    final mealTiming = results['mealTiming'] as List<Map<String, String>>;
    for (final meal in mealTiming) {
      buffer.writeln('${meal['time']} | ${meal['description']}');
      if (meal['macroFocus'] != null) {
        buffer.writeln('   Focus: ${meal['macroFocus']}');
      }
    }
    buffer.writeln();

    buffer.writeln('⚠️  IMPORTANT GUIDELINES:');
    buffer.writeln('• Weigh yourself weekly at the same time (morning, after bathroom)');
    buffer.writeln('• Adjust calories by ±200 if weight gain is off target');
    buffer.writeln('• Prioritize whole foods over processed options');
    buffer.writeln('• Stay consistent with training for optimal results');
    buffer.writeln('• Take progress photos and body measurements monthly');
    buffer.writeln('• Consult healthcare providers for personalized advice');

    return buffer.toString();
  }

  static Future<void> saveBulkingPlan(Map<String, dynamic> plan) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Save under gymkitdetails collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gymkitdetails')
          .doc('bulking_macros')
          .set({
        'plan': plan,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Bulking plan saved to Firebase successfully');
    } catch (e) {
      print('Error saving bulking plan to Firebase: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getSavedBulkingPlan() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('User not authenticated');
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gymkitdetails')
          .doc('bulking_macros')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['plan'] != null) {
          // Convert Timestamp back to DateTime if needed
          final plan = Map<String, dynamic>.from(data['plan']);
          if (plan['calculatedAt'] is Timestamp) {
            plan['calculatedAt'] = (plan['calculatedAt'] as Timestamp).toDate();
          }
          return plan;
        }
      }

      return null;
    } catch (e) {
      print('Error loading saved bulking plan from Firebase: $e');
      return null;
    }
  }

  static Future<void> deleteSavedBulkingPlan() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gymkitdetails')
          .doc('bulking_macros')
          .delete();

      print('Bulking plan deleted from Firebase successfully');
    } catch (e) {
      print('Error deleting bulking plan from Firebase: $e');
      rethrow;
    }
  }

  // Helper method to check if current plan needs updating
  static bool shouldUpdatePlan(Map<String, dynamic>? savedPlan, Map<String, dynamic> newUserInput) {
    if (savedPlan == null) return true;

    final savedInput = savedPlan['userInput'] as Map<String, dynamic>?;
    if (savedInput == null) return true;

    // Check if any key parameters have changed
    return savedInput['gender'] != newUserInput['gender'] ||
           savedInput['weight'] != newUserInput['weight'] ||
           savedInput['height'] != newUserInput['height'] ||
           savedInput['age'] != newUserInput['age'] ||
           savedInput['activityLevel'] != newUserInput['activityLevel'] ||
           savedInput['targetGain'] != newUserInput['targetGain'] ||
           savedInput['timeframe'] != newUserInput['timeframe'];
  }

  // Get plan age in days
  static int getPlanAgeDays(Map<String, dynamic> plan) {
    final calculatedAt = plan['calculatedAt'];
    if (calculatedAt == null) return 0;

    DateTime date;
    if (calculatedAt is Timestamp) {
      date = calculatedAt.toDate();
    } else if (calculatedAt is DateTime) {
      date = calculatedAt;
    } else {
      return 0;
    }

    return DateTime.now().difference(date).inDays;
  }
}