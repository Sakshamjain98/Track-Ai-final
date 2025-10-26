import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/workout_planner_service.dart';

class Smartgymkit extends StatefulWidget {
  const Smartgymkit({super.key});

  @override
  State<Smartgymkit> createState() => _SmartgymkitState();
}

class _SmartgymkitState extends State<Smartgymkit> {
  final PageController _pageController = PageController();

  final int _totalInputSteps = 10;

  int _currentPage = 0;
  bool _isGenerating = false;
  Map<String, dynamic>? _results;
  bool _isSaving = false;
  String _selectedHeightUnit = 'cm'; // ADDED
  final List<String> _heightUnits = ['cm', 'ft/in'];
  // Form Variables (State maintained)
  String _selectedGender = '';
  final TextEditingController _fitnessGoalsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedWeightUnit = 'kg';
  final TextEditingController _heightController = TextEditingController();
  String _selectedFitnessLevel = '';
  final _feetController = TextEditingController();   // ADDED
  final _inchesController = TextEditingController(); // ADDED
  List<String> _selectedFocusAreas = ['full body'];
  String _selectedWorkoutType = 'Any (No Preference)';
  String _selectedWorkoutDuration = '';
  String _selectedPreferredTime = 'Any Time';
  String _selectedPlanDuration = '7 Days';

  // Options (Retained)
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _coreGoals = ['Muscle Gain', 'Weight Loss', 'Strength and Endurance', 'Keep Fit'];
  final List<String> _weightUnits = ['kg', 'lb'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _focusAreaOptions = ['full body', 'chest', 'back', 'legs', 'shoulders', 'arms', 'triceps', 'glutes'];
  final List<String> _workoutTypes = ['Any (No Preference)', 'Gym Workout', 'Home Workout'];
  final List<String> _workoutDurations = ['15 minutes', '30 minutes', '45 minutes', '60 minutes', '75 minutes', '90 minutes'];
  final List<String> _preferredTimes = ['Any Time', 'Morning', 'Afternoon', 'Evening'];
  final List<String> _planDurations = ['3 Days', '5 Days', '7 Days', '14 Days', '21 Days', '30 Days'];


  @override
  void dispose() {
    _pageController.dispose();
    _fitnessGoalsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalInputSteps) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showValidationSnackBar();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

// --- Inside _SmartgymkitState class ---

  bool _validateCurrentPage() {
    String errorMessage = ''; // Define errorMessage locally

    switch (_currentPage) {
      case 0: return _selectedGender.isNotEmpty; // NEW Step 0: Gender
      case 1: return _fitnessGoalsController.text.trim().isNotEmpty; // NEW Step 1: Goals
      case 2: return _weightController.text.trim().isNotEmpty; // NEW Step 2: Weight

      case 3: // CORRECTED Step 3: Height
        if (_selectedHeightUnit.isEmpty) {
          errorMessage = 'Please select a height unit.';
        } else if (_selectedHeightUnit == 'cm') {
          if (_heightController.text.isEmpty ||
              double.tryParse(_heightController.text) == null ||
              double.parse(_heightController.text) <= 0) {
            errorMessage = 'Please enter a valid height in cm.';
          }
        } else if (_selectedHeightUnit != 'cm') { // Implies 'ft/in'
          final feet = int.tryParse(_feetController.text);
          final inches = double.tryParse(_inchesController.text);
          if (feet == null || feet < 0 || inches == null || inches < 0 || inches >= 12) {
            errorMessage = 'Please enter valid feet (>=0) and inches (0-11.9).';
          }
        }


        return true; // Return true only if all checks pass

      case 4: return _selectedFitnessLevel.isNotEmpty; // NEW Step 4: Fitness Level
      case 5: return _selectedFocusAreas.isNotEmpty; // NEW Step 5: Focus Areas
      case 6: return _selectedWorkoutType.isNotEmpty; // NEW Step 6: Workout Type
      case 7: return _selectedWorkoutDuration.isNotEmpty; // NEW Step 7: Duration
      case 8: return _selectedPreferredTime.isNotEmpty; // NEW Step 8: Preferred Time
      case 9: return _selectedPlanDuration.isNotEmpty; // NEW Step 9: Plan Duration
      default: return true;
    }
  }

  Future<void> _generatePlan() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar();
      return;
    }
    setState(() => _isGenerating = true);
    _nextPage();

    try {
      final duration = int.tryParse(_selectedWorkoutDuration.split(' ').first);

      double? weightValue = double.tryParse(_weightController.text.trim());
      if (_selectedWeightUnit == 'lb' && weightValue != null) {
        weightValue = weightValue * 0.453592;
      }

      double? heightValue = double.tryParse(_heightController.text.trim());
      if (_selectedHeightUnit == 'ft' && heightValue != null) {
        heightValue = heightValue * 30.48;
      }

      String workoutTypeKey = _selectedWorkoutType == 'Any (No Preference)' ? 'any' : _selectedWorkoutType.toLowerCase().split(' ').first;
      String preferredTimeKey = _selectedPreferredTime == 'Any Time' ? 'any' : _selectedPreferredTime.toLowerCase();
      final planDurationDays = int.tryParse(_selectedPlanDuration.split(' ').first);

      final workoutPlan = await WorkoutPlannerService.generateWorkoutPlan(
        fitnessGoals: _fitnessGoalsController.text,
        fitnessLevel: _selectedFitnessLevel.toLowerCase(),
        durationPerWorkout: duration,
        workoutType: workoutTypeKey,
        preferredTime: preferredTimeKey,
        planDuration: planDurationDays?.toString(),
        gender: _selectedGender.toLowerCase(),
        weight: weightValue != null ? weightValue.toStringAsFixed(1) : null,
        height: heightValue != null ? heightValue.toStringAsFixed(1) : null,
        focusAreas: _selectedFocusAreas,
      );

      if (workoutPlan != null) {
        setState(() => _results = workoutPlan);
        _showSuccessSnackBar('Workout plan generated successfully!');
      } else {
        throw Exception('Failed to generate plan.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      _previousPage();
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _savePlan() async {
    if (_results == null) return;

    setState(() => _isSaving = true);
    try {
      await WorkoutPlannerService.saveWorkoutPlan(_results!);
      _showSuccessSnackBar('Workout plan saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save plan: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetFlow() {
    setState(() {
      _currentPage = 0;
      _results = null;
      _selectedGender = '';
      _fitnessGoalsController.clear();
      _weightController.clear();
      _selectedWeightUnit = 'kg';
      _heightController.clear();
      _selectedHeightUnit = 'cm';
      _selectedFitnessLevel = '';
      _selectedFocusAreas = ['full body'];
      _selectedWorkoutType = 'Any (No Preference)';
      _selectedWorkoutDuration = '';
      _selectedPreferredTime = 'Any Time';
      _selectedPlanDuration = '7 Days';
    });
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider is read here
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary(isDark), size: 20)
        ),
        title: Text('AI Workout Planner',
            style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              if (_currentPage < _totalInputSteps)
                _buildProgressIndicator(isDark, horizontalPadding),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    // --- REVISED PAGE ORDER ---
                    _buildGenderPage(isDark), // Step 0 (NEW START)
                    _buildFitnessGoalsPage(isDark), // Step 1
                    _buildWeightPage(isDark), // Step 2
                    _buildHeightPage(isDark), // Step 3
                    _buildFitnessLevelPage(isDark), // Step 4
                    _buildFocusAreasPage(isDark), // Step 5 (Pill Selector)
                    _buildWorkoutTypePage(isDark), // Step 6
                    _buildWorkoutDurationPage(isDark), // Step 7 (Pill Selector)
                    _buildPreferredTimePage(isDark), // Step 8
                    _buildPlanDurationPage(isDark), // Step 9
                    _buildWorkoutResultsPage(isDark), // Step 10 (Results)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // --- MISSING METHOD DEFINITION WAS HERE ---
      bottomNavigationBar: _currentPage < _totalInputSteps
          ? _buildNavigationButtons(isDark)
          : null,
    );
  }

  // =================================================================
  // METHOD DEFINITIONS (Including the missing _buildNavigationButtons)
  // =================================================================

  Widget _buildProgressIndicator(bool isDark, double horizontalPadding) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_totalInputSteps, (index) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index < _totalInputSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: index <= _currentPage ?
                  AppColors.black :
                  AppColors.cardBackground(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 10),
          Text('Step ${_currentPage + 1} of $_totalInputSteps',
              style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13
              )),
        ],
      ),
    );
  }

  // --- MISSING METHOD 1: Navigation Buttons ---
  Widget _buildNavigationButtons(bool isDark) {
    bool isLastInputStep = _currentPage == _totalInputSteps - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.background(isDark),
          border: Border(
              top: BorderSide(color: AppColors.borderColor(isDark))
          )
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
                          color: AppColors.borderColor(isDark)
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)
                      ),
                      foregroundColor: AppColors.textPrimary(isDark)
                  ),
                  child: Text('Back',
                      style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.w600,
                          fontSize: 16
                      )
                  )
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isLastInputStep ?
              (_isGenerating ? null : _generatePlan) : _nextPage,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                  )
              ),
              child: _isGenerating && isLastInputStep
                  ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white
                      )
                  )
              )
                  : Text(
                  isLastInputStep ? 'Generate Plan' : 'Continue',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Re-Defined Helper Methods for the Pages ---
  Widget _buildQuestionPage({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark)
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary(isDark)
              )),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon, // For Gender
  }) {
    Color selectedColor = AppColors.black;
    Color unselectedColor = AppColors.cardBackground(isDark);
    Color selectedTextColor = AppColors.white;
    Color unselectedTextColor = AppColors.textPrimary(isDark);
    Color borderColor = AppColors.borderColor(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? selectedColor : borderColor,
              width: isSelected ? 2 : 1
          ),
        ),
        child: Row(
          children: [
            if (icon != null) // Display icon if provided (e.g., Gender)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(icon,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
                    size: 24
                ),
              ),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? selectedTextColor : unselectedTextColor
                  )),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: selectedTextColor,
                  size: 22
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionGroup(
      List<String> options,
      String selectedValue,
      Function(String) onSelect,
      bool isDark
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((option) {
        IconData? icon;
        // Logic for Gender icons
        if (_genders.contains(option)) {
          switch (option) {
            case 'Male': icon = Icons.male; break;
            case 'Female': icon = Icons.female; break;
            default: icon = Icons.transgender;
          }
        }
        return _buildSelectionCard(
          title: option,
          isSelected: selectedValue == option,
          onTap: () => onSelect(option),
          isDark: isDark,
          icon: icon,
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
        filled: true,
        fillColor: AppColors.cardBackground(isDark),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: AppColors.borderColor(isDark)
            )
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: AppColors.black,
                width: 2
            )
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }


  // --- UPDATED INPUT PAGES ---

  // Step 0: Gender
  Widget _buildGenderPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What\'s your gender?',
      subtitle: 'This provides more accurate body composition recommendations.',
      child: _buildSelectionGroup(_genders, _selectedGender,
              (val) => setState(() => _selectedGender = val), isDark),
    );
  }

  // Step 1: Fitness Goals
  Widget _buildFitnessGoalsPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Choose Your Goal?',
      subtitle: 'Select your primary fitness objective.',
      child: _buildSelectionGroup(_coreGoals, _fitnessGoalsController.text,
              (val) => setState(() => _fitnessGoalsController.text = val), isDark),
    );
  }

  // Step 2: Weight
  Widget _buildWeightPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your weight?',
      subtitle: 'Select your preferred unit and enter your weight.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit Selector (Pill Style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: _weightUnits.map((option) =>
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedWeightUnit = option),
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedWeightUnit == option ? AppColors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            option == 'kg' ? 'Kilograms (kg)' : 'Pounds (lb)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedWeightUnit == option ? AppColors.white : AppColors.textPrimary(isDark),
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
          // Weight Input Field
          _buildTextField(
            controller: _weightController,
            hint: 'Enter weight in $_selectedWeightUnit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
// --- Inside _AIRecipeGeneratorState class ---

// Page 3: Height (Now Step 3, Index 2)
  Widget _buildHeightPage(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your height?',
      subtitle: 'Select your preferred unit and enter your height.',
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

  // Step 4: Fitness Level
  Widget _buildFitnessLevelPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Fitness level?',
      subtitle: 'Select your current fitness experience level.',
      child: _buildSelectionGroup(_fitnessLevels, _selectedFitnessLevel,
              (val) => setState(() => _selectedFitnessLevel = val), isDark),
    );
  }

  // Step 5: Focus Areas (2-column pill layout)
  Widget _buildFocusAreasPage(bool isDark) {
    void handleFocusAreaChange(String area) {
      setState(() {
        if (area == 'full body') {
          _selectedFocusAreas = ['full body'];
        } else {
          _selectedFocusAreas.remove('full body');
          if (_selectedFocusAreas.contains(area)) {
            _selectedFocusAreas.remove(area);
          } else {
            _selectedFocusAreas.add(area);
          }
          if (_selectedFocusAreas.isEmpty) {
            _selectedFocusAreas = ['full body'];
          }
        }
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 24.0;
    // Calculate item width based on the actual screen width minus padding
    final double itemWidth = (screenWidth - (horizontalPadding * 2) - 12.0) / 2.0;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'Focus Area(s)?',
      subtitle: 'Select the primary areas you wish to focus on.',
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: _focusAreaOptions.map((area) {
          final displayName = area.toUpperCase();
          final isSelected = _selectedFocusAreas.contains(area);

          return GestureDetector(
            onTap: () => handleFocusAreaChange(area),
            child: Container(
              width: itemWidth,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textPrimary(isDark),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Step 6: Workout Type
  Widget _buildWorkoutTypePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Workout type?',
      subtitle: 'Choose your preferred environment and style.',
      child: _buildSelectionGroup(_workoutTypes, _selectedWorkoutType,
              (val) => setState(() => _selectedWorkoutType = val), isDark),
    );
  }

  // Step 7: Workout Duration (2-column pill layout)
  Widget _buildWorkoutDurationPage(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 24.0;
    final itemWidth = (screenWidth - (horizontalPadding * 2) - 12.0) / 2.0;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'Workout duration?',
      subtitle: 'How long do you want each workout session to be?',
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: _workoutDurations.map((duration) {
          final isSelected = _selectedWorkoutDuration == duration;

          return GestureDetector(
            onTap: () => setState(() => _selectedWorkoutDuration = duration),
            child: Container(
              width: itemWidth,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  duration,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textPrimary(isDark),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Step 8: Preferred Time
  Widget _buildPreferredTimePage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Preferred time?',
      subtitle: 'When do you prefer to exercise?',
      child: _buildSelectionGroup(_preferredTimes, _selectedPreferredTime,
              (val) => setState(() => _selectedPreferredTime = val), isDark),
    );
  }

  /// --- Inside _SmartgymkitState class ---

// Step 9: Plan Duration (REVISED to 2-column pill layout)
  Widget _buildPlanDurationPage(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use a reliable fixed padding value (24.0) since the outer widget has padding applied.
    const double fixedHorizontalPadding = 24.0;

    // Calculate item width for two-column layout: (Screen width - 2*Padding - Spacing) / 2
    final double itemWidth = (screenWidth - (fixedHorizontalPadding * 2) - 12.0) / 2.0;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'Plan length?',
      subtitle: 'Select the total duration for this workout plan.',
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: _planDurations.map((duration) {
          final isSelected = _selectedPlanDuration == duration;

          return GestureDetector(
            onTap: () => setState(() => _selectedPlanDuration = duration),
            child: Container(
              width: itemWidth,
              height: 55,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  duration,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.textPrimary(isDark),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

// --- The rest of the file remains unchanged. ---
  // Remaining methods (Results Page and Helpers)
// --- Inside _SmartgymkitState class ---

// --- NEW Helper: Custom Loading Screen ---
  Widget _buildCustomLoadingScreen(bool isDark) {
    final Color primaryTextColor = AppColors.textPrimary(isDark);
    final Color secondaryTextColor = AppColors.textSecondary(isDark);
    final Color spinnerColor = AppColors.black; // Using black for visibility

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using SpinKit for a branded loading effect
          SpinKitFadingCube(color: spinnerColor, size: 50.0),
          const SizedBox(height: 32),
          Text(
            'Track AI is making your customized workout plan...',
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
    );
  }


// --- MODIFIED: Result Page to include Custom Loading Screen ---
  Widget _buildWorkoutResultsPage(bool isDark) {
    if (_isGenerating) {
      // Show the custom loading screen when the plan is generating
      return _buildCustomLoadingScreen(isDark);
    }

    if (_results == null) {
      // Should not happen if flow is correct, but handles a non-loading null state
      return Center(child: Text('Error loading results.', style: TextStyle(color: AppColors.textPrimary(isDark))));
    }

    // --- Display Results Content (Unchanged) ---
    final schedule = _results!['weeklySchedule'] as List?;
    final tips = _results!['generalTips'] as List?;

    return SingleChildScrollView(
      // ... (rest of the results display logic) ...
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(lucide.LucideIcons.award, size: 48, color: AppColors.black)),
          const SizedBox(height: 16),
          Center(child: Text(_results!['planTitle'] ?? 'Your Workout Plan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark), ))),
          const SizedBox(height: 8),
          Center(child: Text(_results!['introduction'] ?? 'Your personalized plan is ready!', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5,))),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _savePlan,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                      : const Icon(lucide.LucideIcons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Plan'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.borderColor(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppColors.textPrimary(isDark)
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  onPressed: _resetFlow,
                  icon: const Icon(lucide.LucideIcons.refreshCw),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Workout Schedule', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 16),
          if (schedule != null && schedule.isNotEmpty)
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final dayData = schedule[index];
                  return _buildCollapsibleDayTile(dayData, isDark);
                })
          else
            Text('No schedule provided.', style: TextStyle(color: AppColors.textSecondary(isDark))),
          const SizedBox(height: 32),
          Text('General Tips', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 16),
          if (tips != null && tips.isNotEmpty)
            ...tips.map((tip) => ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.green), title: Text(tip.toString(), style: TextStyle(color: AppColors.textSecondary(isDark)))))
          else
            Text('No tips provided.', style: TextStyle(color: AppColors.textSecondary(isDark)))
        ],
      ),
    );
  }

  Widget _buildCollapsibleDayTile(Map<String, dynamic> dayData, bool isDark) {
    final bool isRestDay = (dayData['activity'] ?? '').toLowerCase().contains('rest') || (dayData['details'] as List? ?? []).isEmpty;
    final exercises = dayData['details'] as List?;

    Color iconColor = isRestDay ? Colors.green : AppColors.black;
    Color tileColor = isDark ? AppColors.cardBackground(isDark) : AppColors.white;
    Color titleColor = AppColors.textPrimary(isDark);
    Color subtitleColor = AppColors.textSecondary(isDark);

    IconData leadingIcon = isRestDay ? lucide.LucideIcons.bed : lucide.LucideIcons.dumbbell;
    String subtitleText = isRestDay ? 'Recovery Day' : (dayData['activity'] ?? 'Full Workout');
    final duration = dayData['duration'] != null ? ' | ${dayData['duration']}' : '';
    subtitleText = '$subtitleText$duration';

    final bool isTappable = !isRestDay || (exercises?.isNotEmpty ?? false);

    void navigateToDayDetails() {
      if (isTappable) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayDetailsPage(dayData: dayData, isDark: isDark),
          ),
        );
      }
    }

    Widget content = isTappable
        ? Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(isDark), width: 1.0),
      ),
      child: ListTile(
        onTap: navigateToDayDetails,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          dayData['day'] ?? 'Unknown Day',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(color: subtitleColor, fontStyle: isRestDay ? FontStyle.italic : FontStyle.normal),
        ),
        leading: Icon(leadingIcon, color: iconColor),
        trailing: isTappable ? Icon(Icons.arrow_forward_ios, color: subtitleColor, size: 16) : null,
      ),
    )
        : Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor(isDark), width: 1.0),
      ),
      color: tileColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(dayData['day'] ?? 'Unknown Day', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
        subtitle: Text(subtitleText, style: TextStyle(color: subtitleColor, fontStyle: FontStyle.italic)),
        leading: Icon(leadingIcon, color: iconColor),
        children: <Widget>[
          Divider(height: 1, color: AppColors.borderColor(isDark)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ensure you focus on mobility, stretching, or light cardio to aid muscle recovery. Listen to your body!',
              style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
            ),
          ),
        ],
      ),
    );

    return content;
  }

  void _showValidationSnackBar() {
    String message = '';
    switch (_currentPage) {
      case 0: message = 'Please select your gender'; break;
      case 1: message = 'Please select your fitness goal'; break;
      case 2: message = 'Please enter your weight'; break;
      case 3: message = 'Please enter your height'; break;
      case 4: message = 'Please select your fitness level'; break;
      case 5: message = 'Please select your focus areas (or Full Body)'; break;
      case 6: message = 'Please select a workout type'; break;
      case 7: message = 'Please select the workout duration'; break;
      case 8: message = 'Please select the preferred time'; break;
      case 9: message = 'Please select the plan duration'; break;
      default: message = 'Please complete the form';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.check_circle_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }
}
class Exercise {
  final String name;
  final String instruction;

  Exercise({required this.name, required this.instruction});
}

// -------------------------------------------------------------------------
// New Page 1: Day Details (Shows list of exercises for a selected day)
// -------------------------------------------------------------------------

class DayDetailsPage extends StatelessWidget {
  final Map<String, dynamic> dayData;
  final bool isDark;

  const DayDetailsPage({Key? key, required this.dayData, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exercises = (dayData['details'] as List?)
        ?.map((e) => Exercise(name: e['name'] ?? 'N/A', instruction: e['instruction'] ?? ''))
        .toList() ??
        [];
    final dayName = dayData['day'] ?? 'Workout Day';
    final activity = dayData['activity'] ?? 'Details';

    final primaryColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          dayName.toUpperCase(),
          style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity,
              style: TextStyle(color: secondaryColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              '${exercises.length} exercises',
              style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (exercises.isNotEmpty)
              ...exercises.map((exercise) => _buildExerciseTile(context, exercise, isDark)).toList()
            else
              Center(
                child: Text('No detailed exercises available for this session.', style: TextStyle(color: secondaryColor)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(BuildContext context, Exercise exercise, bool isDark) {
    final primaryColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? AppColors.cardBackground(isDark) : Colors.white;

    // Get the first letter for the leading avatar
    final firstLetter = exercise.name.isNotEmpty ? exercise.name[0] : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          // Navigate to the Exercise Details Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailsPage(exercise: exercise, isDark: isDark),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(isDark), width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.black,
                child: Text(firstLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.instruction,
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
            ],
          ),
        ),
      ),
    );
  }
}
// -------------------------------------------------------------------------
// New Page 2: Exercise Details (Shows instructions, prep, execution)
// -------------------------------------------------------------------------

class ExerciseDetailsPage extends StatelessWidget {
  final Exercise exercise;
  final bool isDark;

  const ExerciseDetailsPage({Key? key, required this.exercise, required this.isDark}) : super(key: key);

  Widget _buildSection({
    required String title,
    required Widget content,
    required bool isDark,
  }) {
    final primaryColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(String text) {
    return Column(
      children: [
        // Placeholder for an icon/animation (like the animated dumbbells in the image)
        Icon(lucide.LucideIcons.dumbbell, size: 40, color: Colors.cyan),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? AppColors.cardBackground(isDark) : Colors.white;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          exercise.name,
          style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Section
            _buildSection(
              title: 'Instructions',
              isDark: isDark,
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor(isDark), width: 1),
                ),
                child: Text(
                  exercise.instruction,
                  style: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // Preparation Section (Placeholder)
            _buildSection(
              title: 'Preparation',
              isDark: isDark,
              content: _buildPlaceholderContent(
                'Detailed instructions, form tips, and video examples for this exercise are coming soon!',
              ),
            ),

            // Execution Section (Placeholder)
            _buildSection(
              title: 'Execution',
              isDark: isDark,
              content: _buildPlaceholderContent(
                'Detailed instructions, form tips, and video examples for this exercise are coming soon!',
              ),
            ),

            // Key Tips Section (Placeholder)
            _buildSection(
              title: 'Key Tips',
              isDark: isDark,
              content: _buildPlaceholderContent(
                'Detailed instructions, form tips, and video examples for this exercise are coming soon!',
              ),
            ),
          ],
        ),
      ),
    );
  }
}