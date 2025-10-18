import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class BodyCompositionAnalyzer extends StatefulWidget {
  const BodyCompositionAnalyzer({Key? key}) : super(key: key);

  @override
  State<BodyCompositionAnalyzer> createState() => _BodyCompositionAnalyzerState();
}

class _BodyCompositionAnalyzerState extends State<BodyCompositionAnalyzer> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedGender = '';
  String _selectedUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedActivityLevel = '';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  // Options
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _unitOptions = ['kg', 'lbs'];
  final List<String> _heightUnits = ['cm', 'ft/in'];
  final List<String> _activityLevels = [
    'Sedentary (little/no exercise)',
    'Light (1-3 days/week)',
    'Moderate (3-5 days/week)',
    'Active (6-7 days a week)',
    'Very Active (very hard exercise)',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
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
        return _ageController.text.isNotEmpty && _selectedGender.isNotEmpty;
      case 1:
        return _weightController.text.isNotEmpty;
      case 2:
        if (_selectedHeightUnit == 'cm') {
          return _heightController.text.isNotEmpty;
        } else {
          return _feetController.text.isNotEmpty && _inchesController.text.isNotEmpty;
        }
      case 3:
        return _selectedActivityLevel.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _analyzeBodyComposition() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      double height;

      if (_selectedHeightUnit == 'cm') {
        height = double.parse(_heightController.text);
      } else {
        final feet = double.parse(_feetController.text);
        final inches = double.parse(_inchesController.text);
        height = (feet * 12 + inches) * 2.54;
      }

      double weightKg = _selectedUnit == 'kg' ? weight : weight * 0.453592;
      double heightCm = height;

      setState(() {
        _analysisResult = _generateBodyAnalysis(weightKg, heightCm, age, _selectedGender);
        _isAnalyzing = false;
      });

      _nextPage();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing data: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _generateBodyAnalysis(
      double weight,
      double height,
      int age,
      String gender,
      ) {
    double bmi = weight / ((height / 100) * (height / 100));
    if (bmi.isNaN || bmi.isInfinite) bmi = 0.0;

    double bodyFatPercent;
    if (gender == 'Male') {
      bodyFatPercent = (1.20 * bmi) + (0.23 * age) - 16.2;
    } else {
      bodyFatPercent = (1.20 * bmi) + (0.23 * age) - 5.4;
    }

    bodyFatPercent = bodyFatPercent.clamp(5.0, 50.0);
    double bodyFatMass = weight * (bodyFatPercent / 100);
    double leanMass = weight - bodyFatMass;
    double skeletalMuscleMass = leanMass * (gender == 'Male' ? 0.45 : 0.36);

    double bmr;
    if (gender == 'Male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    int overallScore = _calculateOverallScore(bmi, bodyFatPercent, age, gender);

    return {
      'overallScore': overallScore,
      'bmi': bmi,
      'bodyFat': bodyFatPercent,
      'skeletalMuscle': skeletalMuscleMass,
      'leanMass': leanMass,
      'bodyFatMass': bodyFatMass,
      'bmr': bmr,
    };
  }

  int _calculateOverallScore(double bmi, double bodyFat, int age, String gender) {
    double score = 100.0;
    double optimalBMI = 22.0;
    score -= (bmi - optimalBMI).abs() * 2;

    double optimalBodyFat = gender == 'Male' ? 15.0 : 23.0;
    score -= (bodyFat - optimalBodyFat).abs() * 1.5;

    if (age > 30) score -= (age - 30) * 0.2;

    return score.round().clamp(20, 100);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _getBodyFatCategory(double bodyFat, String gender) {
    if (gender == 'Male') {
      if (bodyFat < 10) return 'Essential';
      if (bodyFat < 18) return 'Athletic';
      if (bodyFat < 25) return 'Good';
      return 'Excess';
    } else {
      if (bodyFat < 16) return 'Essential';
      if (bodyFat < 24) return 'Athletic';
      if (bodyFat < 31) return 'Good';
      return 'Excess';
    }
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
              'Body Composition Analyzer',
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
                    _buildPersonalDetailsPage(isDark),
                    _buildWeightPage(isDark),
                    _buildHeightPage(isDark),
                    _buildActivityPage(isDark),
                    _buildResultsPage(isDark),
                  ],
                ),
              ),

              // Navigation Buttons
              if (_currentPage < 4) _buildNavigationButtons(isDark),
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
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
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
            'Step ${_currentPage + 1} of 5',
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

  Widget _buildPersonalDetailsPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.person_outline,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with your basic information to personalize your analysis.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildTextField(
            label: 'Age',
            controller: _ageController,
            hint: 'Enter your age',
            keyboardType: TextInputType.number,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          _buildDropdownField(
            label: 'Gender',
            value: _selectedGender.isEmpty ? null : _selectedGender,
            items: _genderOptions,
            onChanged: (value) {
              setState(() {
                _selectedGender = value ?? '';
              });
            },
            isDark: isDark,
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
            'Enter your current weight. This will be used to calculate your body composition.',
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
                  hint: 'Enter weight',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  label: 'Unit',
                  value: _selectedUnit,
                  items: _unitOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value ?? 'kg';
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

  Widget _buildHeightPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.height,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Height',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your height to calculate your Body Mass Index (BMI) and other metrics.',
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
                child: _selectedHeightUnit == 'cm'
                    ? _buildTextField(
                  label: 'Height',
                  controller: _heightController,
                  hint: 'Enter height in cm',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                )
                    : Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Feet',
                        controller: _feetController,
                        hint: 'ft',
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Inches',
                        controller: _inchesController,
                        hint: 'in',
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  label: 'Unit',
                  value: _selectedHeightUnit,
                  items: _heightUnits,
                  onChanged: (value) {
                    setState(() {
                      _selectedHeightUnit = value ?? 'cm';
                      _heightController.clear();
                      _feetController.clear();
                      _inchesController.clear();
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
            Icons.fitness_center,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Activity Level',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your typical activity level to get more accurate metabolic calculations.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _buildDropdownField(
            label: 'Activity Level',
            value: _selectedActivityLevel.isEmpty ? null : _selectedActivityLevel,
            items: _activityLevels,
            onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value ?? '';
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
    if (_analysisResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: AppColors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Body Analysis',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your personalized body composition analysis based on your information.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Overall Score
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
                  'Overall Health Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_analysisResult!['overallScore']}',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Key Metrics
          Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),

          const SizedBox(height: 16),

          _buildMetricCard(
            'BMI',
            _analysisResult!['bmi'].toStringAsFixed(1),
            '',
            _getBMICategory(_analysisResult!['bmi']),
            isDark,
          ),

          _buildMetricCard(
            'Body Fat',
            _analysisResult!['bodyFat'].toStringAsFixed(1),
            '%',
            _getBodyFatCategory(_analysisResult!['bodyFat'], _selectedGender),
            isDark,
          ),

          _buildMetricCard(
            'Skeletal Muscle',
            _analysisResult!['skeletalMuscle'].toStringAsFixed(1),
            'kg',
            'Good',
            isDark,
          ),

          _buildMetricCard(
            'BMR',
            _analysisResult!['bmr'].toStringAsFixed(0),
            'kcal/day',
            'Normal',
            isDark,
          ),

          const SizedBox(height: 32),

          // Start New Analysis Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage = 0;
                  _analysisResult = null;
                  _ageController.clear();
                  _weightController.clear();
                  _heightController.clear();
                  _feetController.clear();
                  _inchesController.clear();
                  _selectedGender = '';
                  _selectedActivityLevel = '';
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
                  const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  Text(
                    'Start New Analysis',
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
              onPressed: _currentPage == 3
                  ? (_isAnalyzing ? null : _analyzeBodyComposition)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAnalyzing
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
                  const Text('Analyzing...'),
                ],
              )
                  : Text(
                _currentPage == 3 ? 'Analyze' : 'Next',
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

  Widget _buildMetricCard(
      String title,
      String value,
      String unit,
      String category,
      bool isDark,
      ) {
    Color categoryColor;
    switch (category.toLowerCase()) {
      case 'normal':
      case 'healthy':
      case 'athletic':
      case 'good':
      case 'excellent':
        categoryColor = AppColors.successColor;
        break;
      case 'overweight':
      case 'excess':
        categoryColor = AppColors.warningColor;
        break;
      case 'obese':
      case 'high risk':
      case 'high':
        categoryColor = AppColors.errorColor;
        break;
      default:
        categoryColor = AppColors.textSecondary(isDark);
    }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
