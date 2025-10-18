import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/bulkingmacroservice.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'package:trackai/features/home/ai-options/service/workoutPlannerService.dart';
import 'package:trackai/features/onboarding/service/observices.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Smartgymkit extends StatefulWidget {
  const Smartgymkit({Key? key}) : super(key: key);

  @override
  State<Smartgymkit> createState() => _SmartgymkitState();
}

class _SmartgymkitState extends State<Smartgymkit> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  int _currentPage = 0;
  bool _isGenerating = false;
  Map<String, dynamic>? _results;

  // Workout Planner Variables
  final TextEditingController _fitnessGoalsController = TextEditingController();
  String _selectedFitnessLevel = '';
  String _selectedWorkoutType = '';
  String _selectedPlanDuration = '';

  // Options
  final List<String> _fitnessLevels = [
    'Beginner (0-6 months)',
    'Intermediate (6 months - 2 years)',
    'Advanced (2-5 years)',
    'Expert (5+ years)',
  ];

  final List<String> _workoutTypes = [
    'Any',
    'Home Workout',
    'Gym Workout',
    'Calisthenics',
    'Strength Training',
    'Cardio Focus',
    'Hybrid Training',
  ];

  final List<String> _planDurations = [
    '3 Days',
    '5 Days',
    '7 Days',
    '14 Days',
    '21 Days',
    '30 Days',
  ];

  final List<Map<String, String>> _fitnessGoals = [
    {'title': 'Lose weight and improve cardiovascular health', 'icon': '🏃‍♀️'},
    {'title': 'Build muscle and increase overall strength', 'icon': '💪'},
    {'title': 'Improve general fitness and endurance', 'icon': '🏃‍♂️'},
    {'title': 'Increase flexibility and mobility', 'icon': '🤸‍♀️'},
    {'title': 'Tone up and improve body composition', 'icon': '✨'},
    {'title': 'Prepare for a specific sport or event', 'icon': '🏆'},
    {'title': 'Reduce stress and improve mental well-being', 'icon': '🧘‍♀️'},
    {'title': 'Gain functional strength for daily activities', 'icon': '🏠'},
    {'title': 'Improve posture and core stability', 'icon': '🧍‍♀️'},
    {'title': 'Increase energy levels throughout the day', 'icon': '⚡'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fitnessGoalsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) { // Only 4 pages total (0, 1, 2, 3)
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showValidationSnackBar();
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
        return _fitnessGoalsController.text.trim().isNotEmpty;
      case 1:
        return _selectedFitnessLevel.isNotEmpty;
      case 2:
        return _selectedWorkoutType.isNotEmpty && _selectedPlanDuration.isNotEmpty;
      default:
        return true;
    }
  }

  void _showValidationSnackBar() {
    String message = '';
    switch (_currentPage) {
      case 0:
        message = 'Please describe your fitness goals to continue';
        break;
      case 1:
        message = 'Please select your current fitness level';
        break;
      case 2:
        if (_selectedWorkoutType.isEmpty && _selectedPlanDuration.isEmpty) {
          message = 'Please select workout type and plan duration';
        } else if (_selectedWorkoutType.isEmpty) {
          message = 'Please select your preferred workout type';
        } else if (_selectedPlanDuration.isEmpty) {
          message = 'Please select your plan duration';
        }
        break;
      default:
        message = 'Please fill all required fields';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_rounded,
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

  Future<void> _generatePlan() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar();
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate Workout Plan
      final workoutPlan = await WorkoutPlannerService.generateWorkoutPlan(
        fitnessGoals: _fitnessGoalsController.text,
        fitnessLevel: _selectedFitnessLevel,
        workoutType: _selectedWorkoutType,
        planDuration: _selectedPlanDuration,
        onboardingData: {},
      );

      if (workoutPlan != null) {
        setState(() {
          _results = workoutPlan;
          _isGenerating = false;
        });
        _showSuccessSnackBar('Workout plan generated successfully!');
        _nextPage();
      } else {
        setState(() {
          _isGenerating = false;
        });
        _showErrorSnackBar('Failed to generate workout plan. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        _showErrorSnackBar('Error generating plan: ${e.toString()}');
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _currentPage = 0;
      _results = null;
      _fitnessGoalsController.clear();
      _selectedFitnessLevel = '';
      _selectedWorkoutType = '';
      _selectedPlanDuration = '';
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            backgroundColor: AppColors.background(isDark),
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            title: Text(
              'AI Workout Planner',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
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
                    _buildFitnessGoalsPage(isDark),
                    _buildFitnessLevelPage(isDark),
                    _buildWorkoutPreferencesPage(isDark),
                    _buildWorkoutResultsPage(isDark),
                  ],
                ),
              ),

              // Navigation Buttons
              if (_results == null) _buildNavigationButtons(isDark),
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
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage
                        ? AppColors.black
                        : AppColors.cardBackground(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentPage + 1} of 4',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessGoalsPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Fitness Goals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe your specific fitness goals and what you want to achieve.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Fitness Goals *',
            controller: _fitnessGoalsController,
            hint: 'Describe your specific fitness goals, target areas, and what you want to achieve',
            maxLines: 4,
            isDark: isDark,
            isRequired: true,
          ),

          const SizedBox(height: 24),

          Text(
            'Popular Goals (tap to select)',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _fitnessGoals.length,
            itemBuilder: (context, index) {
              final goal = _fitnessGoals[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _fitnessGoalsController.text = goal['title']!;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _fitnessGoalsController.text == goal['title']
                        ? AppColors.black.withOpacity(0.1)
                        : AppColors.cardBackground(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _fitnessGoalsController.text == goal['title']
                          ? AppColors.black
                          : AppColors.borderColor(isDark),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(goal['icon']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          goal['title']!,
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 11,
                            fontWeight: _fitnessGoalsController.text == goal['title']
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessLevelPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Fitness Level',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your current fitness experience level.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Current Fitness Level *',
            value: _selectedFitnessLevel.isEmpty ? null : _selectedFitnessLevel,
            items: _fitnessLevels,
            onChanged: (value) {
              setState(() {
                _selectedFitnessLevel = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutPreferencesPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Workout Preferences',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred workout type and plan duration.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Workout Type *',
            value: _selectedWorkoutType.isEmpty ? null : _selectedWorkoutType,
            items: _workoutTypes,
            onChanged: (value) {
              setState(() {
                _selectedWorkoutType = value ?? '';
              });
            },
            isDark: isDark,
            isRequired: true,
          ),

          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Plan Duration *',
            value: _selectedPlanDuration.isEmpty ? null : _selectedPlanDuration,
            items: _planDurations,
            onChanged: (value) {
              setState(() {
                _selectedPlanDuration = value ?? '';
              });
            },
            isDark: isDark,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutResultsPage(bool isDark) {
    if (_results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Workout Plan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personalized AI-generated workout plan is ready!',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Plan Overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _results!['title'] ?? 'AI Generated Workout Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPlanDetail('Duration', _results!['duration'] ?? _selectedPlanDuration, isDark),
                _buildPlanDetail('Type', _results!['workoutType'] ?? _selectedWorkoutType, isDark),
                _buildPlanDetail('Level', _results!['fitnessLevel'] ?? _selectedFitnessLevel, isDark),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareWorkoutPlan(_results!),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Plan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _resetFlow,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.white,
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          if (_currentPage > 0) const SizedBox(width: 16),

          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 2
                  ? (_isGenerating ? null : _generatePlan)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Generating...'),
                ],
              )
                  : Text(
                _currentPage == 2 ? 'Generate Plan' : 'Next',
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
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && controller.text.isEmpty
                    ? Colors.red.withOpacity(0.5)
                    : AppColors.borderColor(isDark),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && controller.text.isEmpty
                    ? Colors.red.withOpacity(0.5)
                    : AppColors.borderColor(isDark),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.black, width: 2),
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
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
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
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          isExpanded: isExpanded,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && (value == null || value.isEmpty)
                    ? Colors.red.withOpacity(0.5)
                    : AppColors.borderColor(isDark),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isRequired && (value == null || value.isEmpty)
                    ? Colors.red.withOpacity(0.5)
                    : AppColors.borderColor(isDark),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.black, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          dropdownColor: AppColors.cardBackground(isDark),
        ),
      ],
    );
  }

  Widget _buildPlanDetail(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    try {
      final planText = WorkoutPlannerService.generateWorkoutPlanText(workoutPlan);
      final planTitle = workoutPlan['title'] ?? 'Workout Plan';
      await FileDownloadService.shareWorkoutPlan(planText, planTitle);
      _showSuccessSnackBar('Workout plan shared successfully!');
    } catch (e) {
      _showErrorSnackBar('Error sharing plan: ${e.toString()}');
    }
  }
}
