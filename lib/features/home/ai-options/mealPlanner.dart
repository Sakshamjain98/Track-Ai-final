import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';

// --- NEW IMPORTS ---
import 'dart:async';
// NOTE: Assuming this path is correct
import '../../settings/service/geminiservice.dart';
// If AppColors is not in core/constants, this might break. Assuming it is.
import 'package:trackai/core/constants/appcolors.dart';

class AIMealPlanner extends StatefulWidget {
  const AIMealPlanner({Key? key}) : super(key: key);

  @override
  State<AIMealPlanner> createState() => _AIMealPlannerState();
}

class _AIMealPlannerState extends State<AIMealPlanner> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  // --- CONTROLLERS ---
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _otherAllergiesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _healthConditionsController = TextEditingController();
  final _preferencesController = TextEditingController();

  // --- STATE VARIABLES ---
  int _currentPage = 0;
  bool _isGenerating = false;
  bool _isSaving = false; // NEW: State for save button
  Map<String, dynamic>? _mealPlan;
  final List<String> _heightUnits = ['cm', 'ft/in'];
  final List<String> _weightUnits = ['kg', 'lb']; // FIX: Ensure this is correctly defined here
  String _selectedGender = '';
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedGoal = '';
  List<String> _selectedAllergies = [];
  String _selectedDays = '';
  String _selectedDietType = '';

  // --- OPTIONS ---
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _goalOptions = [
    'Weight Loss',
    'Weight Gain',
    'Maintenance'
  ];
  final List<Map<String, String>> _allergyOptions = [
    {'id': 'gluten', 'label': 'Gluten'},
    {'id': 'dairy', 'label': 'Dairy'},
    {'id': 'nuts', 'label': 'Nuts'},
    {'id': 'eggs', 'label': 'Eggs'},
    {'id': 'soy', 'label': 'Soy'},
    {'id': 'seafood', 'label': 'Seafood'},
  ];
  final List<String> _dayOptions = [
    '3 Days',
    '5 Days',
    '7 Days',
    '14 Days',
    '30 Days'
  ];
  final List<String> _dietOptions = [
    'No Specific Diet',
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Keto',
    'Paleo',
    'Gluten-Free',
    'Dairy-Free',
  ];

  // --- TOTAL STEPS UPDATED ---
  final int _totalSteps = 10;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _otherAllergiesController.dispose();
    _caloriesController.dispose();
    _cuisineController.dispose();
    _healthConditionsController.dispose();
    _preferencesController.dispose();
    _pageController.dispose();
    _feetController.dispose();
    _inchesController.dispose();

    _pageController.dispose();
    super.dispose();
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
                Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
                Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalSteps) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        String message = _getValidationMessage();
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

  // --- UPDATED VALIDATION MESSAGE ---
  String _getValidationMessage() {
    switch (_currentPage) {
      case 5: // Calories
        return 'Please enter your target daily calorie goal';
      case 6: // Days
        return 'Please select the plan duration';
      case 7: // Diet Type
        return 'Please select your diet type';
      default:
        return 'Please complete this field';
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Gender
        return _selectedGender.isNotEmpty;

      case 1: // Age
      // Check for valid positive integer
        return _ageController.text.isNotEmpty && int.tryParse(_ageController.text) != null && int.parse(_ageController.text) > 0;

      case 2: // Weight
        final weightValue = double.tryParse(_weightController.text);
        // Check if value is valid (not null and greater than zero)
        return weightValue != null && weightValue > 0;

      case 3: // Height (Fixed Logic)
        if (_selectedHeightUnit.isEmpty) return false;

        if (_selectedHeightUnit == 'cm') {
          final heightCmValue = double.tryParse(_heightController.text);
          // Check if value is valid (not null and greater than zero)
          return heightCmValue != null && heightCmValue > 0;

        } else if (_selectedHeightUnit == 'ft/in') {
          final feet = int.tryParse(_feetController.text);
          final inches = double.tryParse(_inchesController.text);

          // Feet must be non-negative integer. Inches must be non-negative and less than 12.
          // We only require feet to be positive if inches is zero, otherwise any non-negative combination is fine.
          final bool areFeetValid = feet != null && feet >= 0;
          final bool areInchesValid = inches != null && inches >= 0 && inches < 12;

          // Ensure at least one value is positive to prevent 0ft 0in
          final bool isNonZero = (feet ?? 0) > 0 || (inches ?? 0) > 0;

          return areFeetValid && areInchesValid && isNonZero;
        }
        return false; // Should not be reached if unit is selected

      case 4: // Goal
        return _selectedGoal.isNotEmpty;

      case 5: // Calories
      // Check for valid positive integer
        return _caloriesController.text.isNotEmpty && int.tryParse(_caloriesController.text) != null && int.parse(_caloriesController.text) > 0;

      case 6: // Days
        return _selectedDays.isNotEmpty;

      case 7: // Diet Type
        return _selectedDietType.isNotEmpty;

      case 8: // Allergies (Always true as selection is optional, text input is optional)
      case 9: // Health Conditions (Always true as input is optional)
        return true;

      default:
        return true;
    }
  }

  // --- FIXED: Improved meal plan parser with better calorie extraction ---
  Map<String, dynamic> _parseMealPlanString(String planString) {
    final Map<String, dynamic> parsedPlan = {};
    final lines = planString.split('\n').map((l) => l.trim()).where((l) =>
    l.isNotEmpty);

    String currentDayKey = '';
    Map<String, dynamic>? currentDayMeals;
    Map<String, dynamic>? currentMeal;

    final dayRegex = RegExp(r'^\*\*(Day\s*\d+.*)\*\*');
    // Updated regex to capture meal type only
    final mealRegex = RegExp(
        r'^[\*-]\s*(Breakfast|Lunch|Dinner|Snacks)\s*[:\s-]*\s*(.*)',
        caseSensitive: false);
    final recipeLineRegex = RegExp(
        r'^\s*-\s*(Recipe|Instructions|Preparation)[:\s-]*\s*(.*)',
        caseSensitive: false);
    final simpleRecipeLineRegex = RegExp(r'^\s*-\s*(.*)');

    void saveCurrentMeal() {
      if (currentMeal != null && currentDayMeals != null) {
        String mealType = (currentMeal['type'] as String).toLowerCase();

        // --- EXTRACT CALORIES FROM MEAL NAME ---
        String mealName = currentMeal['name'];
        int calories = 0;

        // Look for calorie patterns in the meal name
        final caloriePattern = RegExp(
            r'\(approx\.\s*(\d+)\s*calories?\)', caseSensitive: false);
        final match = caloriePattern.firstMatch(mealName);

        if (match != null) {
          calories = int.tryParse(match.group(1)!) ?? 0;
          // Remove the calorie part from the meal name for cleaner display
          mealName = mealName
              .replaceAll(match.group(0)!, '')
              .replaceAll(':', '')
              .trim();
        }

        // If no calories found, use reasonable defaults
        if (calories == 0) {
          switch (mealType) {
            case 'breakfast':
              calories = 400;
              break;
            case 'lunch':
              calories = 600;
              break;
            case 'dinner':
              calories = 800;
              break;
            case 'snacks':
              calories = 200;
              break;
            default:
              calories = 500;
          }
        }

        currentDayMeals[mealType] = {
          'name': mealName,
          'calories': calories,
          'recipe': currentMeal['recipeLines'].join('\n'),
        };
      }
    }

    for (final line in lines) {
      final dayMatch = dayRegex.firstMatch(line);
      if (dayMatch != null) {
        if (currentDayKey.isNotEmpty && currentDayMeals != null) {
          saveCurrentMeal();
          parsedPlan[currentDayKey] = currentDayMeals;
        }

        currentDayKey = dayMatch.group(1)!.trim();
        currentDayMeals = {};
        currentMeal = null;
        continue;
      }

      if (currentDayKey.isEmpty) continue;

      final mealMatch = mealRegex.firstMatch(line);
      if (mealMatch != null) {
        saveCurrentMeal();

        currentMeal = {
          'type': mealMatch.group(1)!.trim(),
          'name': mealMatch.group(2)?.trim() ?? 'Meal',
          'recipeLines': <String>[],
        };

        continue;
      }

      final recipeMatch = recipeLineRegex.firstMatch(line);
      if (currentMeal != null && recipeMatch != null) {
        currentMeal['recipeLines'].add(recipeMatch.group(2)!.trim());
        continue;
      }

      final simpleRecipeMatch = simpleRecipeLineRegex.firstMatch(line);
      if (currentMeal != null && simpleRecipeMatch != null) {
        currentMeal['recipeLines'].add(simpleRecipeMatch.group(1)!.trim());
        continue;
      }

      if (currentMeal != null) {
        if (currentMeal['recipeLines'].isNotEmpty) {
          currentMeal['recipeLines'].last =
              currentMeal['recipeLines'].last + ' $line';
        } else if (currentMeal['name'].isNotEmpty) {
          currentMeal['recipeLines'].add(line);
        }
      }
    }

    if (currentDayKey.isNotEmpty && currentDayMeals != null) {
      saveCurrentMeal();
      parsedPlan[currentDayKey] = currentDayMeals;
    }

    // Calculate total calories for the day
    for (var dayKey in parsedPlan.keys) {
      int total = 0;
      final day = parsedPlan[dayKey] as Map<String, dynamic>;
      day.forEach((mealType, mealData) {
        if (mealData is Map && mealData.containsKey('calories')) {
          total += (mealData['calories'] as int);
        }
      });
      day['totalCalories'] = total;
    }

    return parsedPlan;
  }

  void _debugMealPlanParsing(String rawPlanString) {
    print('=== RAW MEAL PLAN STRING ===');
    print(rawPlanString);
    print('=== END RAW STRING ===');

    final parsed = _parseMealPlanString(rawPlanString);
    print('=== PARSED RESULT ===');
    print(parsed);
    print('=== END PARSED RESULT ===');
  }

  // --- UPDATED: _generateMealPlan (Calls GeminiService AND Parser)
  Future<void> _generateMealPlan() async {
    _nextPage();

    setState(() {
      _isGenerating = true;
    });

    final Map<String, dynamic> userInput = {
      'age': _ageController.text,
      'gender': _selectedGender,
      'weight': _weightController.text,
      'weightUnit': _selectedWeightUnit,
      'height': _heightController.text,
      'heightUnit': _selectedHeightUnit,
      'goal': _selectedGoal,
      'allergies': _selectedAllergies,
      'otherAllergies': _otherAllergiesController.text,
      'healthConditions': _healthConditionsController.text,
      'calories': _caloriesController.text,
      'dietType': _selectedDietType,
      'days': _selectedDays,
      'mealPrep': '',
      'budget': '',
      'cuisine': _cuisineController.text,
      'preferences': _preferencesController.text,
    };

    try {
      // NOTE: Assuming this service method exists and returns the expected structure.
      final Map<String, dynamic> generatedPlan =
      await GeminiService.generateMealPlan(userInput: userInput)
          .timeout(const Duration(seconds: 60));

      final numDays = int.tryParse(_selectedDays.split(' ')[0]) ?? 7;
      final targetCalories = int.tryParse(_caloriesController.text) ?? 2000;

      final String rawMealPlanString = generatedPlan['mealPlan'] as String;
      _debugMealPlanParsing(rawMealPlanString);

      final Map<String, dynamic> parsedDays = _parseMealPlanString(
          rawMealPlanString);

      if (parsedDays.isEmpty) {
        throw Exception("AI plan structure could not be parsed.");
      }

      setState(() {
        _mealPlan = {
          'planSummary': {
            'totalDays': numDays,
            'avgDailyCalories': targetCalories,
            'dietType': _selectedDietType,
            'generatedOn': DateTime.now().toString().split(' ')[0],
          },
          'groceryList': generatedPlan['groceryList'] as List<String>,
          'cookingGuide': generatedPlan['cookingGuide'] as String,
        };

        _mealPlan!.addAll(parsedDays);
        _isGenerating = false;
      });

      _nextPage();
    } on TimeoutException {
      _handleGenerationError(TimeoutException('The AI request timed out.'));
    } catch (e) {
      _handleGenerationError(e);
    }
  }

  // --- NEW: Error handler to fallback to raw string display ---
  void _handleGenerationError(Object e) {
    final numDays = int.tryParse(_selectedDays.split(' ')[0]) ?? 7;
    final targetCalories = int.tryParse(_caloriesController.text) ?? 2000;

    setState(() {
      _isGenerating = false;
      _mealPlan = {
        'planSummary': {
          'totalDays': numDays,
          'avgDailyCalories': targetCalories,
          'dietType': _selectedDietType,
          'generatedOn': DateTime.now().toString().split(' ')[0],
        },
        'groceryList': [
          'Error: Could not generate list due to API or parsing failure.'
        ],
        'cookingGuide': 'Error: Could not generate guide due to API or parsing failure.',
        'Day 1': { // Fallback structure
          'totalCalories': 0, // Fallback shows 0 calories
          'breakfast': {
            'name': 'Plan Generation Failed',
            'calories': 0,
            'recipe': 'The plan could not be generated or parsed successfully. Error: ${e
                .toString()
                .replaceFirst("Exception: ", "")}'
          },
        }
      };
    });

    if (mounted) {
      _showErrorSnackBar(e.toString().replaceFirst("Exception: ", ""));
    }
    _nextPage();
  }

  // --- NEW: Save Plan Method ---
  Future<void> _savePlan() async {
    if (_mealPlan == null) return;

    setState(() => _isSaving = true);
    try {
      // NOTE: We'll add the plan type before saving to categorize it in Firestore/DB
      final planData = {
        ..._mealPlan!,
        'planCategory': 'meal', // Category for saving
        'planTitle': 'AI Meal Plan (${_mealPlan!['planSummary']['totalDays']} Days)'
      };

      // NOTE: Assuming this service method exists and handles saving
      await GeminiService.saveMealPlan(planData);
      _showSuccessSnackBar('Meal plan saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save plan: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
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
              'AI Meal Planner',
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
              if (_currentPage < _currentPage) _buildProgressIndicator(isDark), // <--- MODIFIED
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
                    _buildGenderPage(isDark),          // Index 0: Gender
                    _buildAgePage(isDark),             // Index 1: Age
                    _buildWeightPage(isDark),          // Index 2: Weight
                    _buildHeightPage(isDark),          // Index 3: Height
                    _buildGoalPage(isDark),            // Index 4: Goal
                    _buildCaloriesPage(isDark),        // Index 5: Calories (Required)
                    _buildDaysPage(isDark),            // Index 6: Days (Required)
                    _buildDietTypePage(isDark),        // Index 7: Diet Type (Required)
                    _buildAllergiesPage(isDark),       // Index 8: Allergies
                    _buildHealthConditionsPage(isDark), // Index 9: Health Conditions
                    _buildResultsPage(isDark),
                  ],
                ),
              ),
              if (_currentPage < _totalSteps) _buildNavigationButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentPage < _totalSteps)
            Row(
              children: List.generate(_totalSteps, (index) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
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
          if (_currentPage < _totalSteps)
            Text(
              'Step ${_currentPage + 1} of $_totalSteps',
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

  Widget _buildLoadingScreen(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color spinnerColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCube(
              color: spinnerColor,
              size: 50.0,
            ),
            const SizedBox(height: 31),
            Text(
              'Track AI is making your customized \n meal plan...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This may take a moment based on your selections.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
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
          const SizedBox(height: 8),
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

  // Builder for single select options (dynamic 1- or 2-column layout)
  Widget _buildDynamicSelection({
    required List<String> options,
    required String selectedValue,
    required Function(String) onSelect,
    required bool isDark,
    bool showIcons = true,
  }) {
    // Determine if we need 2-column layout (if options > 4)
    final useTwoColumnLayout = options.length > 4;

    // Calculate width for 2-column layout if needed
    final screenWidth = MediaQuery.of(context).size.width;
    const double totalHorizontalSpacing = 24.0 * 2;
    const double itemSpacing = 12.0;
    final itemWidth = (screenWidth - totalHorizontalSpacing - itemSpacing) / 2;

    if (useTwoColumnLayout) {
      return Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.start,
        children: options.map((option) {
          return SizedBox(
            width: itemWidth,
            child: _buildSelectionCard(
              title: option,
              isSelected: selectedValue == option,
              onTap: () => onSelect(option),
              isDark: isDark,
              icon: Icons.check, // Dummy icon for compilation
              useCompactStyle: true,
            ),
          );
        }).toList(),
      );
    } else {
      // 1-column layout (default)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((option) {
          IconData? icon;
          // Logic for Gender/Goal icons
          if (showIcons) {
            switch (option) {
              case 'Male': icon = Icons.male; break;
              case 'Female': icon = Icons.female; break;
              case 'Other': icon = Icons.transgender; break;
              case 'Weight Loss': icon = Icons.trending_down; break;
              case 'Weight Gain': icon = Icons.trending_up; break;
              case 'Maintenance': icon = Icons.sync; break;
              default: icon = Icons.check;
            }
          }
          return _buildSelectionCard(
            title: option,
            isSelected: selectedValue == option,
            onTap: () => onSelect(option),
            isDark: isDark,
            icon: icon,
            useCompactStyle: false,
          );
        }).toList(),
      );
    }
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon,
    bool useCompactStyle = false,
    bool isUnitSelector = false, // Added for Weight/Height Unit Pill Selector
  }) {
    Color selectedColor = isDark ? Colors.white : Colors.black;
    Color unselectedColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    Color selectedTextColor = isDark ? Colors.black : Colors.white;
    Color unselectedTextColor = isDark ? Colors.white : Colors.black;
    Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    // --- Special handling for the compact Unit Selector Pill ---
    if (isUnitSelector) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 55, // Fixed height for pill feel
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : Colors.transparent, // Only color the selected part
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // --- Standard 1-Col / 2-Col Selection Card ---
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: useCompactStyle ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        padding: useCompactStyle
            ? const EdgeInsets.symmetric(vertical: 16, horizontal: 10)
            : const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? selectedColor : borderColor,
              width: isSelected ? 2 : 1
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && !useCompactStyle)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(icon,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    size: 24
                ),
              ),
            Expanded(
              child: Text(title,
                  textAlign: useCompactStyle ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? selectedTextColor : unselectedTextColor
                  )),
            ),
            if (isSelected)
              Icon(useCompactStyle ? Icons.check : Icons.check_circle,
                  color: selectedTextColor,
                  size: useCompactStyle ? 18 : 22
              ),
          ],
        ),
      ),
    );
  }

  // --- Page Widgets (0-9, 12) ---

  // Page 0: Age (Optional)
  Widget _buildAgePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'How old are you?',
      subtitle: 'Your age helps in tailoring the meal plan (optional)',
      child: _buildTextField(
        controller: _ageController,
        hint: 'e.g., 30',
        keyboardType: TextInputType.number,
        isDark: isDark,
      ),
    );
  }

  // Page 1: Gender (Optional)
  Widget _buildGenderPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What\'s your gender?',
      subtitle: 'This provides more accurate recommendations (optional)',
      child: Column(
        children: _genderOptions.map((gender) {
          IconData icon;
          switch (gender) {
            case 'Male':
              icon = Icons.male;
              break;
            case 'Female':
              icon = Icons.female;
              break;
            default:
              icon = Icons.transgender;
          }
          return _buildSelectionCard(
            title: gender,
            isSelected: _selectedGender == gender,
            onTap: () {
              setState(() {
                _selectedGender = gender;
              });
            },
            isDark: isDark,
            icon: icon,
          );
        }).toList(),
      ),
    );
  }

  // Page 2: Weight (Unified Input)
  Widget _buildWeightPage(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your weight?',
      subtitle: 'Select your preferred unit and enter your weight.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight Unit Selector (Pill Style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: _weightUnits.map((option) =>
                  _buildSelectionCard(
                    title: option == 'kg' ? 'Kilograms (kg)' : 'Pounds (lb)',
                    isSelected: _selectedWeightUnit == option,
                    onTap: () => setState(() => _selectedWeightUnit = option),
                    isDark: isDark,
                    isUnitSelector: true, // Use the special unit pill style
                  )
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Weight Input Field
          _buildTextField(
            controller: _weightController,
            hint: 'Enter weight in $_selectedWeightUnit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
            isNumeric: true,
          ),
        ],
      ),
    );
  }

  // Page 3: Height (Unified Input UI)
  Widget _buildHeightPage(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your height?',
      subtitle: 'Used to calculate your nutritional needs (optional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Height Unit Selector (Pill Style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: _heightUnits.map((option) =>
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHeightUnit = option;
                          _heightController.clear();
                          _feetController.clear();
                          _inchesController.clear();
                        });
                      },
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedHeightUnit == option ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            option == 'cm' ? 'Centimeters (cm)' : 'Feet/Inches (ft/in)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedHeightUnit == option ? AppColors.white : primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Height Input Field(s) (Conditional)
          _selectedHeightUnit == 'cm'
              ? _buildTextField(
            controller: _heightController,
            hint: 'Enter height in cm',
            keyboardType: TextInputType.number,
            isDark: isDark,
            isNumeric: true,
          )
              : Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      controller: _feetController,
                      hint: 'Feet',
                      keyboardType: TextInputType.number,
                      isDark: isDark
                  )
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField(
                      controller: _inchesController,
                      hint: 'Inches',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      isDark: isDark
                  )
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 4: Goal (Optional)
  Widget _buildGoalPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Fitness goal?',
      subtitle: 'Select your primary fitness objective (optional)',
      child: _buildDynamicSelection( // <-- USE DYNAMIC SELECTION
        options: _goalOptions,
        selectedValue: _selectedGoal,
        onSelect: (val) => setState(() => _selectedGoal = val),
        isDark: isDark,
        showIcons: true,
      ),
    );
  }

  // Page 5: Calories (Required)
  Widget _buildCaloriesPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Daily calorie goal?',
      subtitle: 'Enter your target daily calorie intake for the meal plan',
      child: _buildTextField(
        controller: _caloriesController,
        hint: 'e.g., 2000',
        keyboardType: TextInputType.number,
        isDark: isDark,
      ),
    );
  }

  // Page 6: Days (Required)
  Widget _buildDaysPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Plan duration?',
      subtitle: 'How many days do you want your meal plan for?',
      child: _buildDynamicSelection( // <-- USE DYNAMIC SELECTION
        options: _dayOptions,
        selectedValue: _selectedDays,
        onSelect: (val) => setState(() => _selectedDays = val),
        isDark: isDark,
        showIcons: false,
      ),
    );
  }

  // Page 7: Diet Type (Required)
  Widget _buildDietTypePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Diet preference?',
      subtitle: 'Choose your dietary preference or restriction',
      child: _buildDynamicSelection( // <-- USE DYNAMIC SELECTION
        options: _dietOptions,
        selectedValue: _selectedDietType,
        onSelect: (val) => setState(() => _selectedDietType = val),
        isDark: isDark,
        showIcons: false,
      ),
    );
  }

  // Page 8: Allergies (Optional)
  Widget _buildAllergiesPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Any allergies?',
      subtitle: 'Select any allergies or intolerances (optional)',
      child: Column(
        children: [
          ..._allergyOptions.map((allergy) {
            final isSelected = _selectedAllergies.contains(allergy['label']!);
            return CheckboxListTile(
              title: Text(
                allergy['label']!,
                style: TextStyle(color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedAllergies.add(allergy['label']!);
                  } else {
                    _selectedAllergies.remove(allergy['label']!);
                  }
                });
              },
              activeColor: isDark ? Colors.white : Colors.black,
              checkColor: isDark ? Colors.black : Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              tileColor: isDark ? Colors.grey[900] : Colors.grey[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otherAllergiesController,
            hint: 'e.g., Shellfish, Peanuts',
            maxLines: 2,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Page 9: Health Conditions (Optional)
  Widget _buildHealthConditionsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Health conditions?',
      subtitle: 'Share any health conditions we should consider (optional)',
      child: _buildTextField(
        controller: _healthConditionsController,
        hint: 'e.g., Diabetes, High blood pressure',
        maxLines: 3,
        isDark: isDark,
      ),
    );
  }

  // --- UPDATED: _buildResultsPage
  Widget _buildResultsPage(bool isDark) {
    if (_isGenerating) {
      return _buildLoadingScreen(isDark);
    }
    if (_mealPlan == null) {
      return Center(
        child: _isGenerating
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : Colors.black),
        )
            : Container(),
      );
    }

    final summary = _mealPlan!['planSummary'] as Map<String, dynamic>;
    final groceryList = _mealPlan!['groceryList'] as List<String>? ??
        ['No grocery list generated.'];
    final cookingGuide = _mealPlan!['cookingGuide'] as String? ??
        'No cooking guide generated.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24,20,24,24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Header in Black Box ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black),
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Meal Plan',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your personalized ${summary['totalDays']}-day meal plan is ready!',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. Action Buttons (Save/New Plan) ---
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _savePlan,
                  icon: _isSaving
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                      : const Icon(lucide.LucideIcons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Plan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPage = 0;
                      _mealPlan = null;
                      _ageController.clear();
                      _weightController.clear();
                      _heightController.clear();
                      _otherAllergiesController.clear();
                      _caloriesController.clear();
                      _cuisineController.clear();
                      _healthConditionsController.clear();
                      _preferencesController.clear();
                      _selectedGender = '';
                      _selectedWeightUnit = 'kg';
                      _selectedHeightUnit = 'cm';
                      _selectedGoal = '';
                      _selectedAllergies = [];
                      _selectedDays = '';
                      _selectedDietType = '';
                    });
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- 3. Plan Summary with Black Border ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Plan Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryItem(
                    'Duration', '${summary['totalDays']} Days', isDark),
                _buildSummaryItem(
                    'Daily Calories', '${summary['avgDailyCalories']} kcal',
                    isDark),
                _buildSummaryItem('Diet Type', summary['dietType'], isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 4. Daily Meal Plans (Clickable Cards) ---
          Text(
            'Daily Meal Plans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...(_mealPlan!.entries
              .where((entry) => entry.key.startsWith('Day'))
              .map((entry) {
            final dayName = entry.key;
            final dayMeals = entry.value as Map<String, dynamic>;

            // Check for our fallback placeholder
            final bool isPlaceholder = dayMeals['breakfast']?['name'] ==
                'Plan Generation Failed';

            if (isPlaceholder) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Plan Generation Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      dayMeals['breakfast']['recipe'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- Success: Render clickable day card ---
            final int totalCalories = dayMeals['totalCalories'] as int? ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayDetailsPage(
                      dayData: {
                        'day': dayName,
                        'meals': dayMeals,
                        'totalCalories': totalCalories,
                      },
                      isDark: isDark,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      color: isDark ? Colors.white : Colors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCalories kcal',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),

          // --- 5. Grocery List ---
          _buildExpansionTile(
            isDark: isDark,
            icon: Icons.shopping_cart_outlined,
            title: 'Grocery List',
            children: [
              _buildGroceryList(groceryList, isDark),
            ],
          ),
          const SizedBox(height: 12),

          // --- 6. Cooking Guide ---
          _buildExpansionTile(
            isDark: isDark,
            icon: Icons.soup_kitchen_outlined,
            title: 'Cooking Guide',
            children: [
              _buildCookingGuide(cookingGuide, isDark),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- UPDATED: _buildNavigationButtons ---
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
                onPressed: _isGenerating ? null : _previousPage, // Disable during generation
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
              onPressed: _currentPage == _totalSteps - 1
                  ? (_isGenerating ? null : _generateMealPlan) // Disable if already generating
                  : (_isGenerating ? null : _nextPage), // Disable navigation during generation
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
                  Text(
                    'Generating...',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.black : Colors.white
                    ),
                  ),
                ],
              )
                  : Text(
                _currentPage == _totalSteps - 1 ? 'Generate Plan' : 'Continue',
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
    bool isNumeric = false,
  }) {
    List<TextInputFormatter> formatters = [];
    if (keyboardType == TextInputType.number) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }
    if (isNumeric) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')));
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      inputFormatters: formatters,
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

  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 15,
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
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      case 'snacks':
        return Icons.cake_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }

  Widget _buildMealCard({
    required bool isDark,
    required String mealType,
    required Map<String, dynamic> meal
  }) {
    final int calories = meal['calories'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMealIcon(mealType),
                size: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mealType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              // Display calories (which is now robust against 0 if parsed correctly)
              Text(
                '$calories kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal['name'],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            meal['recipe'],
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? trailing, // NEW
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: isDark ? Colors.white : Colors.black,
        collapsedIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
        shape: const Border(),
        // Remove default border
        title: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded( // NEW: Added Expanded
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        trailing: trailing,
        // NEW
        children: children,
      ),
    );
  }

  Widget _buildGroceryList(List<String> groceryList, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groceryList.map((item) {
          bool isHeader = item.startsWith('**') && item.endsWith('**');
          return Padding(
            padding: EdgeInsets.only(
              top: isHeader ? 12 : 6,
              left: isHeader ? 0 : 16,
            ),
            child: Text(
              isHeader ? item.replaceAll('**', '') : '• $item',
              style: TextStyle(
                color: isHeader
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
                fontSize: isHeader ? 16 : 14,
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
                height: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCookingGuide(String cookingGuide, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardBg = isDark ? Colors.grey[800] : Colors.grey[100];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chef\'s Tips for Meal Prep',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            cookingGuide.trim(),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// --- UPDATED: Simple Day Details Page with Black & White Theme ---
class DayDetailsPage extends StatelessWidget {
  final Map<String, dynamic> dayData;
  final bool isDark;

  const DayDetailsPage({Key? key, required this.dayData, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayName = dayData['day'] ?? 'Day';
    final dayMeals = dayData['meals'] as Map<String, dynamic>;
    final totalCalories = dayData['totalCalories'] as int? ?? 0;

    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          '',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Text(
              dayName,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Total calories : $totalCalories ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            // Meals List
            ...['breakfast', 'lunch', 'dinner', 'snacks'].map((mealType) {
              if (!dayMeals.containsKey(mealType)) {
                return const SizedBox.shrink();
              }
              final meal = dayMeals[mealType] as Map<String, dynamic>;
              final mealName = meal['name'] ?? 'Meal';
              final calories = meal['calories'] as int? ?? 0;
              final recipe = meal['recipe'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Type Header (outside the grey box)
                  Text(
                    mealType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20, // 2x bigger
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Grey Box with meal details
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal Name with Calories (with bullet point)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 40,
                                color: textColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '(approx. $calories calories): $mealName',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Recipe (with bullet point)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 40,
                                color: textColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Recipe: $recipe',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}