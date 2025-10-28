import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Gemini {
  static const String baseUrl = "https://generativelanguage.googleapis.com/v1/models/";

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

      final prompt = """
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
  "foodName": "name of the food",
  "healthScore": 8,
  "healthDescription": "Brief health assessment explaining the score - mention key nutritional benefits/concerns",
  "description": "Short description of appearance, texture, and flavors. MAX 6-7 lines.",
  "ingredients": ["ingredient1", "ingredient2", "ingredient3", "ingredient4", "ingredient5"],
  "origin": "Brief origin information. MAX 3 lines.",
  "whoShouldEat": "Detailed explanation of who should prefer this food.",
  "whoShouldAvoid": "Detailed explanation of who should avoid this food.",
  "allergenInfo": "List common allergens present or 'No major allergens detected'",
  "quickNote": "Brief interesting fact or health tip."
}

Remember: Respond with ONLY the JSON object, nothing else.
""";

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to describe food: $e');
    }
  }

  Future<String> _callGeminiVision(String prompt, String base64Image) async {
    final url = Uri.parse(baseUrl + "gemini-2.0-flash:generateContent?key=$apiKey");

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
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

          String textResponse = responseData['candidates'][0]['content']['parts'][0]['text'] ??
              'No response generated';

          // Clean up response - remove markdown code blocks if present
          textResponse = textResponse
              .replaceAll('```', '') // Corrected line 165: removed unclosed parenthesis
              .replaceAll('```', '') // Corrected line 167: removed unclosed parenthesis
              .trim();

              return textResponse;
              } else {
              throw Exception('Invalid response format from Gemini API');
              }
          } else if (response.body.isEmpty) {
            throw Exception('Empty response from Gemini API. Check network and endpoint.');
          } else {
          final errorData = response.body.isNotEmpty ? json.decode(response.body) : {};
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
}
