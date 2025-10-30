import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Note: Assuming 'gemini.dart' and 'appcolors.dart' paths are correct in your project
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/home/homepage/desc%20and%20scan/gemini.dart';

import '../../../../core/routes/routes.dart';
import 'LabelAnalysisScreen.dart';


class FoodDescriptionScreen extends StatefulWidget {
  final File? imageFile;
  const FoodDescriptionScreen({Key? key, this.imageFile, }) : super(key: key);
  @override
  State<FoodDescriptionScreen> createState() => _FoodDescriptionScreenState();
}

class _FoodDescriptionScreenState extends State<FoodDescriptionScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  bool _isNotFood = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();
  final Gemini _gemini = Gemini();

  // AI Data Structure
  Map<String, dynamic>? _aiData;
  // State variable to control the display of the initial camera interface
  bool _showCameraInterface = true;

  @override
  @override
  void initState() {
    super.initState();

    // --- FIX 1: Initialize controllers FIRST and ALWAYS ---
    // These must be initialized outside the 'if' block.
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // Now, check if an image was passed in.
    if (widget.imageFile != null) {

      // Correctly call setState
      setState(() {
        _selectedImage = widget.imageFile;
        _showCameraInterface = false; // Bypass the selector
      });

      // Call analysis *after* the state is set and the frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeFood();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Simplified: Removed analysisType
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _isNotFood = false;
          _aiData = null;
          // Hide the camera interface once an image is picked
          _showCameraInterface = false;
        });

        HapticFeedback.lightImpact();
        await _analyzeFood(); // Simplified call
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  // Simplified: Removed analysisType and navigation logic
  Future<void> _analyzeFood() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Always call the food description method
      final result = await _gemini.describeFoodFromImage(_selectedImage!);

      try {
        final jsonData = json.decode(result);
        final isNotFood = jsonData['isFood'] == false;

        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
          _isNotFood = isNotFood;
        });

        if (!isNotFood) {
          // Always parse as a general food description
          _parseAIResponse(result);
        } else {
          // Handle Not Food
          setState(() {
            _aiData = null;
            _analysisResult = 'NOT FOOD DETECTED\n\nError Message:\n${jsonData['errorMessage']}';
          });
        }

        // Always show animations on this screen
        _fadeController.forward();
        _slideController.forward();
        HapticFeedback.mediumImpact();

      } catch (parseError) {
        // Fallback for unexpected format
        _parseTextResponse(result);
        _fadeController.forward();
        _slideController.forward();
      }

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorSnackBar('Analysis failed: $e');
    }
  }

  // Helper to remove prefixes the AI sometimes includes in the value string
  String _cleanInternalPrefixes(String text) {
    // Targets known problematic prefixes from the AI's response values.
    text = text.replaceAll(
        RegExp(r'^\s*(description|healthDescription|origin|whoShouldEat|whoShouldAvoid|quickNote|allergenInfo)[:\s]*',
            caseSensitive: false),
        '');
    return text.trim();
  }

  void _parseAIResponse(String response) {
    try {
      final jsonData = json.decode(response);

      if (jsonData['isFood'] == false) {
        setState(() {
          _isNotFood = true;
          _analysisResult = "NOT FOOD DETECTED\n\nMessage: ${jsonData['errorMessage']}";
          _aiData = null;
        });
        return;
      }

      setState(() {
        _aiData = {
          'foodName': jsonData['foodName'] ?? 'Food Item',

          // ✅ FIX 1: Properly parse healthScore as int
          'healthScore': (jsonData['healthScore'] is int)
              ? jsonData['healthScore']
              : int.tryParse(jsonData['healthScore'].toString()) ?? 5,

          'healthDescription': _cleanText(
            _cleanInternalPrefixes(jsonData['healthDescription'] ?? 'No health description available.'),
            limitLength: false,
          ),

          // ✅ FIX 2: Use correct field name 'description'
          'description': _cleanText(
            _cleanInternalPrefixes(jsonData['description'] ?? 'No description available.'),
            limitLength: false,
          ),

          // ✅ FIX 3: Parse ingredients array properly
        'ingredients': (jsonData['ingredients'] as List<dynamic>?)
            ?.map((ingredient) {
        if (ingredient is Map && ingredient.containsKey('name')) {
        return _cleanText(ingredient['name'].toString()); // Clean the name string
        }
        return _cleanText(ingredient.toString());
        })
            .toList() ??
        ['No ingredients listed'],

          'origin': _cleanText(
            _cleanInternalPrefixes(jsonData['origin'] ?? 'Unknown'),
            limitLength: false,
          ),

          // ✅ FIX 4: Properly handle whoShouldEat and whoShouldAvoid
          'whoShouldEat': _cleanInternalPrefixes(
              jsonData['whoShouldEat'] ?? 'Suitable for most individuals.'
          ),

          'whoShouldAvoid': _cleanInternalPrefixes(
              jsonData['whoShouldAvoid'] ?? 'Consult with healthcare provider if you have specific dietary restrictions.'
          ),

          'allergenInfo': _cleanInternalPrefixes(
              jsonData['allergenInfo'] ?? 'No allergen information available.'
          ),

          'quickNote': _cleanInternalPrefixes(
              jsonData['quickNote'] ?? 'No additional notes.'
          ),

          'nutritionalBreakdown': jsonData['nutritionalBreakdown'],
        };
        _isNotFood = false;
      });
    } catch (e) {
      print('Error parsing AI response: $e');
      _parseTextResponse(response);
    }
  }

  String _cleanText(String text, {bool limitLength = true}) {
    // Remove JSON-like artifacts
    text = text
        .replaceAll('"', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll(RegExp(r'^[-:\s]+'), '') // Remove leading dashes, colons, whitespace
        .replaceAll(RegExp(r'[-:\s]+$'), '') // Remove trailing dashes, colons, whitespace
        .trim();

    // Only apply character limit if explicitly requested
    if (limitLength && text.length > 300) {
      int safeLength = text.lastIndexOf(' ', 300);
      if (safeLength > 0) {
        text = text.substring(0, safeLength) + '...';
      } else {
        text = text.substring(0, 300) + '...';
      }
    }

    return text;
  }

  void _parseTextResponse(String response) {
    try {
      Map<String, dynamic> parsedData = {};

      final healthScoreMatch = RegExp(r'Health Score[:\s]*(\d+)').firstMatch(response);
      parsedData['healthScore'] = healthScoreMatch != null
          ? int.parse(healthScoreMatch.group(1)!)
          : 5;

      parsedData['healthDescription'] = _cleanText(_cleanInternalPrefixes(_extractSection(response,
          ['Health Description', 'Health Score Description'],
          'This food item has been analyzed for nutritional value.')), limitLength: false);

      parsedData['description'] = _cleanText(_cleanInternalPrefixes(_extractSection(response,
          ['Description', 'Food Description'],
          'Food item description not available.')), limitLength: false);

      parsedData['ingredients'] = _extractIngredients(response)
          .map((ingredient) => _cleanText(ingredient))
          .toList();

      parsedData['origin'] = _cleanText(_cleanInternalPrefixes(_extractSection(response,
          ['Origin', 'Country of Origin'],
          'Origin information not available.')), limitLength: false);

      parsedData['whoShouldEat'] = _cleanInternalPrefixes(_extractSection(response,
          ['Who Should Eat', 'Who Should Prefer', 'Recommended For', 'Good For'],
          'Suitable for most individuals.'));

      parsedData['whoShouldAvoid'] = _cleanInternalPrefixes(_extractSection(response,
          ['Who Should Avoid', 'Not Recommended For', 'Avoid If'],
          'Consult with healthcare provider if you have specific dietary restrictions.'));

      parsedData['quickNote'] = _cleanInternalPrefixes(_extractSection(response,
          ['Quick Note', 'Fun Fact', 'Did You Know'],
          'Nutritional information based on standard serving size.'));

      // Fallback doesn't parse nutritionalBreakdown
      parsedData['nutritionalBreakdown'] = null;

      setState(() {
        _aiData = parsedData;
        _isNotFood = false;
      });
    } catch (e) {
      print('Error in text parsing: $e');
      setState(() {
        _aiData = null;
      });
    }
  }

  String _extractSection(String text, List<String> headers, String defaultValue) {
    for (String header in headers) {
      final regex = RegExp(
        '$header[:\\s]*([^\n]+(?:\n(?![A-Z][^:]*:)[^\n]+)*)',
        caseSensitive: false,
        multiLine: true,
      );

      final match = regex.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return defaultValue;
  }

  String _extractErrorMessage(String analysis) {
    final lines = analysis.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Error Message')) {
        if (i + 1 < lines.length) {
          return lines[i + 1].trim();
        }
      }
    }
    return 'I can only analyze food items. Please upload an image of food for analysis.';
  }

  // --- UI Building Methods ---
  List<String> _extractIngredients(String text) {
    List<String> ingredients = [];

    final ingredientsMatch = RegExp(
      r'Ingredients?[:\s]*\n((?:[-•*]\s*.+\n?)+)',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(text);

    if (ingredientsMatch != null) {
      final ingredientsText = ingredientsMatch.group(1)!;
      final bulletPoints = RegExp(r'[-•*]\s*(.+)').allMatches(ingredientsText);
      ingredients = bulletPoints.map((m) => m.group(1)!.trim()).toList();
    } else {
      final commaSeparated = RegExp(
        r'Ingredients?[:\s]*([^\n]+)',
        caseSensitive: false,
      ).firstMatch(text);

      if (commaSeparated != null) {
        ingredients = commaSeparated
            .group(1)!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return ingredients.isEmpty ? ['Information not available'] : ingredients;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _isNotFood = false;
      _aiData = null;
      // Show the camera interface when analysis is reset
      _showCameraInterface = true;
    });
    _slideController.reset();
    _fadeController.reset();
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 8) return Colors.green[400]!;
    if (score >= 6) return Colors.lightGreen[400]!;
    if (score >= 4) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Widget _buildHealthScoreSection() {
    if (_aiData == null) return const SizedBox();

    // ✅ Health score is now guaranteed to be an int from _parseAIResponse
    final healthScore = _aiData!['healthScore'] as int;

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.red[400], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '$healthScore/10',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: MediaQuery.of(context).size.width * (healthScore / 10),
                  decoration: BoxDecoration(
                    color: _getHealthScoreColor(healthScore),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _aiData!['healthDescription'] ?? 'No health description available.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    if (_aiData == null) return const SizedBox();

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.cyan[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _aiData!['description'] ?? 'No description available.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    if (_aiData == null) return const SizedBox();

    final ingredients = List<String>.from(_aiData!['ingredients'] ?? []);
    final displayedIngredients = ingredients.take(6).toList();

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_basket, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Primary Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayedIngredients.map((ingredient) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 20, color: Colors.black)),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: const TextStyle(fontSize: 14, color: Colors.black, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginSection() {
    if (_aiData == null) return const SizedBox();

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Origin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _aiData!['origin'] ?? 'Origin unknown.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_aiData == null) return const SizedBox();

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Who should eat this?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    _aiData!['whoShouldEat'] ?? 'Suitable for most individuals.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Who should avoid?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    _aiData!['whoShouldAvoid'] ?? 'Consult with healthcare provider if you have specific dietary restrictions.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteSection() {
    if (_aiData == null) return const SizedBox();

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.cyan[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: Text(
              _aiData!['quickNote'] ?? 'No additional notes.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Moved inside class, renamed, and keys corrected
  Widget _buildNutritionalBreakdownSection() {
    if (_aiData?['nutritionalBreakdown'] == null) return const SizedBox();

    final nutrition = _aiData!['nutritionalBreakdown'];

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nutritional Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildNutritionRow('Calories', '${nutrition['calories'] ?? 'N/A'} kcal'),
                _buildNutritionRow('Protein', '${nutrition['protein'] ?? 'N/A'} g'),
                _buildNutritionRow('Carbohydrates', '${nutrition['carbohydrates'] ?? 'N/A'} g'),
                _buildNutritionRow('Fat', '${nutrition['fat'] ?? 'N/A'} g'),
                _buildNutritionRow('Fiber', '${nutrition['fiber'] ?? 'N/A'} g'),
                _buildNutritionRow('Sugar', '${nutrition['sugar'] ?? 'N/A'} g'),
                _buildNutritionRow('Sodium', '${nutrition['sodium'] ?? 'N/A'} mg'),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          _aiData?['foodName'] ?? 'Describe Food',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),
      // Conditional switch between the new camera interface and the analysis view
      body: _selectedImage == null && _showCameraInterface
          ? _buildImageSelector()
          : _buildAnalysisView(),
    );
  }

  // --- NEW SPLIT-SCREEN CAMERA INTERFACE ---
  Widget _buildImageSelector() {
    return Column(
      children: [
        // Camera Preview Section (Top 70%)
        Expanded(
          flex: 7,
          child: Container(
            color: Colors.black,
            child: Center(
              // NOTE: In a real app, this is where you would integrate the CameraPreview widget.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ready to Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point camera at food or label',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons Section (Bottom 30%) - HORIZONTAL LAYOUT
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Scan Food Button
                  Expanded(
                    child: _buildHorizontalActionButton(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan Food',
                      onTap: () => _pickImage(ImageSource.camera),
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons

                  // Scan Label Button
                  Expanded(
                    child: _buildHorizontalActionButton(
                      icon: Icons.document_scanner_outlined,
                      title: 'Scan Label',
                      // Example: Inside your _buildHorizontalActionButton 'onTap'
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LabelAnalysisScreen()),
                        );
                      },
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10), // Spacing between buttons

                  // Choose from Gallery Button
                  Expanded(
                    child: _buildHorizontalActionButton(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- HELPER FOR HORIZONTAL BUTTONS (FINAL STYLE) ---
  Widget _buildHorizontalActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color, // Now used for foreground (icon/text) color
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 120, // Give the button a fixed height
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, // Solid white background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!, // Subtle grey border
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30), // Icon uses the passed color (black)
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color, // Text uses the passed color (black)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 24),

          if (_isAnalyzing) ...[
            _buildLoadingWidget(),
          ] else if (_analysisResult != null) ...[
            if (_isNotFood)
              _buildNotFoodWidget()
            else if (_aiData != null)
              _buildAIResults()
            else
              _buildFormattedAnalysis(_analysisResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildAIResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Food Name (if available)
            if (_aiData?['foodName'] != null)
              Container(
                decoration: _getCardDecoration(),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.amber[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiData!['foodName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Health Score Section
            _buildHealthScoreSection(),

            // Description Section
            _buildDescriptionSection(),

            // Ingredients Section
            _buildIngredientsSection(),

            // Origin Section
            _buildOriginSection(),

            // Recommendations Section
            _buildRecommendationsSection(),

            // // Allergen Information (if available)
            // if (_aiData?['allergenInfo'] != null)
            //   Container(
            //     decoration: _getCardDecoration(),
            //     padding: const EdgeInsets.all(16),
            //     margin: const EdgeInsets.only(bottom: 16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.warning, color: Colors.orange[600], size: 20),
            //             const SizedBox(width: 8),
            //             const Text(
            //               'Allergen Information',
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.black,
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         Container(
            //           padding: const EdgeInsets.all(12),
            //           decoration: BoxDecoration(
            //             color: Colors.grey[100],
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           child: Text(
            //             _aiData!['allergenInfo'],
            //             style: const TextStyle(
            //               fontSize: 14,
            //               color: Colors.black,
            //               height: 1.4,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),

         //   _buildNutritionalBreakdownSection(),

            // Quick Note Section
            _buildQuickNoteSection(),

            // Try Another Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.home); // Navigate home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Analyze Another Food',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _getCardDecoration(),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoodWidget() {
    final errorMessage = _extractErrorMessage(_analysisResult!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not Food Detected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (){

            Navigator.pushNamed(context, AppRoutes.home);

            },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAnalysis(String analysis) {
    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Text(
        analysis,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          height: 1.4,
        ),
      ),
    );
  }
}