import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class AIMealPlanner extends StatefulWidget {
  const AIMealPlanner({Key? key}) : super(key: key);

  @override
  State<AIMealPlanner> createState() => _AIMealPlannerState();
}

class _AIMealPlannerState extends State<AIMealPlanner> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _caloriesController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _healthConditionsController = TextEditingController();
  final _restrictionsController = TextEditingController();
  final _preferencesController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedDays = '';
  String _selectedDietType = '';
  String _selectedMealPrep = '';
  String _selectedBudget = '';
  bool _isGenerating = false;
  Map<String, dynamic>? _mealPlan;

  // Options
  final List<String> _dayOptions = ['3 Days', '5 Days', '7 Days', '14 Days', '30 Days'];
  final List<String> _dietOptions = [
    'Any / No Specific Diet',
    'Keto',
    'Paleo',
    'Vegan',
    'Vegetarian',
    'Mediterranean',
    'Low Carb',
    'Intermittent Fasting',
    'DASH Diet',
    'Whole30'
  ];
  final List<String> _mealPrepOptions = [
    'Quick & Easy (15-30 min)',
    'Medium Prep (30-45 min)',
    'Detailed Cooking (45+ min)',
    'Meal Prep Friendly'
  ];
  final List<String> _budgetOptions = [
    'Budget-Friendly',
    'Moderate Budget',
    'Premium Ingredients',
    'No Budget Constraints'
  ];

  @override
  void dispose() {
    _caloriesController.dispose();
    _cuisineController.dispose();
    _healthConditionsController.dispose();
    _restrictionsController.dispose();
    _preferencesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        // Enforcing red background with white text for errors as requested
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 5) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        String message = '';
        switch (_currentPage) {
          case 0:
            message = 'Please enter your daily calorie goal and plan duration.';
            break;
          case 1:
            message = 'Please select your preferred diet type.';
            break;
          case 2:
            message = 'Please select your meal preparation time and budget.';
            break;
          default:
            message = 'Please fill all required fields.';
        }
        _showValidationSnackBar(message);
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
        return _caloriesController.text.isNotEmpty && _selectedDays.isNotEmpty;
      case 1:
        return _selectedDietType.isNotEmpty;
      case 2:
        return _selectedMealPrep.isNotEmpty && _selectedBudget.isNotEmpty;
      case 3:
        return true; // Optional fields
      case 4:
        return true; // Optional fields
      default:
        return true;
    }
  }

  Future<void> _generateMealPlan() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar('Please fill all required fields before generating.');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 3));

      setState(() {
        _mealPlan = _createMealPlan();
        _isGenerating = false;
      });

      _nextPage();
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        // Keeping error snakcbar for generation error, not validation.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating meal plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _createMealPlan() {
    final numDays = int.parse(_selectedDays.split(' ')[0]);
    final targetCalories = int.parse(_caloriesController.text);

    Map<String, dynamic> plan = {};

    // Sample meal data based on diet type
    Map<String, List<Map<String, dynamic>>> mealDatabase = {
      'breakfast': [
        {'name': 'Oatmeal with Berries', 'calories': 350, 'recipe': 'Cook 1/2 cup oats with 1 cup almond milk. Top with mixed berries and honey.'},
        {'name': 'Greek Yogurt Parfait', 'calories': 320, 'recipe': 'Layer Greek yogurt with granola and fresh fruits.'},
        {'name': 'Avocado Toast', 'calories': 380, 'recipe': 'Toast whole grain bread, mash avocado with lime and salt.'},
        {'name': 'Smoothie Bowl', 'calories': 340, 'recipe': 'Blend banana, berries, spinach with almond milk. Top with nuts.'},
      ],
      'lunch': [
        {'name': 'Grilled Chicken Salad', 'calories': 520, 'recipe': 'Mixed greens with grilled chicken, vegetables, and olive oil dressing.'},
        {'name': 'Quinoa Buddha Bowl', 'calories': 480, 'recipe': 'Quinoa with roasted vegetables, chickpeas, and tahini dressing.'},
        {'name': 'Turkey Wrap', 'calories': 450, 'recipe': 'Whole wheat tortilla with turkey, hummus, and vegetables.'},
        {'name': 'Lentil Soup', 'calories': 420, 'recipe': 'Red lentils cooked with vegetables and spices. Serve with whole grain bread.'},
      ],
      'dinner': [
        {'name': 'Baked Salmon with Vegetables', 'calories': 680, 'recipe': 'Baked salmon fillet with roasted broccoli and sweet potato.'},
        {'name': 'Chicken Stir Fry', 'calories': 620, 'recipe': 'Stir-fried chicken with mixed vegetables and brown rice.'},
        {'name': 'Vegetarian Pasta', 'calories': 580, 'recipe': 'Whole wheat pasta with marinara sauce and mixed vegetables.'},
        {'name': 'Lean Beef with Quinoa', 'calories': 640, 'recipe': 'Grilled lean beef with quinoa and steamed vegetables.'},
      ],
      'snacks': [
        {'name': 'Mixed Nuts', 'calories': 200, 'recipe': 'A handful of mixed almonds, walnuts, and cashews.'},
        {'name': 'Apple with Peanut Butter', 'calories': 220, 'recipe': 'Sliced apple with 2 tbsp natural peanut butter.'},
        {'name': 'Greek Yogurt', 'calories': 150, 'recipe': 'Plain Greek yogurt with a drizzle of honey.'},
        {'name': 'Hummus with Vegetables', 'calories': 180, 'recipe': 'Hummus with carrot sticks, cucumber, and bell peppers.'},
      ],
    };

    // Generate meals for each day
    for (int i = 1; i <= numDays; i++) {
      Map<String, dynamic> dayMeals = {};
      int dailyCalories = 0;

      // Select meals for each meal type
      ['breakfast', 'lunch', 'dinner', 'snacks'].forEach((mealType) {
        final meals = mealDatabase[mealType]!;
        final selectedMeal = meals[i % meals.length];
        dayMeals[mealType] = selectedMeal;
        dailyCalories += selectedMeal['calories'] as int;
      });

      dayMeals['totalCalories'] = dailyCalories;
      plan['Day $i'] = dayMeals;
    }

    // Add plan summary
    plan['planSummary'] = {
      'totalDays': numDays,
      'avgDailyCalories': targetCalories,
      'totalCalories': numDays * targetCalories,
      'dietType': _selectedDietType,
      'generatedOn': DateTime.now().toString().split(' ')[0],
    };

    return plan;
  }

  // --- Black/White Theme Adjustments ---
  // Assuming a simplified color map for monochrome:
  // background is white, text/icons/accents are black, cards are light gray
  Color get _appBackground => Colors.white;
  Color get _primaryText => Colors.black;
  Color get _secondaryText => Colors.grey[700]!;
  Color get _cardBackground => Colors.grey[50]!;
  Color get _borderColor => Colors.grey[300]!;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Ignoring isDark for strict monochrome theme
        const bool isDark = false;

        return Scaffold(
          backgroundColor: _appBackground,
          appBar: AppBar(
            backgroundColor: _appBackground,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: _primaryText,
              ),
            ),
            title: Text(
              'AI Meal Planner',
              style: TextStyle(
                color: _primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(isDark),

              // Page Content
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
                    _buildBasicInfoPage(isDark),
                    _buildDietTypePage(isDark),
                    _buildPreferencesPage(isDark),
                    _buildHealthInfoPage(isDark),
                    _buildAdditionalPrefsPage(isDark),
                    _buildResultsPage(isDark),
                  ],
                ),
              ),

              // Navigation Buttons
              if (_currentPage < 5) _buildNavigationButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? _primaryText
                        : _cardBackground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentPage + 1} of 6',
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Meal Plan Basics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start by setting your daily calorie goal and plan duration.',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Daily Calorie Goal',
            controller: _caloriesController,
            hint: 'e.g., 2000',
            keyboardType: TextInputType.number,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Plan Duration',
            value: _selectedDays.isEmpty ? null : _selectedDays,
            items: _dayOptions,
            onChanged: (value) {
              setState(() {
                _selectedDays = value ?? '';
              });
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDietTypePage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.eco,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Diet Type',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your dietary preference or restriction.',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Diet Type',
            value: _selectedDietType.isEmpty ? null : _selectedDietType,
            items: _dietOptions,
            onChanged: (value) {
              setState(() {
                _selectedDietType = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Cooking Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your cooking time and budget preferences.',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Meal Preparation Time',
            value: _selectedMealPrep.isEmpty ? null : _selectedMealPrep,
            items: _mealPrepOptions,
            onChanged: (value) {
              setState(() {
                _selectedMealPrep = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
          ),

          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Budget Range',
            value: _selectedBudget.isEmpty ? null : _selectedBudget,
            items: _budgetOptions,
            onChanged: (value) {
              setState(() {
                _selectedBudget = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Health Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share any health conditions or dietary restrictions (optional).',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Health Conditions',
            controller: _healthConditionsController,
            hint: 'e.g., Diabetes, High blood pressure (optional)',
            maxLines: 2,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildTextField(
            label: 'Dietary Restrictions',
            controller: _restrictionsController,
            hint: 'e.g., Nut allergy, Lactose intolerant (optional)',
            maxLines: 2,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalPrefsPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.favorite,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Food Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your favorite cuisines and foods you prefer.',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Cuisine Preferences',
            controller: _cuisineController,
            hint: 'e.g., Italian, Asian, Mediterranean (optional)',
            maxLines: 2,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildTextField(
            label: 'Additional Preferences',
            controller: _preferencesController,
            hint: 'e.g., Love spicy food, prefer organic ingredients (optional)',
            maxLines: 3,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage(bool isDark) {
    if (_mealPlan == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    final summary = _mealPlan!['planSummary'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: _primaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Meal Plan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personalized ${summary['totalDays']}-day meal plan is ready!',
            style: TextStyle(
              fontSize: 16,
              color: _secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Plan Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryItem('Duration', '${summary['totalDays']} Days', isDark),
                _buildSummaryItem('Daily Calories', '${summary['avgDailyCalories']} kcal', isDark),
                _buildSummaryItem('Diet Type', summary['dietType'], isDark),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Meal Plans
          Text(
            'Daily Meal Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 16),

          ...(_mealPlan!.entries.where((entry) => entry.key.startsWith('Day')).map((entry) {
            final dayName = entry.key;
            final dayMeals = entry.value as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primaryText,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${dayMeals['totalCalories']} kcal',
                          style: TextStyle(
                            color: _appBackground,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...['breakfast', 'lunch', 'dinner', 'snacks'].map((mealType) {
                    if (!dayMeals.containsKey(mealType)) return const SizedBox.shrink();

                    final meal = dayMeals[mealType] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _appBackground, // Lighter card for nested item
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getMealIcon(mealType),
                                size: 16,
                                color: _primaryText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mealType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _secondaryText,
                                  ),
                                ),
                              ),
                              Text(
                                '${meal['calories']} kcal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meal['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal['recipe'],
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList()),

          const SizedBox(height: 32),

          // Create New Plan Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 0;
                  _mealPlan = null;
                  _caloriesController.clear();
                  _cuisineController.clear();
                  _healthConditionsController.clear();
                  _restrictionsController.clear();
                  _preferencesController.clear();
                  _selectedDays = '';
                  _selectedDietType = '';
                  _selectedMealPrep = '';
                  _selectedBudget = '';
                });
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryText,
                foregroundColor: _appBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: _appBackground),
                  const SizedBox(width: 8),
                  Text(
                    'Create New Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _appBackground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _primaryText),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _appBackground,
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: _primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          if (_currentPage > 0) const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 4
                  ? (_isGenerating ? null : _generateMealPlan)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryText,
                foregroundColor: _appBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(_appBackground),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Generating Plan...', style: TextStyle(color: _appBackground)),
                ],
              )
                  : Text(
                _currentPage == 4 ? 'Generate Plan' : 'Next',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: _appBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: _primaryText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _secondaryText),
            filled: true,
            fillColor: _cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryText, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
    bool isExpanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(color: _primaryText),
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: isExpanded,
          decoration: InputDecoration(
            filled: true,
            fillColor: _cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryText, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: _cardBackground,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }
}