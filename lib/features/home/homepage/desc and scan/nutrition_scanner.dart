import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:trackai/features/home/homepage/desc%20and%20scan/gemini.dart';

// --- Updated Color Scheme ---
const Color kBackgroundColor = Colors.white;
const Color kCardColor = Color(0xFFF8F9FA);
const Color kCardColorDarker = Color(0xFFE9ECEF);
const Color kTextColor = Color(0xFF212529);
const Color kTextSecondaryColor = Color(0xFF6C757D);
const Color kAccentColor = Color(0xFF131212);
const Color kSuccessColor = Color(0xFF28A745);
const Color kWarningColor = Color(0xFFFFC107);
const Color kDangerColor = Color(0xFFDC3545);
// -----------------------------------------

class NutritionScannerScreen extends StatefulWidget {
  final File? imageFile;
  const NutritionScannerScreen({Key? key,this.imageFile,}) : super(key: key);

  @override
  State<NutritionScannerScreen> createState() => _NutritionScannerScreenState();
}

class _NutritionScannerScreenState extends State<NutritionScannerScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isNotFoodLabel = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();
  final Gemini _gemini = Gemini();

  // Nutrition Data Structure
  Map<String, dynamic>? _nutritionData;
  List<Map<String, dynamic>> _editableIngredients = [];
  bool _showCameraInterface = true;
  int _currentTab = 0; // 0: Overview, 1: Detailed Analysis, 2: Ingredients

  // Form controllers for adding ingredients
  final _formKey = GlobalKey<FormState>();
  final _ingredientNameController = TextEditingController();
  final _ingredientWeightController = TextEditingController();

  @override
  @override
  void initState() {
    super.initState();

    // --- 1. Initialize controllers first ---
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

    // --- 2. Add this logic to check for the passed image ---
    if (widget.imageFile != null) {
      setState(() {
        _selectedImage = widget.imageFile;
        _showCameraInterface = false; // Bypass the selector
      });

      // Call analysis after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeFoodImage();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _ingredientNameController.dispose();
    _ingredientWeightController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration({bool elevated = true}) {
    return BoxDecoration(
      color: kCardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1.0,
      ),
      boxShadow: elevated
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ]
          : null,
    );
  }

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
          _isNotFoodLabel = false;
          _nutritionData = null;
          _editableIngredients = [];
          _showCameraInterface = false;
          _currentTab = 0;
        });

        HapticFeedback.lightImpact();
        await _analyzeFoodImage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeFoodImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _gemini.describeFoodFromImage(_selectedImage!);

      try {
        final jsonData = json.decode(result);
        final isFood = jsonData['isFood'] == true;

        setState(() {
          _isAnalyzing = false;
        });

        if (isFood) {
          _parseFoodResponse(jsonData);
        } else {
          setState(() {
            _isNotFoodLabel = true;
            _nutritionData = null;
            _showErrorSnackBar(
                jsonData['errorMessage'] ?? 'No food was detected.');
          });
        }

        _fadeController.forward();
        _slideController.forward();
        HapticFeedback.mediumImpact();
      } catch (parseError) {
        setState(() {
          _isAnalyzing = false;
        });
        print('Raw API Response (Invalid JSON): $result');
        _showErrorSnackBar(
            'Analysis failed. The AI response was not in the correct format.');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorSnackBar('Analysis failed: $e');
    }
  }

  void _parseFoodResponse(Map<String, dynamic> jsonData) {
    try {
      if (jsonData['isFood'] == false) {
        setState(() {
          _isNotFoodLabel = true;
          _nutritionData = null;
          _showErrorSnackBar(
              jsonData['errorMessage'] ?? 'No food was detected.');
        });
        return;
      }

      setState(() {
        _nutritionData = jsonData;
        if (jsonData['ingredients'] != null) {
          _editableIngredients =
          List<Map<String, dynamic>>.from(jsonData['ingredients']);
        } else {
          _editableIngredients = [];
        }
        _isNotFoodLabel = false;
      });
    } catch (e) {
      print('Error parsing food response: $e');
      _showErrorSnackBar('Failed to parse food data.');
      setState(() {
        _nutritionData = null;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kDangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _isNotFoodLabel = false;
      _nutritionData = null;
      _editableIngredients = [];
      _showCameraInterface = true;
      _currentTab = 0;
    });
    _slideController.reset();
    _fadeController.reset();
  }

  void _setCurrentTab(int tab) {
    setState(() {
      _currentTab = tab;
    });
    HapticFeedback.lightImpact();
  }

  // --- Ingredient Management ---
  void _removeIngredient(int index) {
    setState(() {
      _editableIngredients.removeAt(index);
    });
    HapticFeedback.mediumImpact();
  }

  void _showAddIngredientDialog() {
    _ingredientNameController.clear();
    _ingredientWeightController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kBackgroundColor, // Use app's light background
          surfaceTintColor: kBackgroundColor,
          title: const Text('Add Ingredient', style: TextStyle(color: kTextColor)), // Use app's text color
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _ingredientNameController,
                  style: const TextStyle(color: kTextColor), // Use app's text color
                  decoration: InputDecoration(
                    labelText: 'Ingredient Name',
                    labelStyle: const TextStyle(color: kTextSecondaryColor),
                    filled: true,
                    fillColor: kCardColorDarker, // Use light card color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder( // Added for consistency
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kAccentColor),
                    ),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Cannot be empty' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ingredientWeightController,
                  style: const TextStyle(color: kTextColor), // Use app's text color
                  decoration: InputDecoration(
                    labelText: 'Weight (g)',
                    labelStyle: const TextStyle(color: kTextSecondaryColor),
                    filled: true,
                    fillColor: kCardColorDarker, // Use light card color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder( // Added for consistency
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kAccentColor),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Cannot be empty';
                    if (int.tryParse(value) == null) return 'Must be a number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: kTextSecondaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor, // Use app's accent color (black)
                foregroundColor: Colors.white, // Text on black must be white
              ),
              onPressed: _addIngredient,
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  void _addIngredient() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _editableIngredients.add({
          'name': _ingredientNameController.text,
          'weight_g': int.parse(_ingredientWeightController.text),
        });
      });
      Navigator.pop(context);
      HapticFeedback.lightImpact();
    }
  }
  Widget _buildNutritionalEstimate() {
    if (_nutritionData == null) return const SizedBox();

    final breakdown = _nutritionData!['nutritionalBreakdown'] ?? {};
    final estimatedWeight = _nutritionData!['totalEstimatedWeight_g'] ?? 0;
    final calories = breakdown['calories'] ?? 0;

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutritional Estimate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated Weight: ~${estimatedWeight}g',
            style: const TextStyle(
              fontSize: 15,
              color: kTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // 🍽 Calories card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCardColorDarker,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: kAccentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Calories",
                      style: TextStyle(
                        color: kTextSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$calories',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ✅ FIXED: Nutrient Cards without GridView
          Row(
            children: [
              Expanded(
                child: _buildNutrientCard(
                  'Protein',
                  '${breakdown['protein_g'] ?? 0}',
                  'g',
                  lucide.LucideIcons.zap,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutrientCard(
                  'Carbs',
                  '${breakdown['carbohydrates_g'] ?? 0}',
                  'g',
                  lucide.LucideIcons.wheat,
                  kSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNutrientCard(
                  'Fat',
                  '${breakdown['fat_g'] ?? 0}',
                  'g',
                  lucide.LucideIcons.droplet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNutrientCard(
                  'Fiber',
                  '${breakdown['fiber_g'] ?? 0}',
                  'g',
                  Icons.eco,
                  const Color(0xFFE37F4A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🧾 Log meal button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Add log meal logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text(
                'Log This Meal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNutrientCard(
      String title,
      String value,
      String unit,
      IconData icon,
      Color iconColor,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColorDarker,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kTextSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHealthScore() {
    if (_nutritionData == null) return const SizedBox();

    final healthScore = _nutritionData!['healthScore'] as num? ?? 8;
    final healthDescription =
        _nutritionData!['healthDescription'] ?? 'Healthy food item';

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  '${healthScore.toInt()}/10',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],

          ),
          const SizedBox(height: 16),
          // Health Score Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: healthScore / 10.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getHealthScoreColor(healthScore.toInt())),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            healthDescription,
            style: const TextStyle(
              fontSize: 15,
              color: kTextSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Tab Buttons
          LayoutBuilder(
            builder: (context, constraints) {

                return Row(
                  children: [

                    Expanded(
                      child: _buildTabButton('Refine Ingredients', 2, Icons.edit),
                    ),
                      SizedBox(width: 10,),
                    Expanded(
                      child: _buildTabButton('Detailed Analysis', 1, Icons.bar_chart),
                    ),
                  ],
                );
                          },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int tabIndex, IconData icon) {
    bool isActive = _currentTab == tabIndex;
    return ElevatedButton(
      onPressed: () => _setCurrentTab(tabIndex),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? kAccentColor : kCardColorDarker,
        foregroundColor: isActive ? Colors.white : kTextColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive ? kAccentColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        elevation: 0,
        minimumSize: Size.zero, // Removes default minimum size constraint
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Removes extra padding
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Shrink to content size
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6), // Reduced spacing
          Flexible( // Prevents text overflow
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13, // Slightly reduced font size
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis, // Handle long text
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }


  Color _getHealthScoreColor(int score) {
    if (score >= 8) return kSuccessColor;
    if (score >= 5) return kWarningColor;
    return kDangerColor;
  }

  Widget _buildDescriptionSection() {
    if (_nutritionData == null) return const SizedBox();

    final analysis = _nutritionData!['descriptionAnalysis'] ?? '';
    final ingredients = _nutritionData!['ingredients'] as List<dynamic>? ?? [];
    final ingredientNames =
    ingredients.map((ing) => ing['name'] as String? ?? '').join(', ');

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),

          // Identified Ingredients
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: kTextColor,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: 'Identified as: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ingredientNames.isNotEmpty
                      ? ingredientNames
                      : 'Various food items',
                  style: const TextStyle(color: kTextSecondaryColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE9ECEF)),
          const SizedBox(height: 16),

          // Analysis
          const Text(
            'Analysis',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: kTextColor),
          ),
          const SizedBox(height: 12),
          Text(
            analysis,
            style: const TextStyle(
              fontSize: 15,
              color: kTextSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    if (_nutritionData == null) return const SizedBox();

    final benefits = _nutritionData!['healthBenefits'] as List<dynamic>? ?? [];

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(17),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Health Benefits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          if (benefits.isEmpty)
            const Text(
              'No detailed health benefits were provided by the analysis.',
              style: TextStyle(color: kTextSecondaryColor),
            )
          else
            ...benefits.map((benefit) {
              final String ingredient = benefit['ingredient'] ?? 'Unknown';
              final String text = benefit['benefit'] ?? 'No description.';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildHealthBenefit(ingredient, text),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildHealthBenefit(String ingredient, String benefit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColorDarker,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: kSuccessColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '$ingredient:',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            benefit,
            style: const TextStyle(
              fontSize: 14,
              color: kTextSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    if (_nutritionData == null) return const SizedBox();

    int totalWeight = _editableIngredients.fold(
        0, (sum, item) => sum + (item['weight_g'] as num? ?? 0).toInt());

    return Container(
      decoration: _getCardDecoration(),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredient Approval',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust the AI\'s estimates for a more accurate result. Add or remove items as needed.',
            style: TextStyle(
              fontSize: 15,
              color: kTextSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // AI Tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAccentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kAccentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: kAccentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Tip: I can only see what\'s on top! Consider adding hidden ingredients like sauces or oils.',
                    style: TextStyle(
                      fontSize: 14,
                      color: kAccentColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ingredients List with new card style
          ..._editableIngredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            return _buildIngredientItem(ingredient, index);
          }).toList(),

          const SizedBox(height: 20),

          // Add Ingredient Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddIngredientDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAccentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: kAccentColor),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Ingredient'),
            ),
          ),

          const SizedBox(height: 20),

          // Total Weight
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardColorDarker,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Est. Weight:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                Text(
                  '${totalWeight}g',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Back to Results Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _setCurrentTab(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Results',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(Map<String, dynamic> ingredient, int index) {
    final String name = ingredient['name'] ?? 'Unknown';
    final int weight = (ingredient['weight_g'] as num? ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: _getCardDecoration(), // Use the app's existing light card style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Title and Delete Button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.apple, color: kSuccessColor, size: 20), // Use app's theme color
                  const SizedBox(width: 8),
                  Text(
                    'Ingredient #${index + 1}',
                    style: const TextStyle(
                      color: kTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.delete, color: kDangerColor, size: 20), // Use app's theme color
                onPressed: () => _removeIngredient(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Bottom Row: Name and Weight Fields ---
          Row(
            children: [
              // --- Name Field ---
              Expanded(
                flex: 3, // Give name more space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    // This container mimics the disabled text field style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: kCardColorDarker, // Use light theme inner field color
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(color: kTextColor, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // --- Weight Field ---
              Expanded(
                flex: 2, // Give weight less space
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight (g)',
                      style: TextStyle(color: kTextSecondaryColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: kCardColorDarker, // Use light theme inner field color
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        weight.toString(),
                        style: const TextStyle(color: kTextColor, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kBackgroundColor,
        scrolledUnderElevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: kTextColor),
        ),
        title: Text(
          _nutritionData?['foodName'] ?? 'Nutrition Scanner',
          style: const TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedImage != null || _nutritionData != null)
            IconButton(
              onPressed: _resetAnalysis,
              icon: const Icon(Icons.refresh, color: kTextColor),
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: _selectedImage == null && _showCameraInterface
          ? _buildImageSelector()
          : _buildAnalysisView(),
    );
  }
  Widget _buildImageSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Column(
          children: [
            // Camera Preview Section
            Expanded(
              flex: isTablet ? 6 : 7,
              child: Container(
                color: Colors.black,
                child: Center(
                  // NOTE: Replace this placeholder with your CameraPreview widget
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera,
                        size: isTablet ? 80 : 64,
                        color: kTextSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to Scan Food',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isTablet ? 24 : 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point camera at your food',
                        style: TextStyle(
                          color: kTextSecondaryColor,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons Section
            Expanded(
              flex: isTablet ? 4 : 3,
              child: Container(
                color: kBackgroundColor, // Use your defined background color
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    // Adjusted padding slightly
                    horizontal: isTablet ? 32.0 : 16.0,
                    vertical: isTablet ? 24.0 : 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Scan Food Button - Wrapped in Expanded
                      Expanded(
                        child: _buildHorizontalActionButton(
                          icon: Icons.qr_code_scanner,
                          title: 'Scan Food',
                          onTap: () => _pickImage(ImageSource.camera),
                          isTablet: isTablet,
                          color: Colors.black, // Explicitly set color
                        ),
                      ),

                      SizedBox(width: isTablet ? 24 : 12), // Adjusted spacing

                      Expanded(
                        child: _buildHorizontalActionButton(
                          icon: Icons.document_scanner_outlined,
                          title: 'Scan Label',
                          // Assuming _pickImage is simplified and doesn't need type
                          onTap: () => _pickImage(ImageSource.camera),
                          isTablet: isTablet,
                          color: Colors.black, // Explicitly set color
                        ),
                      ),

                      SizedBox(width: isTablet ? 24 : 12), // Adjusted spacing

                      // Gallery Button - Wrapped in Expanded
                      Expanded(
                        child: _buildHorizontalActionButton(
                          icon: Icons.image_search, // Consistent icon
                          title: 'Gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                          isTablet: isTablet,
                          color: Colors.black, // Explicitly set color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _buildHorizontalActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isTablet, // Keep for potential size adjustments
    Color color = Colors.black // Default color
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: isTablet ? 36 : 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          if (_selectedImage != null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 24),

          if (_isAnalyzing) ...[
            _buildLoadingWidget(),
          ] else if (_nutritionData != null) ...[
            _buildFoodResults()
          ] else if (_isNotFoodLabel) ...[
            _buildNotLabelWidget()
          ] else ...[
            _buildNotLabelWidget(
                message: 'An unknown error occurred. Please try again.')
          ],
        ],
      ),
    );
  }

  Widget _buildFoodResults() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildNutritionalEstimate(),
            _buildHealthScore(),

            if (_currentTab == 0) ...[
              _buildDescriptionSection(),
            ] else if (_currentTab == 1) ...[
              _buildDetailedAnalysis(),
            ] else if (_currentTab == 2) ...[
              _buildIngredientsSection(),
            ],

            if (_currentTab != 2)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton(
                  onPressed: _resetAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Scan Another Food',
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
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kAccentColor),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Analyzing food image...',
            style: TextStyle(
              fontSize: 16,
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLabelWidget(
      {String message =
      'No food was detected. Please take a clear photo of your meal.'}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWarningColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: kWarningColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: kTextSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _resetAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}