import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Gemini {
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }
    return key;
  }

  Future<String> analyzeNutritionFromImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = """
      Analyze this food image and provide detailed nutrition information in the following EXACT format:

      **[Food Name]**

      **Health Score**
      **[X/10]**
      [Brief health assessment explaining the score, mentioning key nutritional aspects and why this score was given]

      **Description**
      [Detailed description of the food, its preparation method, visual characteristics, and typical serving context]

      **Nutritional Breakdown (per serving)**
      • Calories: [X] kcal
      • Protein: [X]g
      • Carbohydrates: [X]g
      • Fat: [X]g
      • Fiber: [X]g
      • Sugar: [X]g
      • Sodium: [X]mg

      **Primary Ingredients**
      * [ingredient 1]
      * [ingredient 2]
      * [ingredient 3]
      * [ingredient 4]
      * [ingredient 5]

      **Origin**
      [Country/Region of origin]

      **Who Should Prefer This**
      • [Specific group 1] - [detailed reason why this group benefits]
      • [Specific group 2] - [detailed reason why this group benefits]
      • [Specific group 3] - [detailed reason why this group benefits]
      • [Specific group 4] - [detailed reason why this group benefits]

      **Who Should Avoid This**
      • [Specific group 1] - [detailed reason why this group should avoid]
      • [Specific group 2] - [detailed reason why this group should avoid]
      • [Specific group 3] - [detailed reason why this group should avoid]
      • [Specific group 4] - [detailed reason why this group should avoid]

      **Allergen Information**
      [List common allergens present: gluten, dairy, nuts, shellfish, soy, etc. If none, state "No major allergens detected"]

      **Quick Note**
      [Interesting nutritional fact or health tip related to this food, preferably with a scientific reference]

      Please provide accurate estimates based on standard nutritional data and maintain the exact formatting shown above.
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

      If the image does NOT contain food (like objects, people, scenery, etc.), respond with:
      **NOT FOOD DETECTED**

      **Error Message**
      I can only analyze food items. The image you provided appears to contain [describe what you see instead]. Please upload an image of food for analysis.

      If the image DOES contain food, analyze it and provide a detailed description in the following EXACT format:

      **[Food Name]**

      **Health Score**
      **[X/10]**
      [Brief health assessment explaining the score - mention key nutritional benefits/concerns, cooking method impact, and overall healthiness. Keep this concise but informative.]

      **Description**
      [Provide a comprehensive description covering: visual appearance, cooking method, texture, likely flavors, cultural context, and typical serving occasions. Make this engaging and informative, as if you're a food enthusiast.]

      **Primary Ingredients**
      * [ingredient 1]
      * [ingredient 2]
      * [ingredient 3]
      * [ingredient 4]
      * [ingredient 5]

      **Origin**
      [Country/Region of origin]

      **Who Should Prefer This**
      • Athletes and active individuals - provides quick energy from carbohydrates and essential nutrients
      • Growing children - offers nutrients important for development and growth
      • People seeking comfort food - satisfying and filling meal option
      • [Specific group based on the food] - [specific reason for this particular food]

      **Who Should Avoid This**
      • People with diabetes - high carbohydrate content may spike blood sugar levels
      • Those on low-sodium diets - often contains high sodium from seasonings or sauces
      • Individuals trying to lose weight - high calorie density may hinder weight loss goals
      • People with [specific condition based on food] - [specific reason for this particular food]

      **Allergen Information**
      [List common allergens present: gluten, dairy, nuts, shellfish, soy, etc. If none, state "No major allergens detected"]

      **Quick Note**
      [Share an interesting nutritional fact, cultural insight, or health tip related to this food. If possible, reference scientific studies or nutritional research.]

      CRITICAL INSTRUCTIONS:
      1. NEVER leave any section empty - always provide content for each section
      2. Use the EXACT format above with ** for bold headings
      3. Always provide at least 3-4 bullet points for each recommendation section
      4. Be specific and detailed - give real reasons why each group should or shouldn't eat this
      5. Make sure every section has meaningful content
      6. The food name should be on its own line after the ** markers
      7. Each section should be clearly separated with the ** format
      8. Use • (bullet point) for "Who Should Prefer This" and "Who Should Avoid This" sections
      9. Use * (asterisk) for "Primary Ingredients" section
      """;

      return await _callGeminiVision(prompt, base64Image);
    } catch (e) {
      throw Exception('Failed to describe food: $e');
    }
  }

  Future<String> _callGeminiVision(String prompt, String base64Image) async {
    final url = Uri.parse(
      '$baseUrl/gemini-1.5-flash:generateContent?key=$apiKey',
    );

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
        'temperature':
            0.2, // Even lower temperature for more consistent formatting
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 4096, // Increased for detailed recommendations
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

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          return responseData['candidates'][0]['content']['parts'][0]['text'] ??
              'No response generated';
        } else {
          throw Exception('Invalid response format from Gemini API');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'API Error (${response.statusCode}): ${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet connection');
      }
      rethrow;
    }
  }

  // Alternative method for text-only requests (if needed)
  Future<String> generateTextResponse(String prompt) async {
    final url = Uri.parse(
      '$baseUrl/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['candidates'][0]['content']['parts'][0]['text'] ??
            'No response generated';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'API Error: ${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }
}