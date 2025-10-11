import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'dart:convert';

class Recipegenerator extends StatefulWidget {
  const Recipegenerator({Key? key}) : super(key: key);

  @override
  State<Recipegenerator> createState() => _RecipegeneratorState();
}

class _RecipegeneratorState extends State<Recipegenerator>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _dietaryRestrictionsController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isGenerating = false;
  Map<String, dynamic>? _currentRecipe;
  Map<String, dynamic>? _lastRecipe;

  final List<String> _cuisineTypes = [
    'Any',
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Mediterranean',
    'American',
    'Thai',
    'Japanese',
    'French',
  ];

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Appetizer',
  ];

  String _selectedCuisine = 'Any';
  String _selectedMealType = 'Lunch';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _loadLastRecipe();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ingredientsController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  Future<void> _loadLastRecipe() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recipe_calculations')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (doc.docs.isNotEmpty) {
          setState(() {
            _lastRecipe = doc.docs.first.data();
          });
        }
      }
    } catch (e) {
      print('Error loading last recipe: $e');
    }
  }

  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some ingredients'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _currentRecipe = null;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found in .env file. Please add GEMINI_API_KEY to your .env file.');
      }
      
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = _buildPrompt();
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        final recipeData = _parseRecipeResponse(response.text!);
        await _saveRecipeToFirebase(recipeData);
        
        setState(() {
          _currentRecipe = recipeData;
          _lastRecipe = recipeData;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recipe generated successfully!'),
            backgroundColor: AppColors.primary(Provider.of<ThemeProvider>(context, listen: false).isDarkMode),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Empty response from Gemini');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating recipe: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _buildPrompt() {
    return '''
Create a recipe using these ingredients: ${_ingredientsController.text}

Requirements:
- Cuisine: $_selectedCuisine
- Meal Type: $_selectedMealType
- Dietary Restrictions: ${_dietaryRestrictionsController.text.isEmpty ? 'None' : _dietaryRestrictionsController.text}

Please respond with ONLY a valid JSON object in this exact format (no extra text, no markdown):
{
  "name": "Recipe Name Here",
  "description": "Brief description of the dish",
  "prepTime": "20 minutes",
  "cookTime": "35 minutes", 
  "servings": 4,
  "ingredients": [
    "1.5 lbs Chicken Breast, cut into 1-inch cubes",
    "1 cup Yogurt (full fat)",
    "2 tbsp Tandoori Masala"
  ],
  "instructions": [
    "In a bowl, marinate the chicken cubes with yogurt and spices.",
    "Preheat oven to 400°F (200°C).",
    "Thread the marinated chicken onto skewers.",
    "Bake for 20-25 minutes until cooked through."
  ],
  "cuisine": "$_selectedCuisine",
  "mealType": "$_selectedMealType",
  "difficulty": "Medium",
  "nutritionalInfo": {
    "calories": "Approx 350 per serving",
    "protein": "35g",
    "carbs": "10g",
    "fat": "18g"
  }
}

Make the recipe practical with specific measurements and clear instructions.
Include nutritional information if possible.
''';
  }

  Map<String, dynamic> _parseRecipeResponse(String response) {
    try {
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      } else if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      int startIndex = cleanResponse.indexOf('{');
      int endIndex = cleanResponse.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      final parsed = json.decode(cleanResponse);
      return parsed;
    } catch (e) {
      return {
        'name': 'Generated Recipe',
        'description': 'A delicious recipe created from your ingredients',
        'prepTime': '20 minutes',
        'cookTime': '30 minutes',
        'servings': 4,
        'ingredients': _ingredientsController.text.split(',').map((e) => e.trim()).toList(),
        'instructions': [
          'Prepare all ingredients as listed above.',
          'Follow standard cooking methods for your chosen cuisine type.',
          'Cook until ingredients are properly prepared and seasoned.',
          'Serve hot and enjoy your meal!'
        ],
        'cuisine': _selectedCuisine,
        'mealType': _selectedMealType,
        'difficulty': 'Medium',
        'nutritionalInfo': {
          'calories': 'Varies based on ingredients',
          'protein': 'Varies based on ingredients',
          'carbs': 'Varies based on ingredients',
          'fat': 'Varies based on ingredients'
        }
      };
    }
  }

  Future<void> _saveRecipeToFirebase(Map<String, dynamic> recipeData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existingDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recipe_calculations')
            .get();
        
        for (var doc in existingDocs.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('recipe_calculations')
            .add({
          ...recipeData,
          'timestamp': FieldValue.serverTimestamp(),
          'ingredients_input': _ingredientsController.text,
          'cuisine_input': _selectedCuisine,
          'meal_type_input': _selectedMealType,
          'dietary_restrictions_input': _dietaryRestrictionsController.text,
        });
      }
    } catch (e) {
      print('Error saving recipe: $e');
    }
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(40, 50, 49, 0.85),
            const Color.fromARGB(215, 14, 14, 14),
            Color.fromRGBO(33, 43, 42, 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary(isDarkTheme).withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(isDarkTheme).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme).withOpacity(0.95),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.90),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary(isDarkTheme).withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(isDarkTheme).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    required bool isDarkTheme,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textPrimary(isDarkTheme)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDarkTheme)),
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required bool isDarkTheme,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 14,
          ),
          dropdownColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, bool isDark, {required bool isRecent}) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with recipe name and recent indicator
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe['name'] ?? 'Recipe',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              if (isRecent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe['description'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          
          // Recipe details row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip('Prep: ${recipe['prepTime'] ?? 'N/A'}', Icons.schedule, isDark),
              _buildDetailChip('Cook: ${recipe['cookTime'] ?? 'N/A'}', Icons.timer, isDark),
              _buildDetailChip('Serves: ${recipe['servings'] ?? 'N/A'}', Icons.people, isDark),
              _buildDetailChip('${recipe['difficulty'] ?? 'Medium'}', Icons.bar_chart, isDark),
            ],
          ),
          const SizedBox(height: 16),
          
          // Nutritional Info
          if (recipe['nutritionalInfo'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutritional Information (approx):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildNutritionChip('Calories: ${recipe['nutritionalInfo']['calories']}', Icons.local_fire_department, isDark),
                    _buildNutritionChip('Protein: ${recipe['nutritionalInfo']['protein']}', Icons.fitness_center, isDark),
                    _buildNutritionChip('Carbs: ${recipe['nutritionalInfo']['carbs']}', Icons.grain, isDark),
                    _buildNutritionChip('Fat: ${recipe['nutritionalInfo']['fat']}', Icons.water_drop, isDark),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Ingredients
          Text(
            'Ingredients:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          ...((recipe['ingredients'] as List<dynamic>?) ?? []).map((ingredient) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          const SizedBox(height: 16),
          
          // Instructions
          Text(
            'Instructions:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          ...((recipe['instructions'] as List<dynamic>?) ?? []).asMap().entries.map((entry) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          
          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _shareRecipe(recipe);
                  },
                  icon: Icon(
                    Icons.share,
                    color: Colors.white,
                  ),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _saveRecipeToFavorites(recipe);
                  },
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                  ),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _shareRecipe(Map<String, dynamic> recipe) {
    final recipeText = '''
${recipe['name'] ?? 'Recipe'}

${recipe['description'] ?? ''}

Prep Time: ${recipe['prepTime'] ?? 'N/A'}
Cook Time: ${recipe['cookTime'] ?? 'N/A'}  
Servings: ${recipe['servings'] ?? 'N/A'}
Difficulty: ${recipe['difficulty'] ?? 'Medium'}

Nutritional Information (approx):
${recipe['nutritionalInfo'] != null ? 
  'Calories: ${recipe['nutritionalInfo']['calories']}\n' +
  'Protein: ${recipe['nutritionalInfo']['protein']}\n' +
  'Carbs: ${recipe['nutritionalInfo']['carbs']}\n' +
  'Fat: ${recipe['nutritionalInfo']['fat']}' 
  : 'Not available'}

Ingredients:
${((recipe['ingredients'] as List<dynamic>?) ?? []).map((ingredient) => '• $ingredient').join('\n')}

Instructions:
${((recipe['instructions'] as List<dynamic>?) ?? []).asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}

Generated by TrackAI Recipe Generator
    ''';
    
    Clipboard.setData(ClipboardData(text: recipeText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recipe copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveRecipeToFavorites(Map<String, dynamic> recipe) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorite_recipes')
            .add({
          ...recipe,
          'timestamp': FieldValue.serverTimestamp(),
          'saved_from': 'recipe_generator',
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recipe saved to favorites!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: ${e.toString()}'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDark),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(
                  lucide.LucideIcons.chefHat,
                  color: Color(0xFF26A69A),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Recipe Generator',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDark),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Input Form Card
                      Container(
                        decoration: _getCardDecoration(isDark),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  lucide.LucideIcons.chefHat,
                                  color: Color(0xFF26A69A),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Recipe Generator',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate creative recipes based on ingredients you have and your preferences.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Available Ingredients Input
                            _buildInputField(
                              label: 'Available Ingredients (comma-separated) *',
                              controller: _ingredientsController,
                              hintText: 'e.g., chicken breast, rice, tomatoes, onions, garlic',
                              isDarkTheme: isDark,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            // Cuisine Type Dropdown
                            _buildDropdownField(
                              label: 'Cuisine Type (Optional)',
                              value: _selectedCuisine,
                              options: _cuisineTypes,
                              isDarkTheme: isDark,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCuisine = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Meal Type Dropdown
                            _buildDropdownField(
                              label: 'Meal Type (Optional)',
                              value: _selectedMealType,
                              options: _mealTypes,
                              isDarkTheme: isDark,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedMealType = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Dietary Restrictions Input
                            _buildInputField(
                              label: 'Dietary Restrictions (Optional)',
                              controller: _dietaryRestrictionsController,
                              hintText: 'e.g., vegetarian, gluten-free, dairy-free, nut-free',
                              isDarkTheme: isDark,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Generate Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _generateRecipe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            shadowColor: AppColors.black.withOpacity(0.4),
                          ),
                          child: _isGenerating
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Generating Recipe...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_fix_high,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Generate Recipe', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Recipe Result
                      if (_currentRecipe != null)
                        _buildRecipeCard(_currentRecipe!, isDark, isRecent: false)
                      else if (_lastRecipe != null)
                        _buildRecipeCard(_lastRecipe!, isDark, isRecent: true),
                      
                      // Empty state if no recipes
                      if (_currentRecipe == null && _lastRecipe == null)
                        Container(
                          decoration: _getCardDecoration(isDark),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                lucide.LucideIcons.chefHat,
                                size: 64,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withOpacity(0.5)
                                    : AppColors.lightTextSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recipes yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary(isDark),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your ingredients and preferences to generate your first recipe!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}