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

      // This is the prompt from your *previous* message,
      // which is required by your NutritionScannerScreen.dart
      final prompt = """
First, carefully examine this image to determine if it contains food items.
IMPORTANT: You MUST respond with ONLY a valid JSON object, no additional text, markdown, or code blocks.
If the image does NOT contain food (like objects, people, scenery, etc.), respond with:
{
  "isFood": false,
  "errorMessage": "I can only analyze food items. The image you provided appears to contain [describe what you see]. Please upload an image of food for analysis."
}
If the image DOES contain food, respond with this EXACT JSON structure, estimating values from the image:
{
  "isFood": true,
  "foodName": "e.g., 'Large Vegetable Salad'",
  "totalEstimatedWeight_g": 2730,
  "healthScore": 8,
  "healthDescription": "Brief health assessment explaining the score. e.g., 'This meal is very healthy due to its high volume of diverse vegetables and fruits, providing a wide range of vitamins, minerals, and fiber. It is low in processed ingredients and saturated fat...'",
  "descriptionAnalysis": "Detailed analysis of the meal. e.g., 'This meal is very healthy due to its high volume of diverse vegetables and fruits... The sugar content is moderate, primarily from natural sources.'",
  
  "nutritionalBreakdown": {
    "calories": 879,
    "protein_g": 30,
    "carbohydrates_g": 210,
    "fat_g": 8,
    "fiber_g": 65
  },
  
  "ingredients": [
    {"name": "Red Bell Pepper", "weight_g": 300},
    {"name": "Red Grapes", "weight_g": 250},
    {"name": "Cucumber", "weight_g": 400},
    {"name": "Tomato", "weight_g": 300},
    {"name": "Pumpkin", "weight_g": 500},
    {"name": "Broccoli", "weight_g": 300}
  ],
  
  "healthBenefits": [
    {"ingredient": "Broccoli", "benefit": "Broccoli is a cruciferous vegetable rich in vitamins C and K, fiber, and antioxidants. It supports immune function, bone health, and may have cancer-preventive properties."},
    {"ingredient": "Pumpkin", "benefit": "Pumpkin is an excellent source of vitamin A, fiber, and antioxidants. It supports eye health, digestive health, and may help boost immunity."},
    {"ingredient": "Red Bell Pepper", "benefit": "Red bell peppers are high in vitamin C and antioxidants, supporting immune function and skin health."}
  ]
}
Remember: Respond with ONLY the JSON object, nothing else.
""";

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
  "vitamins": ["vitamin1", "vitamin2"],
  "minerals": ["mineral1", "mineral2"],
  "ingredientInsights": "analysis of key ingredients and their health implications"
}
""";

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to analyze nutrition label: $e');
    }
  }
}