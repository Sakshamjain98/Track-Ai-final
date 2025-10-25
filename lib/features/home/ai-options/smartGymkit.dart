import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'package:trackai/features/home/ai-options/service/workout_planner_service.dart';

class Smartgymkit extends StatefulWidget {
  const Smartgymkit({super.key});

  @override
  State<Smartgymkit> createState() => _SmartgymkitState();
}

class _SmartgymkitState extends State<Smartgymkit> {
  final PageController _pageController = PageController();

  // Total Steps: 10 Input Steps + 1 Result Step = 11
  final int _totalInputSteps = 10;

  // State variables
  int _currentPage = 0;
  bool _isGenerating = false;
  Map<String, dynamic>? _results;
  bool _isSaving = false; // State for save button loading

  // Form Variables
  final TextEditingController _fitnessGoalsController = TextEditingController();
  String _selectedGender = '';
  final TextEditingController _weightController = TextEditingController();
  String _selectedWeightUnit = 'kg';
  final TextEditingController _heightController = TextEditingController();
  String _selectedHeightUnit = 'cm';
  String _selectedFitnessLevel = '';
  List<String> _selectedFocusAreas = ['full body'];
  String _selectedWorkoutType = 'Any (No Preference)';
  String _selectedWorkoutDuration = '';
  String _selectedPreferredTime = 'Any Time';
  String _selectedPlanDuration = '7 Days';

  // Options
  final List<String> _coreGoals = ['Muscle Gain', 'Weight Loss', 'Strength and Endurance', 'Keep Fit'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _weightUnits = ['kg', 'lb'];
  final List<String> _heightUnits = ['cm', 'ft'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _focusAreaOptions = ['full body', 'chest', 'back', 'legs', 'shoulders', 'arms', 'triceps', 'abs', 'glutes'];
  final List<String> _workoutTypes = ['Any (No Preference)', 'Gym Workout', 'Home Workout'];
  final List<String> _workoutDurations = ['30 minutes', '45 minutes', '60 minutes', '75 minutes', '90 minutes'];
  final List<String> _preferredTimes = ['Any Time', 'Morning', 'Afternoon', 'Evening'];
  final List<String> _planDurations = ['3 Days', '5 Days', '7 Days', '14 Days', '21 Days', '30 Days', '45 Days'];


  @override
  void dispose() {
    _pageController.dispose();
    _fitnessGoalsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
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

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: return _fitnessGoalsController.text.trim().isNotEmpty;
      case 1: return _selectedGender.isNotEmpty;
      case 2: return _weightController.text.trim().isNotEmpty;
      case 3: return _heightController.text.trim().isNotEmpty;
      case 4: return _selectedFitnessLevel.isNotEmpty;
      case 5: return _selectedFocusAreas.isNotEmpty;
      case 6: return _selectedWorkoutType.isNotEmpty;
      case 7: return _selectedWorkoutDuration.isNotEmpty;
      case 8: return _selectedPreferredTime.isNotEmpty; // Separated validation
      case 9: return _selectedPlanDuration.isNotEmpty; // New separate validation
      default: return true;
    }
  }

  Future<void> _generatePlan() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar();
      return;
    }
    setState(() => _isGenerating = true);
    _nextPage(); // Move to the results page

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

  // --- IMPLEMENTED: Save Plan Method ---
  Future<void> _savePlan() async {
    if (_results == null) return;

    setState(() => _isSaving = true);
    try {
      // Assuming WorkoutPlannerService has a method named `saveWorkoutPlan`
      // that takes the generated plan map. This will save the plan to the designated
      // location (e.g., Firebase) which is then displayed in the SavedPlansScreen.
      await WorkoutPlannerService.saveWorkoutPlan(_results!);
      _showSuccessSnackBar('Workout plan saved successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to save plan: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }
  // --- END IMPLEMENTED: Save Plan Method ---

  void _resetFlow() {
    setState(() {
      _currentPage = 0;
      _results = null;
      _fitnessGoalsController.clear();
      _selectedGender = '';
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark))),
        title: Text('AI Workout Planner', style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              if (_currentPage < _totalInputSteps)
                _buildProgressIndicator(isDark, _totalInputSteps),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildFitnessGoalsPage(isDark), // Step 1
                    _buildGenderPage(isDark), // Step 2
                    _buildWeightPage(isDark), // Step 3
                    _buildHeightPage(isDark), // Step 4
                    _buildFitnessLevelPage(isDark), // Step 5
                    _buildFocusAreasPage(isDark), // Step 6
                    _buildWorkoutTypePage(isDark), // Step 7
                    _buildWorkoutDurationPage(isDark), // Step 8
                    _buildPreferredTimePage(isDark), // Step 9 (New separate step)
                    _buildPlanDurationPage(isDark), // Step 10 (New separate step)
                    _buildWorkoutResultsPage(isDark), // Step 11 (Results)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _currentPage < _totalInputSteps
          ? _buildNavigationButtons(isDark)
          : null,
    );
  }
  Widget _buildNavigationButtons(bool isDark) {
    bool isLastInputStep = _currentPage == _totalInputSteps - 1;

    return Container(
      color: AppColors.background(isDark),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0) Expanded(child: OutlinedButton(onPressed: _previousPage, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: AppColors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: AppColors.white), child: Text('Previous', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 16)))),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isLastInputStep ? (_isGenerating ? null : _generatePlan) : _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isGenerating && isLastInputStep
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))), const SizedBox(width: 12), const Text('Generating...')])
                  : Text(isLastInputStep ? 'Generate Plan' : 'Next', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProgressIndicator(bool isDark, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage ? AppColors.black : AppColors.cardBackground(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text('Step ${_currentPage + 1} of $totalSteps', style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helper for step headers (Centered Icon/Text) - Removed "Step X of Y" from title
  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: AppColors.black),
        const SizedBox(height: 16),
        Text(
          title, // Title only
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Helper for selection card groups (centered)
  Widget _buildSelectionCardGroup({
    required String label,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String> onSelect,
    required bool isDark,
    bool isMultiSelect = false,
    List<String>? multiSelectedValues,
    ValueChanged<String>? onMultiSelect,
  }) {
    Color selectedColor = AppColors.black;
    Color unselectedColor = AppColors.cardBackground(isDark);
    Color selectedTextColor = AppColors.white;
    Color unselectedTextColor = AppColors.textPrimary(isDark);
    Color borderColor = AppColors.borderColor(isDark);

    // Conditional rendering based on option count
    final bool isVerticalLayout = options.length <= 4 && !isMultiSelect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(label, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        if (isVerticalLayout)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally in column
            children: options.map((option) => _buildSelectionCardItem(
              option: option,
              isSelected: option == selectedValue,
              onTap: () => onSelect(option),
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              selectedTextColor: selectedTextColor,
              unselectedTextColor: unselectedTextColor,
              borderColor: borderColor,
            )).toList(),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0,
            runSpacing: 12.0,
            children: options.map((option) {
              final isSelected = isMultiSelect ? (multiSelectedValues?.contains(option) ?? false) : option == selectedValue;
              return _buildSelectionCardItem(
                option: option,
                isSelected: isSelected,
                onTap: () {
                  if (isMultiSelect) {
                    onMultiSelect?.call(option);
                  } else {
                    onSelect(option);
                  }
                },
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                selectedTextColor: selectedTextColor,
                unselectedTextColor: unselectedTextColor,
                borderColor: borderColor,
                isWrap: true, // Indicates it's inside a Wrap
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSelectionCardItem({
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
    required Color selectedColor,
    required Color unselectedColor,
    required Color selectedTextColor,
    required Color unselectedTextColor,
    required Color borderColor,
    bool isWrap = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Add vertical margin for column layout
        margin: isWrap ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 6.0, horizontal: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          option,
          textAlign: isWrap ? TextAlign.left : TextAlign.center, // Center text when in column
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Helper for text input with unit selection (Weight/Height) - (Unchanged logic)
  Widget _buildUnitInput({
    required String label,
    required TextEditingController controller,
    required String selectedUnit,
    required List<String> unitOptions,
    required ValueChanged<String> onUnitSelect,
    required String placeholder,
    required bool isDark,
  }) {
    Color primaryColor = AppColors.textPrimary(isDark);
    Color secondaryColor = AppColors.textSecondary(isDark);
    Color cardColor = isDark ? AppColors.cardBackground(isDark) : AppColors.white;
    Color borderColor = AppColors.borderColor(isDark);
    Color hintColor = secondaryColor.withAlpha(153);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.black, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(color: primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildSelectionCardGroup(
                label: '',
                selectedValue: selectedUnit,
                options: unitOptions,
                onSelect: onUnitSelect,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- INPUT PAGES (10 STEPS) ---

  // Step 1: Fitness Goals
  Widget _buildFitnessGoalsPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: Icons.flag_outlined,
            title: 'Choose Your Goal',
            subtitle: 'Select your primary fitness objective to tailor your workout plan.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Select Your Primary Goal *',
            selectedValue: _fitnessGoalsController.text,
            options: _coreGoals,
            onSelect: (value) => setState(() {
              _fitnessGoalsController.text = value;
            }),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 2: Gender
  Widget _buildGenderPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: lucide.LucideIcons.user,
            title: 'Your Gender',
            subtitle: 'This helps the AI personalize exercises and calorie estimates.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Select Your Gender *',
            selectedValue: _selectedGender,
            options: _genders,
            onSelect: (value) => setState(() => _selectedGender = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 3: Weight
  Widget _buildWeightPage(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStepHeader(
              icon: lucide.LucideIcons.scale,
              title: 'Your Weight',
              subtitle: 'Enter your current body weight for accurate metrics.',
              isDark: isDark,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: isDark ? 2 : 4,
              color: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    Text(
                      'Current Weight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _weightController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 70',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedWeightUnit,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onChanged: (value) => setState(() => _selectedWeightUnit = value!),
                            items: _weightUnits
                                .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightPage(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildStepHeader(
              icon: lucide.LucideIcons.ruler,
              title: 'Your Height',
              subtitle: 'Enter your current height for accurate metrics.',
              isDark: isDark,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: isDark ? 2 : 4,
              color: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    Text(
                      'Current Height',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _heightController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 175',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedHeightUnit,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onChanged: (value) => setState(() => _selectedHeightUnit = value!),
                            items: _heightUnits
                                .map((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 5: Fitness Level
  Widget _buildFitnessLevelPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: Icons.trending_up,
            title: 'Fitness Level',
            subtitle: 'Select your current fitness experience level.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Current Fitness Level *',
            selectedValue: _selectedFitnessLevel,
            options: _fitnessLevels,
            onSelect: (value) => setState(() => _selectedFitnessLevel = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 6: Focus Areas
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: lucide.LucideIcons.target,
            title: 'Focus Area(s)',
            subtitle: 'Select the primary areas you wish to focus on.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Select Focus Area(s)',
            selectedValue: '',
            options: _focusAreaOptions.map((e) => e.toUpperCase()).toList(),
            onSelect: (_) {},
            isMultiSelect: true,
            multiSelectedValues: _selectedFocusAreas.map((e) => e.toUpperCase()).toList(),
            onMultiSelect: (value) => handleFocusAreaChange(value.toLowerCase()),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 7: Workout Type
  Widget _buildWorkoutTypePage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: lucide.LucideIcons.settings,
            title: 'Workout Type',
            subtitle: 'Choose your preferred environment and style.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Preferred Workout Type',
            selectedValue: _selectedWorkoutType,
            options: _workoutTypes,
            onSelect: (value) => setState(() => _selectedWorkoutType = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 8: Workout Duration
  Widget _buildWorkoutDurationPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: lucide.LucideIcons.timer,
            title: 'Workout Duration',
            subtitle: 'How long do you want each workout session to be?',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Duration per Workout (mins) *',
            selectedValue: _selectedWorkoutDuration,
            options: _workoutDurations,
            onSelect: (value) => setState(() => _selectedWorkoutDuration = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 9: Preferred Time (Separated)
  Widget _buildPreferredTimePage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: lucide.LucideIcons.sunMoon,
            title: 'Preferred Time',
            subtitle: 'When do you prefer to exercise?',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Preferred Time *',
            selectedValue: _selectedPreferredTime,
            options: _preferredTimes,
            onSelect: (value) => setState(() => _selectedPreferredTime = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Step 10: Plan Duration (Separated)
  Widget _buildPlanDurationPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: Icons.calendar_today_outlined,
            title: 'Plan Length',
            subtitle: 'Select the total duration for this workout plan.',
            isDark: isDark,
          ),
          _buildSelectionCardGroup(
            label: 'Plan Duration *',
            selectedValue: _selectedPlanDuration,
            options: _planDurations,
            onSelect: (value) => setState(() => _selectedPlanDuration = value),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- UPDATED: Result Page to include Save Button ---
  Widget _buildWorkoutResultsPage(bool isDark) {
    if (_isGenerating || _results == null) {
      return Center(child: SpinKitFadingCube(color: AppColors.black, size: 50.0));
    }
    final schedule = _results!['weeklySchedule'] as List?;
    final tips = _results!['generalTips'] as List?;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(lucide.LucideIcons.award, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text(_results!['planTitle'] ?? 'Your Workout Plan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark), )),
          const SizedBox(height: 8),
          Text(_results!['introduction'] ?? 'Your personalized plan is ready!', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5,)),
          const SizedBox(height: 32),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 150,
                // --- MODIFIED: Save Plan Button ---
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
                // --- END MODIFIED ---
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
    final bool isRestDay = (dayData['activity'] ?? '').toLowerCase().contains('rest');
    final exercises = dayData['details'] as List?;

    Color iconColor = isRestDay ? Colors.green : AppColors.black;
    Color tileColor = isDark ? AppColors.cardBackground(isDark) : AppColors.white;
    Color titleColor = AppColors.textPrimary(isDark);
    Color subtitleColor = AppColors.textSecondary(isDark);

    IconData leadingIcon = isRestDay ? lucide.LucideIcons.bed : lucide.LucideIcons.dumbbell;
    String subtitleText = isRestDay ? 'Recovery Day' : (dayData['activity'] ?? 'Full Workout');

    if(isRestDay && exercises != null && exercises.isNotEmpty){
      subtitleText = exercises.first['instruction'] ?? 'Active recovery advised.';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor(isDark), width: 1.0),
      ),
      color: tileColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          dayData['day'] ?? 'Unknown Day',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: subtitleColor,
            fontStyle: isRestDay ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        leading: Icon(leadingIcon, color: iconColor),
        children: <Widget>[
          Divider(height: 1, color: AppColors.borderColor(isDark)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isRestDay
                ?
            Text(
              'Ensure you focus on mobility, stretching, or light cardio to aid muscle recovery. Listen to your body!',
              style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
            )
                :
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Exercise Details:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      decoration: TextDecoration.underline
                  ),
                ),
                const SizedBox(height: 12),
                if (exercises != null && exercises.isNotEmpty)
                  ...exercises.map<Widget>((exercise) {
                    final instruction = exercise['instruction'] ?? 'No specific instructions provided.';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(
                              text: '${exercise['name'] ?? "Exercise"}: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                  fontSize: 16
                              ),
                            ),
                            TextSpan(
                              text: instruction,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                else
                  Text('No detailed exercises available for this session.', style: TextStyle(color: subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sharing logic removed as per previous request to replace with Save Plan
  Future<void> _shareWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    // Left empty since the button was replaced by Save Plan
  }

  void _showValidationSnackBar() {
    String message = '';
    switch (_currentPage) {
      case 0: message = 'Please select your fitness goal'; break;
      case 1: message = 'Please select your gender'; break;
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
  void _showSuccessSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.check_circle_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }
  void _showErrorSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }
}