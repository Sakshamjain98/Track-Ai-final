import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Gemini {
  // 1. UPDATED: Use the v1beta endpoint to access JSON mode
  static const String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/";

  final apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<String> analyzeNutritionFromImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = """
Analyze this food image and provide detailed nutrition information.
IMPORTANT: You MUST respond with ONLY a valid JSON object, no additional text or markdown formatting.
Return the information in this EXACT JSON format:
{
  "foodName": "name of the food",
  "healthScore": 8,
  "healthDescription": "detailed health assessment",
  "description": "comprehensive description",
  "nutritionalBreakdown": {
    "calories": 500,
    "protein": 25,
    "carbohydrates": 60,
    "fat": 15,
    "fiber": 8,
    "sugar": 10,
    "sodium": 500
  },
  "ingredients": ["ingredient1", "ingredient2", "ingredient3", "ingredient4", "ingredient5"],
  "origin": "country/region",
  "whoShouldPrefer": [
    {"group": "Athletes", "reason": "provides quick energy"},
    {"group": "Growing children", "reason": "nutrients for development"},
    {"group": "Active individuals", "reason": "sustained energy"},
    {"group": "Health enthusiasts", "reason": "balanced nutrition"}
  ],
  "whoShouldAvoid": [
    {"group": "Diabetics", "reason": "high carbohydrate content"},
    {"group": "Low-sodium diets", "reason": "high sodium levels"},
    {"group": "Weight loss", "reason": "high calorie density"},
    {"group": "Specific allergies", "reason": "contains allergens"}
  ],
  "allergenInfo": "list of allergens or 'No major allergens detected'",
  "quickNote": "interesting fact or health tip"
}
      """;

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to analyze nutrition: $e');
    }
  }

  Future<String> describeFoodFromImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = '''
First, carefully examine this image to determine if it contains food items.

IMPORTANT: You MUST respond with ONLY a valid JSON object, no additional text, markdown, or code blocks.

If the image does NOT contain food (like objects, people, scenery, etc.), respond with:
{
  "isFood": false,
  "errorMessage": "I can only analyze food items. The image you provided appears to contain [describe what you see]. Please upload an image of food for analysis."
}

If the image DOES contain food, respond with this EXACT JSON structure:
{
  "isFood": true,
  "foodName": "e.g., Avocado Toast with Egg",
  "totalEstimatedWeight_g": 350,
  "healthScore": 7,
  "healthDescription": "This avocado toast with egg is a relatively healthy meal. It provides healthy fats from avocado, protein from the egg, and fiber from the whole-wheat toast. However, the overall health score could be improved by adding more vegetables and reducing the amount of salt and oil.",
  "description": "This avocado toast with egg consists of whole-wheat toast topped with mashed avocado and sliced hard-boiled egg. The avocado provides healthy monounsaturated fats, fiber, and several vitamins and minerals. The egg is a good source of protein and essential nutrients. The whole-wheat toast provides complex carbohydrates and fiber. The meal is seasoned with salt, pepper, and possibly red pepper flakes.",
  "nutritionalBreakdown": {
    "calories": 350,
    "protein_g": 15,
    "carbohydrates_g": 30,
    "fat_g": 20,
    "fiber_g": 7
  },
  "ingredients": [
    {"name": "Whole-Wheat Toast", "weight_g": 60},
    {"name": "Avocado", "weight_g": 120},
    {"name": "Egg", "weight_g": 60},
    {"name": "Salt", "weight_g": 1},
    {"name": "Pepper", "weight_g": 0.5},
    {"name": "Red Pepper Flakes", "weight_g": 0.5}
  ],
  "healthBenefits": [
    {
      "ingredient": "Avocado",
      "benefit": "Avocados are rich in healthy monounsaturated fats, fiber, and various vitamins and minerals. They support heart health, improve digestion, and may help with weight management."
    },
    {
      "ingredient": "Egg",
      "benefit": "Eggs are an excellent source of high-quality protein and contain essential nutrients like choline, vitamin B12, and selenium. They support muscle health, brain function, and overall nutrition."
    },
    {
      "ingredient": "Whole-Wheat Toast",
      "benefit": "Whole-wheat toast provides complex carbohydrates and fiber, which can help regulate blood sugar levels and promote digestive health."
    }
  ],
  "origin": "International - Popular breakfast/brunch item",
  "whoShouldEat": "Suitable for most individuals seeking a balanced meal with healthy fats, protein, and fiber. Good for active individuals, health-conscious people, and those looking for sustained energy.",
  "whoShouldAvoid": "Consult with healthcare provider if you have specific dietary restrictions. People with egg allergies should avoid. Those on low-sodium diets should reduce salt.",
  "allergenInfo": "Contains: Eggs, Gluten (from wheat). May contain traces of other allergens depending on preparation.",
  "quickNote": "This meal provides a good balance of macronutrients. The healthy fats from avocado can help with nutrient absorption. Consider adding more vegetables for additional vitamins and minerals."
}

Remember: Respond with ONLY the JSON object, nothing else.
''';

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to describe food: $e');
    }
  }

  Future<String> _callGeminiVision(String prompt, String base64Image) async {
    // 2. UPDATED: Use a newer, more reliable model for JSON output
    final url = Uri.parse(
        baseUrl + "gemini-2.0-flash:generateContent?key=$apiKey");

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
        // 3. THE KEY FIX: Force the API to output only JSON
        'responseMimeType': "application/json",
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {

          String textResponse =
              responseData['candidates'][0]['content']['parts'][0]['text'] ??
                  '{}'; // Default to empty JSON

          // 4. REMOVED: The .replaceAll('```', '') is no longer needed
          // because 'responseMimeType' guarantees clean JSON output.

          return textResponse.trim(); // Just trim whitespace
        } else {
          // Handle cases where the API blocked the request
          if (responseData['promptFeedback'] != null) {
            final feedback = responseData['promptFeedback'];
            if (feedback['blockReason'] != null) {
              // Return a valid JSON error message
              return '{"isFood": false, "errorMessage": "Analysis blocked: ${feedback['blockReason']}. This may be due to a safety setting."}';
            }
          }
          throw Exception('Invalid response format from Gemini API');
        }
      } else if (response.body.isEmpty) {
        throw Exception(
            'Empty response from Gemini API. Check network and endpoint.');
      } else {
        final errorData =
        response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet connection');
      }
      rethrow;
    }
  }

  Future<String> analyzeNutritionLabel(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = """
Analyze this nutrition facts label and provide detailed information.
IMPORTANT: You MUST respond with ONLY a valid JSON object, no additional text or markdown formatting.
First, determine if this is a valid nutrition facts label. If not, respond with:
{
  "isValidLabel": false,
  "errorMessage": "No valid nutrition label detected. Please take a clear photo of a nutrition facts label."
}
If it is a valid nutrition label, respond with this EXACT JSON structure:
{
  "isValidLabel": true,
  "productName": "name of the product",
  "servingSize": "serving size information",
  "servingsPerContainer": "number of servings",
  "calories": 0,
  "quickSummary": "brief nutritional assessment",
  "nutrientBreakdown": {
    "protein": 0,
    "carbohydrates": 0,
    "fat": 0,
    "fiber": 0,
    "sugar": 0,
    "sodium": 0
  },
  "otherNutrients": ["nutrient1", "nutrient2"],
 "vitamins": ["e.g., Vitamin D (10% DV)", "e.g., Calcium (20% DV)"],
  "minerals": ["e.g., Iron (8% DV)", "e.g., Potassium (5% DV)"],
  "ingredientInsights": "analysis of key ingredients and their health implications"
}
""";

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to analyze nutrition label: $e');
    }
  }
}