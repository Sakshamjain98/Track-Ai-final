import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static Future<Map<String, dynamic>?> calculateNutritionGoals({
    required Map<String, dynamic> onboardingData,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('Gemini API key not found in .env file');
      }

      // Calculate basic metrics
      final age = _calculateAge(onboardingData['dateOfBirth']);
      final bmi = _calculateBMI(onboardingData);
      
      // Create prompt for Gemini
      final prompt = _createNutritionPrompt(onboardingData, age, bmi);
      
      // Make API call with correct model name
      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topP': 0.8,
            'topK': 40,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          return _parseGeminiResponse(content);
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        // Fallback to manual calculation if API fails
        return _calculateFallbackGoals(onboardingData, age, bmi);
      }
      
      // If parsing fails, use fallback
      return _calculateFallbackGoals(onboardingData, age, bmi);
    } catch (e) {
      print('GeminiService Error: $e');
      // Fallback to manual calculation on any error
      final age = _calculateAge(onboardingData['dateOfBirth']);
      final bmi = _calculateBMI(onboardingData);
      return _calculateFallbackGoals(onboardingData, age, bmi);
    }
  }

  static String _createNutritionPrompt(Map<String, dynamic> data, int? age, double? bmi) {
    final isMetric = data['isMetric'] ?? false;
    final weight = isMetric ? data['weightKg'] : data['weightLbs'];
    final height = isMetric 
        ? '${data['heightCm']} cm'
        : '${data['heightFeet']}\'${data['heightInches']}"';
    
    return '''
Calculate daily nutrition goals for a person with these details:

Personal Information:
- Age: ${age ?? 'Unknown'} years
- Gender: ${data['gender'] ?? 'Unknown'}
- Height: $height
- Weight: $weight ${isMetric ? 'kg' : 'lbs'}
- BMI: ${bmi?.toStringAsFixed(1) ?? 'Unknown'}

Fitness Information:
- Workout Frequency: ${data['workoutFrequency'] ?? 'Unknown'}
- Primary Goal: ${data['goal'] ?? 'Unknown'}
- Goal Pace: ${data['goalPace'] ?? 'Unknown'}
- Diet Preference: ${data['dietPreference'] ?? 'Unknown'}
${data['desiredWeight'] != null ? '- Target Weight: ${data['desiredWeight']} ${isMetric ? 'kg' : 'lbs'}' : ''}

IMPORTANT GUIDELINES:
- For WEIGHT LOSS: Use 20% calorie deficit from TDEE, prioritize protein (2.2g/kg bodyweight)
- For WEIGHT GAIN: Use 10% calorie surplus from TDEE, moderate protein (2.0g/kg bodyweight)  
- For MAINTENANCE: Use TDEE calories, balanced protein (1.8g/kg bodyweight)

Please calculate and return ONLY a JSON response with these exact fields:
{
  "calories": [daily calorie target as integer - ensure appropriate deficit/surplus],
  "protein": [daily protein in grams as integer - based on bodyweight],
  "carbs": [daily carbs in grams as integer - fill remaining calories after protein/fat],
  "fat": [daily fat in grams as integer - around 25% of calories],
  "fiber": [daily fiber in grams as integer - 14g per 1000 calories],
  "bmr": [basal metabolic rate as integer - Harris Benedict],
  "tdee": [total daily energy expenditure as integer - BMR × activity factor],
  "explanation": "[brief explanation of how these macros support their specific goal]"
}

Base calculations on:
- Harris-Benedict equation for BMR
- Activity level from workout frequency  
- Appropriate calorie deficit/surplus for goal
- Protein based on bodyweight and goal
- Fat around 25% of calories
- Carbs fill remaining calories

Return ONLY the JSON, no other text.
''';
  }

  static Map<String, dynamic>? _parseGeminiResponse(String content) {
    try {
      // Clean the response to extract JSON
      String cleanContent = content.trim();
      
      // Find JSON block
      int startIndex = cleanContent.indexOf('{');
      int endIndex = cleanContent.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
        String jsonString = cleanContent.substring(startIndex, endIndex + 1);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error parsing Gemini response: $e');
      return null;
    }
  }

  static int? _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return null;
    
    DateTime birthDate;
    if (dateOfBirth is DateTime) {
      birthDate = dateOfBirth;
    } else if (dateOfBirth is String) {
      birthDate = DateTime.tryParse(dateOfBirth) ?? DateTime.now();
    } else {
      return null;
    }

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  static double? _calculateBMI(Map<String, dynamic> data) {
    try {
      final bool isMetric = data['isMetric'] ?? false;

      if (isMetric) {
        final double? weightKg = data['weightKg']?.toDouble();
        final int? heightCm = data['heightCm'];

        if (weightKg != null && heightCm != null && heightCm > 0) {
          final heightM = heightCm / 100;
          return weightKg / (heightM * heightM);
        }
      } else {
        final double? weightLbs = data['weightLbs']?.toDouble();
        final int? heightFeet = data['heightFeet'];
        final int? heightInches = data['heightInches'];

        if (weightLbs != null && heightFeet != null && heightInches != null) {
          final totalInches = (heightFeet * 12) + heightInches;
          if (totalInches > 0) {
            return (weightLbs / (totalInches * totalInches)) * 703;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error calculating BMI: $e');
      return null;
    }
  }

  /// Fallback calculation method when Gemini API is unavailable
  static Map<String, dynamic> _calculateFallbackGoals(
    Map<String, dynamic> data,
    int? age,
    double? bmi,
  ) {
    try {
      print('Using fallback nutrition calculation...');
      
      // Calculate BMR using Harris-Benedict equation
      final bmr = _calculateBMR(data, age);
      
      // Calculate TDEE based on activity level
      final activityMultiplier = _getActivityMultiplier(data['workoutFrequency']);
      final tdee = (bmr * activityMultiplier).round();
      
      // Adjust calories based on goal
      final calories = _adjustCaloriesForGoal(tdee, data['goal']);
      
      // Calculate macros based on goal-specific ratios
      final macros = _calculateMacrosForGoal(calories, data['goal'], data);
      
      return {
        'calories': calories,
        'protein': macros['protein'],
        'carbs': macros['carbs'],
        'fat': macros['fat'],
        'fiber': macros['fiber'],
        'bmr': bmr.round(),
        'tdee': tdee,
        'explanation': _getFallbackExplanation(data, calories, bmr.round(), tdee),
      };
    } catch (e) {
      print('Error in fallback calculation: $e');
      // Return basic default values if even fallback fails
      return {
        'calories': 2000,
        'protein': 125,
        'carbs': 250,
        'fat': 67,
        'fiber': 28,
        'bmr': 1600,
        'tdee': 2000,
        'explanation': 'Basic nutrition goals based on standard recommendations. For personalized goals, please ensure your profile information is complete and try recalculating.',
      };
    }
  }

  static double _calculateBMR(Map<String, dynamic> data, int? age) {
    final isMetric = data['isMetric'] ?? false;
    final gender = data['gender']?.toLowerCase() ?? 'male';
    
    double weight, height;
    
    if (isMetric) {
      weight = (data['weightKg'] ?? 70).toDouble();
      height = (data['heightCm'] ?? 170).toDouble();
    } else {
      weight = ((data['weightLbs'] ?? 154) * 0.453592).toDouble(); // Convert to kg
      final heightFeet = data['heightFeet'] ?? 5;
      final heightInches = data['heightInches'] ?? 7;
      height = ((heightFeet * 12 + heightInches) * 2.54).toDouble(); // Convert to cm
    }
    
    final ageValue = age ?? 25;
    
    // Harris-Benedict equation
    if (gender == 'female') {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * ageValue);
    } else {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * ageValue);
    }
  }

  static double _getActivityMultiplier(String? workoutFrequency) {
    switch (workoutFrequency?.toLowerCase()) {
      case 'never':
      case 'sedentary':
        return 1.2;
      case '1-2 times per week':
      case 'lightly active':
        return 1.375;
      case '3-4 times per week':
      case 'moderately active':
        return 1.55;
      case '5-6 times per week':
      case 'very active':
        return 1.725;
      case 'daily':
      case 'extremely active':
        return 1.9;
      default:
        return 1.375; // Default to lightly active
    }
  }

  static int _adjustCaloriesForGoal(int tdee, String? goal) {
    switch (goal?.toLowerCase()) {
      case 'lose weight':
      case 'weight loss':
      case 'cut':
        return (tdee * 0.80).round(); // 20% deficit for effective weight loss
      case 'gain weight':
      case 'weight gain':
      case 'bulk':
      case 'muscle gain':
        return (tdee * 1.10).round(); // 10% surplus for lean gains
      case 'maintain weight':
      case 'maintenance':
      case 'maintain':
      default:
        return tdee;
    }
  }

  static Map<String, int> _calculateMacrosForGoal(
    int calories,
    String? goal,
    Map<String, dynamic> data,
  ) {
    // Get body weight in kg for protein calculation
    final isMetric = data['isMetric'] ?? false;
    double weightKg;
    
    if (isMetric) {
      weightKg = (data['weightKg'] ?? 70).toDouble();
    } else {
      weightKg = ((data['weightLbs'] ?? 154) * 0.453592).toDouble();
    }
    
    int protein, fat, carbs, fiber;
    
    switch (goal?.toLowerCase()) {
      case 'lose weight':
      case 'weight loss':
      case 'cut':
        // Higher protein for muscle preservation during cut
        protein = (weightKg * 2.2).round(); // 2.2g per kg bodyweight
        fat = (calories * 0.25 / 9).round(); // 25% of calories from fat
        break;
        
      case 'gain weight':
      case 'weight gain':
      case 'bulk':
      case 'muscle gain':
        // Moderate protein for muscle building
        protein = (weightKg * 2.0).round(); // 2.0g per kg bodyweight
        fat = (calories * 0.25 / 9).round(); // 25% of calories from fat
        break;
        
      case 'maintain weight':
      case 'maintenance':
      case 'maintain':
      default:
        // Balanced approach for maintenance
        protein = (weightKg * 1.8).round(); // 1.8g per kg bodyweight
        fat = (calories * 0.25 / 9).round(); // 25% of calories from fat
        break;
    }
    
    // Calculate remaining carbs from leftover calories
    final proteinCalories = protein * 4;
    final fatCalories = fat * 9;
    final remainingCalories = calories - proteinCalories - fatCalories;
    carbs = (remainingCalories / 4).round().clamp(0, 1000); // Ensure positive
    
    // Fiber based on total calories (14g per 1000 calories)
    fiber = (calories / 1000 * 14).round();
    
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  static String _getFallbackExplanation(
    Map<String, dynamic> data,
    int calories,
    int bmr,
    int tdee,
  ) {
    final goal = data['goal'] ?? 'maintain weight';
    final workoutFrequency = data['workoutFrequency'] ?? 'moderate';
    
    return 'Based on your profile, your BMR is $bmr kcal and your TDEE is $tdee kcal. '
        'For your goal of ${goal.toLowerCase()}, we recommend $calories calories daily. '
        'Your macros are balanced with 25% protein, 25% fat, and 50% carbs to support your '
        '${workoutFrequency.toLowerCase()} activity level and ${goal.toLowerCase()} objective.';
  }
}