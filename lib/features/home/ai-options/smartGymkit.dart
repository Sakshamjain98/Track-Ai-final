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

      // DEBUG: Print what's being sent to the AI
      print('DEBUG - Plan Duration Details:');
      print('Selected: $_selectedPlanDuration');
      print('Extracted days: $planDurationDays');
      print('Sending to AI: ${planDurationDays?.toString()}');

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

        // DEBUG: Check what was actually generated
        final schedule = workoutPlan['weeklySchedule'] as List?;
        print('DEBUG - Generated schedule length: ${schedule?.length}');
        print('DEBUG - Expected length: $planDurationDays');

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

// --- Display Results Content ---
    final schedule = _results!['weeklySchedule'] as List?;
    final tips = _results!['generalTips'] as List?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BLACK BANNER - Title above duration at bottom left
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title above duration
                Text(
                  _results!['planTitle']?.toString().toUpperCase() ?? 'YOUR WORKOUT PLAN',
                  style: const TextStyle(
                    fontSize: 18, // Reduced from 22
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0, // Reduced from 1.1
                  ),
                ),
                const SizedBox(height: 12),
                // Duration at bottom left in white pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedPlanDuration,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Responsive buttons
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
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
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
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
        ],
      ),
    );
  }
  Widget _buildCollapsibleDayTile(Map<String, dynamic> dayData, bool isDark) {
    final bool isRestDay = (dayData['activity'] ?? '').toLowerCase().contains('rest') || (dayData['details'] as List? ?? []).isEmpty;
    final exercises = dayData['details'] as List?;
    final exerciseCount = exercises?.length ?? 0;

    // Changed to grey background
    Color backgroundColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    // Removed border color

    String dayName = dayData['day'] ?? 'Day';
    String activity = dayData['activity'] ?? 'Workout';

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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        // Removed border property
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isTappable ? navigateToDayDetails : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day title - Big font
                Text(
                  dayName+":",
                  style: TextStyle(
                    fontSize: 18, // Big font
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black, // Dark color
                  ),
                ),

                const SizedBox(height: 4),

                // Exercise name and count in one line
                Row(
                  children: [
                    // Exercise name
                    Text(
                      isRestDay ? 'Rest Day' : activity,
                      style: TextStyle(
                        fontSize: 14, // Small font
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Vertical divider
                    Container(
                      width: 1,
                      height: 14,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),

                    const SizedBox(width: 8),

                    // Exercise count
                    Text(
                      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                      style: TextStyle(
                        fontSize: 14, // Small font
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),

                    const Spacer(),

                    // Arrow icon for tappable days
                    if (isTappable)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.white : Colors.black,
                        size: 16,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        title: const Text(''), // Empty app bar title

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Title and Dumbbell Icon in same row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.fitness_center,
                  color: primaryColor,
                  size: 80,
                ),
              ],
            ),
            const SizedBox(height: 2),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                activity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Exercise Count
            Text(
              '${exercises.length} ${exercises.length == 1 ? 'exercise' : 'exercises'}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Exercises List
            if (exercises.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildExerciseItem(
                  context,
                  exercises[index],
                  isDark,
                  primaryColor,
                  secondaryColor!,
                  cardColor!,
                ),
              )
            else
              Center(
                child: Text(
                    'No detailed exercises available for this session.',
                    style: TextStyle(color: secondaryColor)
                ),
              )
          ],
        ),
      ),
    );
  }
}

Widget _buildExerciseItem(
    BuildContext context,
    Exercise exercise,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
    Color cardColor,
    ) {
  // Get first letter for the avatar
  final firstLetter = exercise.name.isNotEmpty ? exercise.name[0].toUpperCase() : '?';

  return GestureDetector(
    onTap: () {
      // Navigate to Exercise Details Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseDetailsPage(exercise: exercise, isDark: isDark),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Black Rounded Square with first letter
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Exercise Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (exercise.instruction.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise.instruction,
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Chevron Icon
          Icon(
            Icons.chevron_right,
            color: secondaryColor,
            size: 20,
          ),
        ],
      ),
    ),
  );
}


// -------------------------------------------------------------------------
// Exercise Details Page
// -------------------------------------------------------------------------





// Placeholder for your Gemini Service (You MUST ensure your actual GeminiService
// class has the generateExercisePreparationTips method as discussed previously)
class GeminiService {
  static Future<List<String>> generateExercisePreparationTips({
    required String exerciseName,
    required String context,
  }) async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return mock data based on a simple name check
    if (exerciseName.toLowerCase().contains('squat')) {
      return [
        'Place the bar high across your upper back (traps) for stability.',
        'Set your feet slightly wider than shoulder-width, toes pointed slightly out.',
        'Take a deep breath and brace your core tightly before unracking the weight.',
        'Keep your chest up and look slightly down throughout the movement.',
      ];
    } else {
      return [
        'Ensure the bench or equipment is adjusted for your body height.',
        'Perform 1-2 sets of 10-15 light repetitions as a specific warm-up.',
        'Check that all weights/pins are securely fastened before starting.',
      ];
    }
  }
}

// ----------------------------------------------------------------------

class ExerciseDetailsPage extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;

  const ExerciseDetailsPage({Key? key, required this.exercise, required this.isDark}) : super(key: key);

  @override
  State<ExerciseDetailsPage> createState() => _ExerciseDetailsPageState();
}

class _ExerciseDetailsPageState extends State<ExerciseDetailsPage> {
  List<String> _preparationTips = ['Loading preparation tips...'];
  bool _isLoadingTips = true;
  String _tipError = '';

  @override
  void initState() {
    super.initState();
    _fetchPreparationTips();
  }

  Future<void> _fetchPreparationTips() async {
    setState(() {
      _isLoadingTips = true;
      _tipError = '';
    });
    try {
      final tips = await GeminiService.generateExercisePreparationTips(
        exerciseName: widget.exercise.name,
        context: widget.exercise.instruction,
      );

      setState(() {
        _preparationTips = tips.isNotEmpty
            ? tips
            : ['The AI did not generate specific preparation tips for this exercise.'];
      });
    } catch (e) {
      setState(() {
        _tipError = 'Failed to load tips: ${e.toString()}';
        _preparationTips = [];
      });
    } finally {
      setState(() {
        _isLoadingTips = false;
      });
    }
  }

  Widget _buildSection({
    required String title,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildNumberedItem(String text, int number) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? Colors.white : Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationContent() {
    if (_isLoadingTips) {
      return Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'Generating AI tips...',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (_tipError.isNotEmpty) {
      return Column(
        children: [
          Icon(Icons.error_outline,
              color: widget.isDark ? Colors.white : Colors.black,
              size: 28),
          const SizedBox(height: 8),
          Text(
            _tipError,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchPreparationTips,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isDark ? Colors.white : Colors.black,
              foregroundColor: widget.isDark ? Colors.black : Colors.white,
            ),
            child: Text('Retry', style: TextStyle(fontSize: 14)),
          ),
        ],
      );
    }

    // Show all preparation tips as paragraph only
    return Text(
      _preparationTips.join(' '),
      style: TextStyle(
        fontSize: 14,
        color: widget.isDark ? Colors.white : Colors.black,
        height: 1.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDark ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
            color: widget.isDark ? Colors.white : Colors.black),
        title: Text(
          widget.exercise.name,
          style: TextStyle(
            fontSize: 16,
            color: widget.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.exercise.name.isNotEmpty ? widget.exercise.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3 Sets x 3 reps',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Instructions Section with Grey Background
            _buildSection(
              title: 'Instructions',
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.exercise.instruction.isNotEmpty
                      ? widget.exercise.instruction
                      : 'No specific instructions available for this exercise.',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // Preparation Section - Now paragraph only
            _buildSection(
              title: 'Preparation',
              content: _buildPreparationContent(),
            ),

            // Execution Section - Only one point
            _buildSection(
              title: 'Execution',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedItem(
                    'Exhale on Exertion: Exhaling during the hard part (lifting/pushing) helps stabilize your core and generates more power.',
                    1,
                  ),
                  _buildNumberedItem(
                    'Inhale on Return: Inhaling during the easy part (lowering/returning to start) prepares your body for the next rep.Inhale on Return: Inhaling during the easy part (lowering/returning to start) prepares your body for the next rep.',
                    2,
                  ),
                ],
              ),
            ),

            // General Tips Section - Added back with three points
            _buildSection(
              title: 'General Tips',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberedItem(
                    'Warm-up before each workout with light cardio and dynamic stretching.',
                    1,
                  ),
                  _buildNumberedItem(
                    'Cool-down after each workout with static stretching, holding each stretch for 20-30 seconds.',
                    2,
                  ),
                  _buildNumberedItem(
                    'Stay hydrated by drinking plenty of water throughout the day and listen to your body.',
                    3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}