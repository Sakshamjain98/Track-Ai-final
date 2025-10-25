import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';

// --- NEW IMPORTS ---
import 'dart:async';
// NOTE: Assuming this path is correct
import '../../settings/service/geminiservice.dart';
// If AppColors is not in core/constants, this might break. Assuming it is.
import 'package:trackai/core/constants/appcolors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class AIMealPlanner extends StatefulWidget {
  const AIMealPlanner({Key? key}) : super(key: key);

  @override
  State<AIMealPlanner> createState() => _AIMealPlannerState();
}

class _AIMealPlannerState extends State<AIMealPlanner> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

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

  String _selectedGender = '';
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedGoal = '';
  List<String> _selectedAllergies = [];
  String _selectedDays = '';
  String _selectedDietType = '';

  // --- OPTIONS ---
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _goalOptions = ['Weight Loss', 'Weight Gain', 'Maintenance'];
  final List<Map<String, String>> _allergyOptions = [
    {'id': 'gluten', 'label': 'Gluten'},
    {'id': 'dairy', 'label': 'Dairy'},
    {'id': 'nuts', 'label': 'Nuts'},
    {'id': 'eggs', 'label': 'Eggs'},
    {'id': 'soy', 'label': 'Soy'},
    {'id': 'seafood', 'label': 'Seafood'},
  ];
  final List<String> _dayOptions = ['3 Days', '5 Days', '7 Days', '14 Days', '30 Days'];
  final List<String> _dietOptions = [
    'Any / No Specific Diet',
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
    super.dispose();
  }

  void _showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
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
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
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

  // --- UPDATED VALIDATION ---
  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: // Age
      case 1: // Gender
      case 2: // Weight
      case 3: // Height
      case 4: // Goal
        return true; // Optional fields
      case 5: // Calories
        return _caloriesController.text.isNotEmpty;
      case 6: // Days
        return _selectedDays.isNotEmpty;
      case 7: // Diet Type
        return _selectedDietType.isNotEmpty;
      case 8: // Allergies
      case 9: // Health Conditions
      case 10: // Preferences
        return true; // Optional fields
      default:
        return true;
    }
  }

  // --- NEW: Dart implementation of the JS meal plan parser (FIXED CALORIE PARSING) ---
  Map<String, dynamic> _parseMealPlanString(String planString) {
    final Map<String, dynamic> parsedPlan = {};
    final lines = planString.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);

    String currentDayKey = '';
    Map<String, dynamic>? currentDayMeals;
    Map<String, dynamic>? currentMeal;

    final dayRegex = RegExp(r'^\*\*(Day\s*\d+.*)\*\*');
    // Regex captures the meal type (Group 1), the full calorie text (Group 2, e.g., "17 calories"), and the meal name (Group 3).
    final mealRegex = RegExp(r'^[\*-]\s*(Breakfast|Lunch|Dinner|Snacks)\s*(?:\((?:approx\.\s*)?([\d,.]+\s*kcal(?:ories)?)\))?[:\s-]*\s*(.*)', caseSensitive: false);
    final recipeLineRegex = RegExp(r'^\s*-\s*(Recipe|Instructions|Preparation)[:\s-]*\s*(.*)', caseSensitive: false);
    final simpleRecipeLineRegex = RegExp(r'^\s*-\s*(.*)');

    void saveCurrentMeal() {
      if (currentMeal != null && currentDayMeals != null) {
        String mealType = (currentMeal['type'] as String).toLowerCase();

        // --- FIX: Robust calorie extraction ---
        final String? rawCalString = currentMeal['calories'];
        int calories = 0;

        if (rawCalString != null) {
          // Use a regex to specifically find the first sequence of digits (\d+).
          // This ensures we extract '17' from '17 calories' without issues.
          final RegExp numRegex = RegExp(r'\d+');
          final Match? numMatch = numRegex.firstMatch(rawCalString);

          if (numMatch != null) {
            final String calNumString = numMatch.group(0)!; // group(0) is the entire match
            calories = int.tryParse(calNumString) ?? 0;
          }
        }
        // --- END FIX ---

        currentDayMeals[mealType] = {
          'name': currentMeal['name'],
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
          'calories': mealMatch.group(2)?.trim(),
          'name': mealMatch.group(3)!.trim(),
          'recipeLines': <String>[],
        };

        if (currentMeal['name'].isEmpty) {
          currentMeal['name'] = 'Meal';
        }
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
          currentMeal['recipeLines'].last = currentMeal['recipeLines'].last + ' $line';
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
      // The totalCalories calculation is now robust.
      day['totalCalories'] = total;
    }

    return parsedPlan;
  }

  // ---
  // --- UPDATED: _generateMealPlan (Calls GeminiService AND Parser)
  // ---
  Future<void> _generateMealPlan() async {
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
      final Map<String, dynamic> parsedDays = _parseMealPlanString(rawMealPlanString);

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
        'groceryList': ['Error: Could not generate list due to API or parsing failure.'],
        'cookingGuide': 'Error: Could not generate guide due to API or parsing failure.',
        'Day 1': { // Fallback structure
          'totalCalories': 0, // Fallback shows 0 calories
          'breakfast': {
            'name': 'Plan Generation Failed',
            'calories': 0,
            'recipe': 'The plan could not be generated or parsed successfully. Error: ${e.toString().replaceFirst("Exception: ", "")}'
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
  // --- END NEW: Save Plan Method ---


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
                    _buildAgePage(isDark),
                    _buildGenderPage(isDark),
                    _buildWeightPage(isDark),
                    _buildHeightPage(isDark),
                    _buildGoalPage(isDark),
                    _buildCaloriesPage(isDark),
                    _buildDaysPage(isDark),
                    _buildDietTypePage(isDark),
                    _buildAllergiesPage(isDark),
                    _buildHealthConditionsPage(isDark),
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
        children: [
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

  // --- Page Widgets (0-9, 12) ---

  // Page 0: Age (Optional)
  Widget _buildAgePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.cake_outlined,
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
      icon: Icons.person_outline,
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

  // Page 2: Weight (Optional)
  Widget _buildWeightPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.monitor_weight_outlined,
      title: 'Your current weight?',
      subtitle: 'Used to calculate your nutritional needs (optional)',
      child: Column(
        children: [
          _buildTextField(
            controller: _weightController,
            hint: 'e.g., 70',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
            isNumeric: true, // Allow decimal
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'kg', label: Text('kg')),
              ButtonSegment<String>(value: 'lb', label: Text('lbs')),
            ],
            selected: {_selectedWeightUnit},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedWeightUnit = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
              foregroundColor: isDark ? Colors.white : Colors.black,
              selectedBackgroundColor: isDark ? Colors.white : Colors.black,
              selectedForegroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Height (Optional)
  Widget _buildHeightPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.height_outlined,
      title: 'What\'s your height?',
      subtitle: 'Used to calculate your nutritional needs (optional)',
      child: Column(
        children: [
          _buildTextField(
            controller: _heightController,
            hint: 'e.g., 175',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
            isNumeric: true, // Allow decimal
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'cm', label: Text('cm')),
              ButtonSegment<String>(value: 'ft', label: Text('ft')),
            ],
            selected: {_selectedHeightUnit},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedHeightUnit = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
              foregroundColor: isDark ? Colors.white : Colors.black,
              selectedBackgroundColor: isDark ? Colors.white : Colors.black,
              selectedForegroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Goal (Optional)
  Widget _buildGoalPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.flag_outlined,
      title: 'Fitness goal?',
      subtitle: 'Select your primary fitness objective (optional)',
      child: Column(
        children: _goalOptions.map((goal) {
          IconData icon;
          switch (goal) {
            case 'Weight Loss':
              icon = Icons.trending_down;
              break;
            case 'Weight Gain':
              icon = Icons.trending_up;
              break;
            default:
              icon = Icons.sync;
          }
          return _buildSelectionCard(
            title: goal,
            isSelected: _selectedGoal == goal,
            onTap: () {
              setState(() {
                _selectedGoal = goal;
              });
            },
            isDark: isDark,
            icon: icon,
          );
        }).toList(),
      ),
    );
  }

  // Page 5: Calories (Required)
  Widget _buildCaloriesPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.local_fire_department_outlined,
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
      icon: Icons.calendar_month_outlined,
      title: 'Plan duration?',
      subtitle: 'How many days do you want your meal plan for?',
      child: Column(
        children: _dayOptions.map((days) {
          return _buildSelectionCard(
            title: days,
            isSelected: _selectedDays == days,
            onTap: () {
              setState(() {
                _selectedDays = days;
              });
            },
            isDark: isDark,
            icon: Icons.event,
          );
        }).toList(),
      ),
    );
  }

  // Page 7: Diet Type (Required)
  Widget _buildDietTypePage(bool isDark) {
    return _buildQuestionPage(
        isDark: isDark,
        icon: Icons.restaurant_menu,
        title: 'Diet preference?',
        subtitle: 'Choose your dietary preference or restriction',
        child: SingleChildScrollView(
        child: Column(
        children: _dietOptions.map((diet) {
      return _buildSelectionCard(
        title: diet,
        isSelected: _selectedDietType == diet,
        onTap: () {
          setState(() {
            _selectedDietType = diet;
          });
        },
        isDark: isDark,
        icon: Icons.eco,
      );
    }).toList(),
    ),
    ),
    );
    }

  // Page 8: Allergies (Optional)
  Widget _buildAllergiesPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.block,
      title: 'Any allergies?',
      subtitle: 'Select any allergies or intolerances (optional)',
      child: Column(
        children: [
          ..._allergyOptions.map((allergy) {
            final isSelected = _selectedAllergies.contains(allergy['label']!);
            return CheckboxListTile(
              title: Text(
                allergy['label']!,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      icon: Icons.health_and_safety_outlined,
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


  // ---
  // --- UPDATED: _buildResultsPage
  // ---
  Widget _buildResultsPage(bool isDark) {
    if (_mealPlan == null) {
      return Center(
        child: _isGenerating
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : Colors.black),
        )
            : Container(),
      );
    }

    final summary = _mealPlan!['planSummary'] as Map<String, dynamic>;
    final groceryList = _mealPlan!['groceryList'] as List<String>? ?? ['No grocery list generated.'];
    final cookingGuide = _mealPlan!['cookingGuide'] as String? ?? 'No cooking guide generated.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- 1. Header ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.restaurant,
              size: 40,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Meal Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personalized ${summary['totalDays']}-day meal plan is ready!',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // --- 2. Action Buttons (Save/New Plan) ---
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _savePlan, // Use new saving method
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                      : const Icon(lucide.LucideIcons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Plan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Reset logic (same as at the bottom)
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
                    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- 3. Plan Summary ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                  'Plan Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
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

          // --- 4. Daily Meal Plans (Collapsible) ---
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
            final bool isPlaceholder = dayMeals['breakfast']?['name'] == 'Plan Generation Failed';

            if (isPlaceholder) {
              // --- Fallback: Render the single raw string ---
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Plan Generation Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      dayMeals['breakfast']['recipe'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.red[200] : Colors.red[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- Success: Render collapsible day tile ---
            final int totalCalories = dayMeals['totalCalories'] as int? ?? 0; // Use robust total calories

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildExpansionTile(
                isDark: isDark,
                icon: Icons.calendar_today_outlined,
                title: dayName,
                // FIX: Use totalCalories (which is now robust)
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalCalories kcal',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: ['breakfast', 'lunch', 'dinner', 'snacks'].map((mealType) {
                        if (!dayMeals.containsKey(mealType)) {
                          return const SizedBox.shrink();
                        }
                        final meal = dayMeals[mealType] as Map<String, dynamic>;

                        return _buildMealCard(
                            isDark: isDark,
                            mealType: mealType,
                            meal: meal
                        );
                      }).toList(),
                    ),
                  )
                ],
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

  // --- SHARED WIDGETS (Unchanged) ---

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
              onPressed: _currentPage == _totalSteps - 1
                  ? (_isGenerating ? null : _generateMealPlan)
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

  // ---
  // --- NEW: Refactored Meal Card Widget
  // ---
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

  // ---
  // --- UPDATED: _buildExpansionTile (to accept a trailing widget)
  // ---
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
        shape: const Border(), // Remove default border
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
        trailing: trailing, // NEW
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      width: double.infinity,
      child: SelectableText(
        cookingGuide.trim(),
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}