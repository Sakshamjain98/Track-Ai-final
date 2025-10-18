import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class CalorieBurnCalculator extends StatefulWidget {
  const CalorieBurnCalculator({Key? key}) : super(key: key);

  @override
  State<CalorieBurnCalculator> createState() => _CalorieBurnCalculatorState();
}

class _CalorieBurnCalculatorState extends State<CalorieBurnCalculator> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _customActivityController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedWeightUnit = 'kg';
  String _selectedActivity = '';
  String _selectedIntensity = '';
  bool _isCalculating = false;
  Map<String, dynamic>? _calculationResult;

  // Options
  final List<String> _weightUnits = ['kg', 'lbs'];
  final List<String> _activities = [
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Weight Lifting',
    'Yoga',
    'HIIT',
    'Dancing',
    'Rowing',
    'Hiking',
    'Basketball',
    'Football',
    'Tennis',
    'Jumping Rope',
    'Elliptical',
    'Stair Climbing',
    'Pilates',
    'Boxing',
    'Custom Activity'
  ];

  final List<String> _intensityLevels = [
    'Light (3-4 METs)',
    'Moderate (4-6 METs)',
    'Vigorous (6-8 METs)',
    'Very Vigorous (8+ METs)'
  ];

  // MET values for activities
  final Map<String, Map<String, double>> _metValues = {
    'Running': {
      'Light (3-4 METs)': 6.0,
      'Moderate (4-6 METs)': 8.0,
      'Vigorous (6-8 METs)': 11.0,
      'Very Vigorous (8+ METs)': 15.0,
    },
    'Walking': {
      'Light (3-4 METs)': 3.0,
      'Moderate (4-6 METs)': 4.0,
      'Vigorous (6-8 METs)': 5.0,
      'Very Vigorous (8+ METs)': 6.5,
    },
    'Cycling': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 6.8,
      'Vigorous (6-8 METs)': 10.0,
      'Very Vigorous (8+ METs)': 14.0,
    },
    'Swimming': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 6.0,
      'Vigorous (6-8 METs)': 8.0,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Weight Lifting': {
      'Light (3-4 METs)': 3.0,
      'Moderate (4-6 METs)': 5.0,
      'Vigorous (6-8 METs)': 6.0,
      'Very Vigorous (8+ METs)': 8.0,
    },
    'Yoga': {
      'Light (3-4 METs)': 2.5,
      'Moderate (4-6 METs)': 4.0,
      'Vigorous (6-8 METs)': 5.5,
      'Very Vigorous (8+ METs)': 7.0,
    },
    'HIIT': {
      'Light (3-4 METs)': 6.0,
      'Moderate (4-6 METs)': 8.0,
      'Vigorous (6-8 METs)': 10.0,
      'Very Vigorous (8+ METs)': 12.0,
    },
    'Dancing': {
      'Light (3-4 METs)': 3.0,
      'Moderate (4-6 METs)': 4.8,
      'Vigorous (6-8 METs)': 7.0,
      'Very Vigorous (8+ METs)': 8.5,
    },
    'Rowing': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 7.0,
      'Vigorous (6-8 METs)': 8.5,
      'Very Vigorous (8+ METs)': 12.0,
    },
    'Hiking': {
      'Light (3-4 METs)': 3.5,
      'Moderate (4-6 METs)': 6.0,
      'Vigorous (6-8 METs)': 7.5,
      'Very Vigorous (8+ METs)': 9.0,
    },
    'Basketball': {
      'Light (3-4 METs)': 4.5,
      'Moderate (4-6 METs)': 6.5,
      'Vigorous (6-8 METs)': 8.0,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Football': {
      'Light (3-4 METs)': 5.0,
      'Moderate (4-6 METs)': 7.0,
      'Vigorous (6-8 METs)': 8.5,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Tennis': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 6.0,
      'Vigorous (6-8 METs)': 8.0,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Jumping Rope': {
      'Light (3-4 METs)': 8.0,
      'Moderate (4-6 METs)': 10.0,
      'Vigorous (6-8 METs)': 12.0,
      'Very Vigorous (8+ METs)': 14.0,
    },
    'Elliptical': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 6.0,
      'Vigorous (6-8 METs)': 8.0,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Stair Climbing': {
      'Light (3-4 METs)': 4.0,
      'Moderate (4-6 METs)': 6.0,
      'Vigorous (6-8 METs)': 8.0,
      'Very Vigorous (8+ METs)': 10.0,
    },
    'Pilates': {
      'Light (3-4 METs)': 3.0,
      'Moderate (4-6 METs)': 4.0,
      'Vigorous (6-8 METs)': 5.0,
      'Very Vigorous (8+ METs)': 6.0,
    },
    'Boxing': {
      'Light (3-4 METs)': 5.0,
      'Moderate (4-6 METs)': 7.8,
      'Vigorous (6-8 METs)': 9.0,
      'Very Vigorous (8+ METs)': 12.0,
    },
    'Custom Activity': {
      'Light (3-4 METs)': 3.5,
      'Moderate (4-6 METs)': 5.0,
      'Vigorous (6-8 METs)': 7.0,
      'Very Vigorous (8+ METs)': 9.0,
    },
  };

  @override
  void dispose() {
    _weightController.dispose();
    _durationController.dispose();
    _customActivityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
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
      case 0:
        return _weightController.text.isNotEmpty;
      case 1:
        return _selectedActivity.isNotEmpty &&
            (_selectedActivity != 'Custom Activity' || _customActivityController.text.isNotEmpty);
      case 2:
        return _durationController.text.isNotEmpty && _selectedIntensity.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _calculateCalories() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final weight = double.parse(_weightController.text);
      final duration = double.parse(_durationController.text);

      // Convert weight to kg if needed
      double weightInKg = _selectedWeightUnit == 'kg' ? weight : weight * 0.453592;

      // Get MET value
      String activityName = _selectedActivity == 'Custom Activity'
          ? _customActivityController.text
          : _selectedActivity;

      double metValue = _metValues[_selectedActivity]?[_selectedIntensity] ?? 5.0;

      // Calculate calories using standard formula: (MET × 3.5 × weight in kg) / 200 × minutes
      double caloriesBurned = (metValue * 3.5 * weightInKg) / 200 * duration;

      setState(() {
        _calculationResult = {
          'activity': activityName,
          'duration': duration.round(),
          'weight': weight,
          'weightUnit': _selectedWeightUnit,
          'intensity': _selectedIntensity,
          'metValue': metValue,
          'caloriesBurned': caloriesBurned.round(),
          'explanation': _generateExplanation(activityName, duration, weightInKg, metValue, caloriesBurned),
        };
        _isCalculating = false;
      });

      _nextPage();
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating calories: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  String _generateExplanation(String activity, double duration, double weightKg, double met, double calories) {
    return 'This calculation is based on the Metabolic Equivalent of Task (MET) method. '
        'For $activity, we used a MET value of $met, which represents the energy cost of the activity. '
        'The formula used is: (MET × 3.5 × body weight in kg) ÷ 200 × duration in minutes. '
        'With your weight of ${weightKg.toStringAsFixed(1)} kg and duration of ${duration.round()} minutes, '
        'the estimated calories burned is ${calories.round()} kcal. '
        'Please note that individual factors like fitness level, body composition, and environmental conditions can affect the actual calorie burn.';
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
              'Calorie Burn Calculator',
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
                    _buildWeightPage(isDark),
                    _buildActivityPage(isDark),
                    _buildDurationPage(isDark),
                    _buildResultsPage(isDark),
                  ],
                ),
              ),

              // Navigation Buttons
              if (_currentPage < 3) _buildNavigationButtons(isDark),
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

  Widget _buildWeightPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Weight',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your current weight to calculate accurate calorie burn estimates.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  label: 'Weight',
                  controller: _weightController,
                  hint: 'Enter your weight',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  label: 'Unit',
                  value: _selectedWeightUnit,
                  items: _weightUnits,
                  onChanged: (value) {
                    setState(() {
                      _selectedWeightUnit = value ?? 'kg';
                    });
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sports_gymnastics,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Select Activity',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the physical activity you want to calculate calories for.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Activity Type',
            value: _selectedActivity.isEmpty ? null : _selectedActivity,
            items: _activities,
            onChanged: (value) {
              setState(() {
                _selectedActivity = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
          ),

          if (_selectedActivity == 'Custom Activity') ...[
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Custom Activity Name',
              controller: _customActivityController,
              hint: 'Enter activity name',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDurationPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Duration & Intensity',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How long did you exercise and at what intensity level?',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Duration (minutes)',
            controller: _durationController,
            hint: 'Enter duration in minutes',
            keyboardType: TextInputType.number,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Intensity Level',
            value: _selectedIntensity.isEmpty ? null : _selectedIntensity,
            items: _intensityLevels,
            onChanged: (value) {
              setState(() {
                _selectedIntensity = value ?? '';
              });
            },
            isDark: isDark,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage(bool isDark) {
    if (_calculationResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Calories Burned',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your estimated calorie burn based on the activity.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Calorie Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderColor(isDark),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Estimated Calories Burned',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_calculationResult!['caloriesBurned']}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Activity Summary
          Text(
            'Activity Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),

          const SizedBox(height: 16),

          _buildSummaryCard(
            'Activity',
            _calculationResult!['activity'],
            Icons.sports_gymnastics,
            isDark,
          ),

          _buildSummaryCard(
            'Duration',
            '${_calculationResult!['duration']} minutes',
            Icons.timer,
            isDark,
          ),

          _buildSummaryCard(
            'Weight',
            '${_calculationResult!['weight']} ${_calculationResult!['weightUnit']}',
            Icons.monitor_weight,
            isDark,
          ),

          _buildSummaryCard(
            'Intensity',
            _calculationResult!['intensity'],
            Icons.trending_up,
            isDark,
          ),

          _buildSummaryCard(
            'MET Value',
            _calculationResult!['metValue'].toString(),
            Icons.speed,
            isDark,
          ),

          const SizedBox(height: 24),

          // Explanation
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
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How We Calculated This',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _calculationResult!['explanation'],
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Calculate Again Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 0;
                  _calculationResult = null;
                  _weightController.clear();
                  _durationController.clear();
                  _customActivityController.clear();
                  _selectedActivity = '';
                  _selectedIntensity = '';
                });
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate),
                  const SizedBox(width: 8),
                  Text(
                    'Calculate Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                  ? (_isCalculating ? null : _calculateCalories)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCalculating
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
                  const Text('Calculating...'),
                ],
              )
                  : Text(
                _currentPage == 2 ? 'Calculate' : 'Next',
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
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
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.black,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
