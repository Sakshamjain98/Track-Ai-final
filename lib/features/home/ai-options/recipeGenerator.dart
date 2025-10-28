import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/recipe_results_screen.dart';

class AIRecipeGenerator extends StatefulWidget {
  const AIRecipeGenerator({Key? key}) : super(key: key);

  @override
  State<AIRecipeGenerator> createState() => _AIRecipeGeneratorState();
}

class _AIRecipeGeneratorState extends State<AIRecipeGenerator> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _ingredientsController = TextEditingController();
  final _restrictionsController = TextEditingController();
  final _cuisineController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedCuisine = '';
  String _selectedMealType = '';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedRecipe;

  // Options
  final List<String> _displayCuisineOptions = [
    'Italian',
    'Mexican',
    'Chinese',
    'Indian',
    'Thai',
    'Japanese',
    'Mediterranean',
    'American',
  ];

  final List<String> _mealTypeOptions = [
    'Any',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  // Total input steps
  final int _totalInputSteps = 4;

  @override
  void dispose() {
    _ingredientsController.dispose();
    _restrictionsController.dispose();
    _pageController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalInputSteps) {
      if (_currentPage == 0) {
        _selectedCuisine = _cuisineController.text.trim();
      }

      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showValidationSnackBar('Please complete this step to continue.');
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _selectedMealType.isNotEmpty;
      case 1:
        return _selectedCuisine.isNotEmpty;
      case 2:
        return _ingredientsController.text.isNotEmpty;
      case 3:
        return true;
      default:
        return true;
    }
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _generateRecipe() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar('Please complete all required steps.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final ingredients = _ingredientsController.text.split(',').length;
      final cuisine = _selectedCuisine.toLowerCase();
      final mealType = _selectedMealType.toLowerCase();

      final inferredServings = _calculateServings(ingredients, mealType);
      final inferredTime = _calculateCookingTime(cuisine, mealType, ingredients);
      final inferredDifficulty = _calculateDifficulty(inferredTime);

      await Future.delayed(const Duration(seconds: 3));

      final recipe = _createRecipe(inferredServings, inferredTime, inferredDifficulty);

      // Navigate to results screen instead of showing in page view
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeResultsScreen(
            recipe: recipe,
            onNewRecipe: _resetForm,
          ),
        ),
      );

      setState(() {
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _currentPage = 0;
      _generatedRecipe = null;
      _ingredientsController.clear();
      _restrictionsController.clear();
      _cuisineController.clear();
      _selectedCuisine = '';
      _selectedMealType = '';
    });
    _pageController.jumpToPage(0);
  }

  // ... Keep all your helper methods (_calculateServings, _calculateCookingTime,
  // _calculateDifficulty, _createRecipe, _generateRecipeName, etc.) exactly as they were ...

  // Only include the helper methods that are used in _createRecipe
  int _calculateServings(int ingredientCount, String mealType) {
    int baseServings = 2;
    if (ingredientCount > 5) baseServings = 4;
    if (ingredientCount > 8) baseServings = 6;
    if (mealType == 'dinner') baseServings += 1;
    if (mealType == 'snack') baseServings = max(2, baseServings - 1);
    return baseServings;
  }

  String _calculateCookingTime(String cuisine, String mealType, int ingredientCount) {
    int baseTime = 20;
    if (cuisine.contains('indian') || cuisine.contains('italian')) baseTime += 15;
    if (cuisine.contains('chinese') || cuisine.contains('thai')) baseTime += 10;
    if (mealType == 'dinner') baseTime += 10;
    if (mealType == 'breakfast') baseTime -= 5;
    if (mealType == 'snack') baseTime -= 10;
    baseTime += (ingredientCount * 2);
    return baseTime.toString();
  }

  String _calculateDifficulty(String cookingTime) {
    int time = int.tryParse(cookingTime) ?? 30;
    if (time < 20) return 'Easy (Under 20 min)';
    if (time <= 40) return 'Medium (20-40 min)';
    if (time <= 60) return 'Hard (40-60 min)';
    return 'Expert (60+ min)';
  }

  Map<String, dynamic> _createRecipe(int inferredServings, String inferredTime, String inferredDifficulty) {
    final ingredients = _ingredientsController.text.split(',').map((e) => e.trim()).toList();
    final servings = inferredServings;
    final cookingTime = inferredTime;
    final cuisineText = _selectedCuisine;

    String recipeName = _generateRecipeName(ingredients, cuisineText, _selectedMealType);
    List<String> recipeIngredients = _generateRecipeIngredients(ingredients, servings);
    List<String> instructions = _generateInstructions(ingredients, cuisineText, _selectedMealType);
    final nutritionalInfo = _generateNutritionalInfo(ingredients, servings);
    final tips = _generateTips(cuisineText, _selectedMealType);

    return {
      'name': recipeName,
      'description': 'A delicious ${cuisineText.toLowerCase()} ${_selectedMealType.toLowerCase()} recipe made with ${ingredients.take(3).join(', ')}.',
      'prepTime': '${(int.tryParse(cookingTime) ?? 30) ~/ 3} minutes',
      'cookTime': '$cookingTime minutes',
      'totalTime': '${(int.tryParse(cookingTime) ?? 30) + ((int.tryParse(cookingTime) ?? 30) ~/ 3)} minutes',
      'servings': servings,
      'difficulty': inferredDifficulty,
      'cuisine': cuisineText,
      'mealType': _selectedMealType,
      'ingredients': recipeIngredients,
      'instructions': instructions,
      'nutritionalInfo': nutritionalInfo,
      'tips': tips,
      'generatedOn': DateTime.now().toString().split(' ')[0],
    };
  }

  String _generateRecipeName(List<String> ingredients, String cuisine, String mealType) {
    String mainIngredient = ingredients.isNotEmpty ? ingredients[0] : 'Mixed';
    Map<String, List<String>> cuisineStyles = {
      'Italian': ['Pasta', 'Risotto', 'Frittata', 'Bruschetta'],
      'Chinese': ['Stir-fry', 'Fried Rice', 'Noodles', 'Dumplings'],
      'Indian': ['Curry', 'Masala', 'Biryani', 'Dal'],
      'Mexican': ['Tacos', 'Quesadillas', 'Burrito Bowl', 'Enchiladas'],
      'Mediterranean': ['Salad', 'Grilled', 'Stuffed', 'Roasted'],
      'American': ['Sandwich', 'Burger', 'Skillet', 'Casserole'],
      'Thai': ['Pad', 'Tom', 'Larb', 'Curry'],
      'Japanese': ['Teriyaki', 'Tempura', 'Donburi', 'Miso'],
      'French': ['Sauté', 'Ratatouille', 'Quiche', 'Tarte'],
    };
    List<String> styles = cuisineStyles[cuisine] ?? ['Special', 'Delicious', 'Homestyle', 'Classic'];
    String style = styles[0];
    return '$style $mainIngredient ${mealType.toLowerCase().replaceAll('Breakfast', 'Bowl').replaceAll('Lunch', 'Plate').replaceAll('Dinner', 'Feast')}';
  }

  List<String> _generateRecipeIngredients(List<String> baseIngredients, int servings) {
    List<String> recipeIngredients = [];
    for (String ingredient in baseIngredients) {
      if (ingredient.trim().isNotEmpty) {
        String quantity = _getIngredientQuantity(ingredient, servings);
        recipeIngredients.add('$quantity ${ingredient.trim()}');
      }
    }
    recipeIngredients.addAll(_getCommonIngredients(_selectedMealType, servings));
    return recipeIngredients;
  }

  String _getIngredientQuantity(String ingredient, int servings) {
    Map<String, String> quantities = {
      'chicken': '${servings * 4} oz',
      'beef': '${servings * 4} oz',
      'fish': '${servings * 4} oz',
      'rice': '${servings ~/ 2} cups',
      'pasta': '${servings * 3} oz',
      'onion': '${(servings / 2).ceil()} medium',
      'garlic': '${servings * 2} cloves',
      'tomato': '${servings} medium',
      'potato': '${servings} medium',
      'oil': '2-3 tbsp',
      'salt': 'to taste',
      'pepper': 'to taste',
    };
    for (String key in quantities.keys) {
      if (ingredient.toLowerCase().contains(key)) {
        return quantities[key]!;
      }
    }
    return '${servings ~/ 2 + 1}';
  }

  List<String> _getCommonIngredients(String mealType, int servings) {
    switch (mealType) {
      case 'Breakfast':
        return ['2 tbsp Olive oil', 'Salt to taste', 'Black pepper to taste', '1 tsp Herbs (optional)'];
      case 'Lunch':
      case 'Dinner':
        return ['3 tbsp Cooking oil', 'Salt to taste', 'Black pepper to taste', '2 cloves Garlic', '1 medium Onion'];
      case 'Snack':
        return ['1 tbsp Oil', 'Pinch of salt', 'Spices to taste'];
      case 'Dessert':
        return ['2 tbsp Sugar', '1 tsp Vanilla extract', 'Pinch of salt'];
      default:
        return ['Salt to taste', 'Pepper to taste', '1 tbsp Oil'];
    }
  }

  List<String> _generateInstructions(List<String> ingredients, String cuisine, String mealType) {
    List<String> instructions = [];
    instructions.add('Prepare all ingredients by washing, chopping, and measuring as needed.');
    if (cuisine.toLowerCase().contains('italian')) {
      instructions.add('Heat olive oil in a large pan over medium heat.');
      instructions.add('Sauté garlic and onions until fragrant and translucent.');
    } else if (cuisine.toLowerCase().contains('chinese')) {
      instructions.add('Heat oil in a wok or large skillet over high heat.');
      instructions.add('Stir-fry ingredients quickly, starting with harder vegetables.');
    } else if (cuisine.toLowerCase().contains('indian')) {
      instructions.add('Heat oil in a heavy-bottomed pan and add whole spices.');
      instructions.add('Add onions and cook until golden brown.');
    } else {
      instructions.add('Heat oil in a large pan over medium-high heat.');
      instructions.add('Add onions and cook until softened.');
    }
    instructions.add('Add the main ingredients (${ingredients.take(2).join(', ')}) and cook according to their requirements.');
    instructions.add('Season with salt, pepper, and any additional spices to taste.');
    instructions.add('Cook until all ingredients are tender and flavors are well combined.');
    instructions.add('Adjust seasoning if needed and serve hot.');
    instructions.add('Garnish as desired and enjoy your homemade ${cuisine.toLowerCase()} ${mealType.toLowerCase()}!');
    return instructions;
  }

  Map<String, String> _generateNutritionalInfo(List<String> ingredients, int servings) {
    int baseCalories = 200;
    int baseProtein = 15;
    int baseCarbs = 20;
    int baseFat = 8;
    for (String ingredient in ingredients) {
      if (ingredient.toLowerCase().contains('chicken') ||
          ingredient.toLowerCase().contains('beef') ||
          ingredient.toLowerCase().contains('fish')) {
        baseCalories += 150;
        baseProtein += 20;
        baseFat += 5;
      } else if (ingredient.toLowerCase().contains('rice') ||
          ingredient.toLowerCase().contains('pasta') ||
          ingredient.toLowerCase().contains('potato')) {
        baseCalories += 100;
        baseCarbs += 25;
      } else if (ingredient.toLowerCase().contains('oil') ||
          ingredient.toLowerCase().contains('butter')) {
        baseCalories += 80;
        baseFat += 10;
      }
    }
    return {
      'calories': '${baseCalories ~/ servings} kcal per serving',
      'protein': '${baseProtein ~/ servings}g',
      'carbs': '${baseCarbs ~/ servings}g',
      'fat': '${baseFat ~/ servings}g',
      'fiber': '3-5g',
      'sodium': 'Varies by seasoning'
    };
  }

  List<String> _generateTips(String cuisine, String mealType) {
    List<String> tips = [
      'Always taste and adjust seasoning before serving',
      'Prep all ingredients before you start cooking for easier workflow',
      'Use fresh ingredients when possible for the best flavor',
    ];
    if (cuisine.toLowerCase().contains('italian')) {
      tips.add('Use good quality olive oil for authentic Italian flavor');
      tips.add('Don\'t overcook pasta - it should be al dente');
    } else if (cuisine.toLowerCase().contains('chinese')) {
      tips.add('Keep the heat high for proper stir-frying technique');
      tips.add('Have all ingredients ready before you start cooking');
    } else if (cuisine.toLowerCase().contains('indian')) {
      tips.add('Toast whole spices before grinding for maximum flavor');
      tips.add('Let the dish simmer to allow flavors to develop');
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
            title: Text(
              'AI Recipe Generator',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildProgressIndicator(isDark),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildMealTypePage(isDark),
                    _buildCuisinePage(isDark),
                    _buildIngredientsPage(isDark),
                    _buildRestrictionsPage(isDark),
                  ],
                ),
              ),
              _buildNavigationButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    int totalSteps = _totalInputSteps;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.grey[800] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'Step ${_currentPage + 1} of $totalSteps',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What ingredients do you have?',
      subtitle: 'List the main ingredients you want to use, separated by commas',
      child: _buildTextField(
        controller: _ingredientsController,
        hint: 'e.g., chicken, rice, onions, tomatoes',
        maxLines: 4,
        isDark: isDark,
      ),
    );
  }

  Widget _buildCuisinePage(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double totalHorizontalSpacing = 24.0 * 2;
    const double itemSpacing = 12.0;
    final itemWidth = (screenWidth - totalHorizontalSpacing - itemSpacing) / 2;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'What Cuisine Type?',
      subtitle: 'Select your preferred cuisine style.',
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.start,
        children: _displayCuisineOptions.map((cuisine) {
          return SizedBox(
            width: itemWidth,
            child: _buildSelectionCard(
              title: cuisine,
              isSelected: _selectedCuisine == cuisine,
              onTap: () {
                setState(() {
                  _selectedCuisine = cuisine;
                  _cuisineController.text = cuisine;
                });
              },
              isDark: isDark,
              icon: Icons.restaurant_menu,
              useCompactStyle: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealTypePage(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double totalHorizontalSpacing = 24.0 * 2;
    const double itemSpacing = 12.0;
    final itemWidth = (screenWidth - totalHorizontalSpacing - itemSpacing) / 2;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'What meal type?',
      subtitle: 'Choose the type of dish you want to make.',
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.start,
        children: _mealTypeOptions.map((mealType) {
          return SizedBox(
            width: itemWidth,
            child: _buildSelectionCard(
              title: mealType,
              isSelected: _selectedMealType == mealType,
              onTap: () {
                setState(() {
                  _selectedMealType = mealType;
                });
              },
              isDark: isDark,
              icon: Icons.dining,
              useCompactStyle: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRestrictionsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Any restrictions?',
      subtitle: 'Share any dietary restrictions or allergies (optional)',
      child: _buildTextField(
        controller: _restrictionsController,
        hint: 'e.g., vegetarian, gluten-free, nut allergy',
        maxLines: 3,
        isDark: isDark,
      ),
    );
  }

  Widget _buildQuestionPage({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required IconData icon,
    bool useCompactStyle = false,
  }) {
    Color selectedColor = isDark ? Colors.white : Colors.black;
    Color unselectedColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    Color selectedTextColor = isDark ? Colors.black : Colors.white;
    Color unselectedTextColor = isDark ? Colors.white : Colors.black;
    Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: selectedTextColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == _totalInputSteps - 1
                  ? (_isGenerating ? null : _generateRecipe)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isGenerating
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Generating...'),
                ],
              )
                  : Text(
                _currentPage == _totalInputSteps - 1 ? 'Generate Recipe' : 'Continue',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}