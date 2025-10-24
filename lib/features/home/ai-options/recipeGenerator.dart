import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

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
  final _servingsController = TextEditingController();
  final _timeController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedCuisine = '';
  String _selectedMealType = '';
  String _selectedDifficulty = '';
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedRecipe;

  // Options
  final List<String> _cuisineOptions = [
    'Any Cuisine',
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Mediterranean',
    'American',
    'Thai',
    'Japanese',
    'French',
    'Korean',
    'Greek',
    'Spanish',
    'Middle Eastern'
  ];

  final List<String> _mealTypeOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Appetizer',
    'Side Dish',
    'Soup'
  ];

  final List<String> _difficultyOptions = [
    'Easy (15-30 min)',
    'Medium (30-60 min)',
    'Hard (60+ min)',
    'Professional Level'
  ];

  @override
  void dispose() {
    _ingredientsController.dispose();
    _restrictionsController.dispose();
    _servingsController.dispose();
    _timeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 7) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
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
      case 0: // Ingredients
        return _ingredientsController.text.isNotEmpty;
      case 1: // Cuisine
        return _selectedCuisine.isNotEmpty;
      case 2: // Meal Type
        return _selectedMealType.isNotEmpty;
      case 3: // Difficulty
        return _selectedDifficulty.isNotEmpty;
      case 4: // Servings
        return _servingsController.text.isNotEmpty;
      case 5: // Cooking Time
        return true; // Optional
      case 6: // Restrictions
        return true; // Optional
      default:
        return true;
    }
  }

  Future<void> _generateRecipe() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _generatedRecipe = _createRecipe();
        _isGenerating = false;
      });

      _nextPage();
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

  Map<String, dynamic> _createRecipe() {
    final ingredients = _ingredientsController.text.split(',').map((e) => e.trim()).toList();
    final servings = int.tryParse(_servingsController.text) ?? 4;
    final cookingTime = _timeController.text.isNotEmpty ? _timeController.text : '30';

    String recipeName = _generateRecipeName(ingredients, _selectedCuisine, _selectedMealType);
    List<String> recipeIngredients = _generateRecipeIngredients(ingredients, servings);
    List<String> instructions = _generateInstructions(ingredients, _selectedCuisine, _selectedMealType);

    return {
      'name': recipeName,
      'description': 'A delicious ${_selectedCuisine.toLowerCase()} ${_selectedMealType.toLowerCase()} recipe made with ${ingredients.take(3).join(', ')}.',
      'prepTime': '${(int.tryParse(cookingTime) ?? 30) ~/ 3} minutes',
      'cookTime': '$cookingTime minutes',
      'totalTime': '${(int.tryParse(cookingTime) ?? 30) + ((int.tryParse(cookingTime) ?? 30) ~/ 3)} minutes',
      'servings': servings,
      'difficulty': _selectedDifficulty,
      'cuisine': _selectedCuisine,
      'mealType': _selectedMealType,
      'ingredients': recipeIngredients,
      'instructions': instructions,
      'nutritionalInfo': _generateNutritionalInfo(ingredients, servings),
      'tips': _generateTips(_selectedCuisine, _selectedMealType),
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

    if (cuisine == 'Italian') {
      instructions.add('Heat olive oil in a large pan over medium heat.');
      instructions.add('Sauté garlic and onions until fragrant and translucent.');
    } else if (cuisine == 'Chinese') {
      instructions.add('Heat oil in a wok or large skillet over high heat.');
      instructions.add('Stir-fry ingredients quickly, starting with harder vegetables.');
    } else if (cuisine == 'Indian') {
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

    if (cuisine == 'Italian') {
      tips.add('Use good quality olive oil for authentic Italian flavor');
      tips.add('Don\'t overcook pasta - it should be al dente');
    } else if (cuisine == 'Chinese') {
      tips.add('Keep the heat high for proper stir-frying technique');
      tips.add('Have all ingredients ready before you start cooking');
    } else if (cuisine == 'Indian') {
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
                    _buildIngredientsPage(isDark),
                    _buildCuisinePage(isDark),
                    _buildMealTypePage(isDark),
                    _buildDifficultyPage(isDark),
                    _buildServingsPage(isDark),
                    _buildTimePage(isDark),
                    _buildRestrictionsPage(isDark),
                    _buildResultsPage(isDark),
                  ],
                ),
              ),
              if (_currentPage < 7) _buildNavigationButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    int totalSteps = 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
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

  // Page 1: Ingredients
  Widget _buildIngredientsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.kitchen,
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

  // Page 2: Cuisine
  Widget _buildCuisinePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.public,
      title: 'Choose cuisine type',
      subtitle: 'Select your preferred cuisine style',
      child: SingleChildScrollView(
        child: Column(
          children: _cuisineOptions.map((cuisine) {
            return _buildSelectionCard(
              title: cuisine,
              isSelected: _selectedCuisine == cuisine,
              onTap: () {
                setState(() {
                  _selectedCuisine = cuisine;
                });
              },
              isDark: isDark,
              icon: Icons.restaurant_menu,
            );
          }).toList(),
        ),
      ),
    );
  }

  // Page 3: Meal Type
  Widget _buildMealTypePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.restaurant,
      title: 'What meal type?',
      subtitle: 'Choose the type of dish you want to make',
      child: Column(
        children: _mealTypeOptions.map((mealType) {
          return _buildSelectionCard(
            title: mealType,
            isSelected: _selectedMealType == mealType,
            onTap: () {
              setState(() {
                _selectedMealType = mealType;
              });
            },
            isDark: isDark,
            icon: Icons.dining,
          );
        }).toList(),
      ),
    );
  }

  // Page 4: Difficulty
  Widget _buildDifficultyPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.bar_chart,
      title: 'Cooking difficulty?',
      subtitle: 'Select the complexity level that suits your skill',
      child: Column(
        children: _difficultyOptions.map((difficulty) {
          return _buildSelectionCard(
            title: difficulty,
            isSelected: _selectedDifficulty == difficulty,
            onTap: () {
              setState(() {
                _selectedDifficulty = difficulty;
              });
            },
            isDark: isDark,
            icon: Icons.timeline,
          );
        }).toList(),
      ),
    );
  }

  // Page 5: Servings
  Widget _buildServingsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.people_outline,
      title: 'How many servings?',
      subtitle: 'Enter the number of people you want to serve',
      child: _buildTextField(
        controller: _servingsController,
        hint: 'e.g., 4',
        keyboardType: TextInputType.number,
        isDark: isDark,
      ),
    );
  }

  // Page 6: Cooking Time (Optional)
  Widget _buildTimePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.timer_outlined,
      title: 'Cooking time?',
      subtitle: 'How many minutes can you spend cooking? (optional)',
      child: _buildTextField(
        controller: _timeController,
        hint: 'e.g., 30',
        keyboardType: TextInputType.number,
        isDark: isDark,
      ),
    );
  }

  // Page 7: Restrictions (Optional)
  Widget _buildRestrictionsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.block,
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
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 40,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.grey[900] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? Colors.black : Colors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPage(bool isDark) {
    if (_generatedRecipe == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center
        ,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 40,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _generatedRecipe!['name'],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _generatedRecipe!['description'],
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Recipe Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Recipe Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Prep Time',
                        _generatedRecipe!['prepTime'],
                        Icons.schedule,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Cook Time',
                        _generatedRecipe!['cookTime'],
                        Icons.timer,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Servings',
                        '${_generatedRecipe!['servings']}',
                        Icons.people,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Difficulty',
                        _generatedRecipe!['difficulty'].split(' ')[0],
                        Icons.bar_chart,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ingredients Section
          Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...(_generatedRecipe!['ingredients'] as List<String>).map((ingredient) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Instructions Section
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...(_generatedRecipe!['instructions'] as List<String>).asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Nutritional Information
          Text(
            'Nutrition Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildNutritionChip(
                  'Calories: ${_generatedRecipe!['nutritionalInfo']['calories']}',
                  Icons.local_fire_department,
                  isDark,
                ),
                _buildNutritionChip(
                  'Protein: ${_generatedRecipe!['nutritionalInfo']['protein']}',
                  Icons.fitness_center,
                  isDark,
                ),
                _buildNutritionChip(
                  'Carbs: ${_generatedRecipe!['nutritionalInfo']['carbs']}',
                  Icons.grain,
                  isDark,
                ),
                _buildNutritionChip(
                  'Fat: ${_generatedRecipe!['nutritionalInfo']['fat']}',
                  Icons.water_drop,
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cooking Tips
          Text(
            'Cooking Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...(_generatedRecipe!['tips'] as List<String>).map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareRecipe(_generatedRecipe!),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.transparent,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPage = 0;
                      _generatedRecipe = null;
                      _ingredientsController.clear();
                      _restrictionsController.clear();
                      _servingsController.clear();
                      _timeController.clear();
                      _selectedCuisine = '';
                      _selectedMealType = '';
                      _selectedDifficulty = '';
                    });
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
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
              onPressed: _currentPage == 6
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
                _currentPage == 6 ? 'Generate Recipe' : 'Continue',
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

  Widget _buildDetailItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.white : Colors.black,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareRecipe(Map<String, dynamic> recipe) {
    final recipeText = '''
${recipe['name']}

${recipe['description']}

⏱️ Prep Time: ${recipe['prepTime']}
🍳 Cook Time: ${recipe['cookTime']}
👥 Serves: ${recipe['servings']}
📊 Difficulty: ${recipe['difficulty']}

🥘 INGREDIENTS:
${(recipe['ingredients'] as List<String>).map((ingredient) => '• $ingredient').join('\n')}

👨‍🍳 INSTRUCTIONS:
${(recipe['instructions'] as List<String>).asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}

💡 COOKING TIPS:
${(recipe['tips'] as List<String>).map((tip) => '• $tip').join('\n')}

📊 NUTRITION (per serving):
${(recipe['nutritionalInfo'] as Map<String, String>).entries.map((entry) => '${entry.key}: ${entry.value}').join('\n')}

Generated by TrackAI Recipe Generator 🤖
    ''';

    Clipboard.setData(ClipboardData(text: recipeText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
