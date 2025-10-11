import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/features/onboarding/service/observices.dart';
import 'package:trackai/features/settings/service/geminiservice.dart';
import 'package:trackai/features/settings/service/goalservice.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class AdjustGoalsPage extends StatefulWidget {
  const AdjustGoalsPage({Key? key}) : super(key: key);

  @override
  State<AdjustGoalsPage> createState() => _AdjustGoalsPageState();
}

class _AdjustGoalsPageState extends State<AdjustGoalsPage> {
  Map<String, dynamic>? _goalsData;
  bool _isLoading = false;
  bool _isCalculating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExistingGoals();
  }

  Future<void> _loadExistingGoals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final existingGoals = await GoalsService.getGoals();

      if (existingGoals != null) {
        setState(() {
          _goalsData = existingGoals;
          _isLoading = false;
        });
      } else {
        await _calculateGoals();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load goals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateGoals() async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final onboardingData = await OnboardingService.getOnboardingData();

      if (onboardingData == null) {
        throw Exception('No onboarding data found. Please complete onboarding first.');
      }

      final calculatedGoals = await GeminiService.calculateNutritionGoals(
        onboardingData: onboardingData,
      );

      if (calculatedGoals == null) {
        throw Exception('Failed to calculate goals. Please try again.');
      }

      await GoalsService.saveGoals(calculatedGoals);

      setState(() {
        _goalsData = calculatedGoals;
        _isCalculating = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goals calculated and saved successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCalculating = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _calculateGoalsWithCustomData(Map<String, dynamic> formData) async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final calculatedGoals = await GeminiService.calculateNutritionGoals(
        onboardingData: formData,
      );

      if (calculatedGoals == null) {
        throw Exception('Failed to calculate goals. Please try again.');
      }

      await GoalsService.saveGoals(calculatedGoals);

      setState(() {
        _goalsData = calculatedGoals;
        _isCalculating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goals recalculated and saved successfully!'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCalculating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _showRecalculateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RecalculateGoalsDialog(
          onCalculate: _calculateGoalsWithCustomData,
          isCalculating: _isCalculating,
        );
      },
    );
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(isDarkTheme ? 0.3 : 0.1),
          blurRadius: 8,
          spreadRadius: 1,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isDarkTheme,
    String? placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDarkTheme ? AppColors.darkBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50], // Match card decoration
            elevation: 1,
            leading: IconButton(
              icon: Icon(
                lucide.LucideIcons.arrowLeft, // Match web's ArrowLeftIcon
                color: isDarkTheme ? Colors.white : Colors.black, // Black and white theme
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(
                  lucide.LucideIcons.target,
                  color: isDarkTheme ? Colors.white : Colors.black, // Black and white theme
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Your Daily Targets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          body: _buildBody(isDarkTheme),
        );
      },
    );
  }

  Widget _buildBody(bool isDarkTheme) {
    if (_isLoading || _isCalculating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 16),
            Text(
              _isCalculating ? 'Calculating your goals...' : 'Loading goals...',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning, // Match web's AlertTriangleIcon
                  size: 64,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateGoals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_goalsData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  lucide.LucideIcons.target,
                  size: 64,
                  color: isDarkTheme ? Colors.white : Colors.black, // Black and white theme
                ),
                const SizedBox(height: 16),
                Text(
                  'No goals found',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s calculate your personalized nutrition goals',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculateGoals,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(lucide.LucideIcons.sparkles),
                        SizedBox(width: 8),
                        Text(
                          'Calculate Goals',
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
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.target,
                      color: isDarkTheme ? Colors.white : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Daily Targets',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'These are your AI-generated daily nutritional goals. You can recalculate them anytime.',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              children: [
                Icon(
                  lucide.LucideIcons.flame,
                  color: isDarkTheme ? Colors.white : Colors.black,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Calories',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_goalsData!['calories']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'kcal',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  isDarkTheme,
                  lucide.LucideIcons.dumbbell,
                  'Protein',
                  '${_goalsData!['protein']}',
                  'g',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  isDarkTheme,
                  lucide.LucideIcons.wheat,
                  'Carbs',
                  '${_goalsData!['carbs']}',
                  'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  isDarkTheme,
                  lucide.LucideIcons.droplet,
                  'Fat',
                  '${_goalsData!['fat']}',
                  'g',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMacroCard(
                  isDarkTheme,
                  lucide.LucideIcons.leaf,
                  'Fiber',
                  '${_goalsData!['fiber']}',
                  'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.brain,
                      color: isDarkTheme ? Colors.white : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Explanation',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Detailed breakdown of your personalized macro plan',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Daily Energy Needs:',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Your Basal Metabolic Rate (BMR) is approximately ${_goalsData!['bmr']} kcal, the energy your body needs at rest.',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• With your activity level, your Total Daily Energy Expenditure (TDEE) is about ${_goalsData!['tdee']} kcal to maintain your current weight.',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Calorie Goal:',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Your target daily calorie intake is ${_goalsData!['calories']} kcal, a ${_goalsData!['calories'] > _goalsData!['tdee'] ? 'surplus' : 'deficit'} of ${(_goalsData!['calories'] - _goalsData!['tdee']).abs()} kcal ${_goalsData!['calories'] > _goalsData!['tdee'] ? 'above' : 'below'} your maintenance level.',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Custom Macro Plan:',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Your macros are balanced to support your goals, prioritizing protein for muscle preservation/growth, carbs for energy, and fats for hormonal function, with sufficient fiber for health and digestion.',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_goalsData!['explanation'] != null && _goalsData!['explanation'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional AI Insights:',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.white : Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _goalsData!['explanation'].toString(),
                              style: TextStyle(
                                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCalculating ? null : _showRecalculateDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isCalculating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recalculating...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(lucide.LucideIcons.sparkles),
                        SizedBox(width: 8),
                        Text(
                          'Recalculate Goals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_goalsData!['calculatedAt'] != null)
            Center(
              child: Text(
                'Last updated: ${_formatDate(_goalsData!['calculatedAt'])}',
                style: TextStyle(
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    bool isDarkTheme,
    IconData icon,
    String label,
    String value,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        children: [
          Icon(
            icon,
            color: isDarkTheme ? Colors.white : Colors.black,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class RecalculateGoalsDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCalculate;
  final bool isCalculating;

  const RecalculateGoalsDialog({
    Key? key,
    required this.onCalculate,
    required this.isCalculating,
  }) : super(key: key);

  @override
  State<RecalculateGoalsDialog> createState() => _RecalculateGoalsDialogState();
}

class _RecalculateGoalsDialogState extends State<RecalculateGoalsDialog> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form data
  int? _age;
  String? _gender;
  bool _isMetric = true;
  double? _weightKg;
  double? _weightLbs;
  int? _heightCm;
  int? _heightFeet;
  int? _heightInches;
  String? _workoutFrequency;
  String? _goal;

  final List<String> _workoutOptions = [
    'Light (1-3 days/wk)',
    'Moderate (3-5 days/wk)',
    'Active (6-7 days/wk)',
  ]; // Aligned with web code

  final List<String> _goalOptions = [
    'Weight Loss',
    'Maintenance',
    'Weight Gain',
  ]; // Aligned with web code

  BoxDecoration _getDialogCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(isDarkTheme ? 0.3 : 0.1),
          blurRadius: 8,
          spreadRadius: 1,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_canProceedFromStep(_currentStep)) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _calculateGoals();
      }
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _calculateGoals() {
    final formData = {
      'age': _age,
      'gender': _gender?.toLowerCase(),
      'isMetric': _isMetric,
      'weightKg': _weightKg,
      'weightLbs': _weightLbs,
      'heightCm': _heightCm,
      'heightFeet': _heightFeet,
      'heightInches': _heightInches,
      'workoutFrequency': _workoutFrequency,
      'goal': _goal?.toLowerCase().replaceAll(' ', '_'),
      'dateOfBirth': DateTime.now().subtract(Duration(days: (_age ?? 25) * 365)),
    };

    widget.onCalculate(formData);
    Navigator.of(context).pop();
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0:
        return _age != null && _gender != null;
      case 1:
        if (_isMetric) {
          return _weightKg != null && _heightCm != null;
        } else {
          return _weightLbs != null && _heightFeet != null && _heightInches != null;
        }
      case 2:
        return _workoutFrequency != null && _goal != null;
      default:
        return false;
    }
  }

  Widget _buildInputField({
    required String label,
    required bool isDarkTheme,
    String? placeholder,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Provider.of<ThemeProvider>(context).isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: _getDialogCardDecoration(isDarkTheme),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        lucide.LucideIcons.user,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _currentStep == 0
                            ? 'Personal Details'
                            : _currentStep == 1
                                ? 'Body Measurements'
                                : 'Lifestyle & Goals',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Step ${_currentStep + 1} of 3. Adjust your details to generate a new macro plan.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? isDarkTheme
                                ? Colors.white
                                : Colors.black
                            : isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalDetailsPage(isDarkTheme),
                  _buildPhysicalDetailsPage(isDarkTheme),
                  _buildGoalsPage(isDarkTheme),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              lucide.LucideIcons.arrowLeft,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: isDarkTheme ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canProceedFromStep(_currentStep)
                          ? (_currentStep == 2 ? _calculateGoals : _nextPage)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 2 ? 'Calculate' : 'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentStep < 2) SizedBox(width: 8),
                          if (_currentStep < 2)
                            Icon(
                              lucide.LucideIcons.arrowRight,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsPage(bool isDarkTheme) {
    final ageController = TextEditingController(text: _age?.toString() ?? '');

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField(
            label: 'Age',
            isDarkTheme: isDarkTheme,
            placeholder: 'Enter your age',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _age = int.tryParse(value);
              });
            },
          ),
          SizedBox(height: 24),
          Text(
            'Gender',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _gender = 'Male';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _gender == 'Male'
                          ? (isDarkTheme ? Colors.white : Colors.black)
                          : isDarkTheme
                              ? AppColors.darkCardBackground
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _gender == 'Male'
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Male',
                        style: TextStyle(
                          color: _gender == 'Male'
                              ? (isDarkTheme ? Colors.black : Colors.white)
                              : isDarkTheme
                                  ? Colors.white
                                  : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _gender = 'Female';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _gender == 'Female'
                          ? (isDarkTheme ? Colors.white : Colors.black)
                          : isDarkTheme
                              ? AppColors.darkCardBackground
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _gender == 'Female'
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Female',
                        style: TextStyle(
                          color: _gender == 'Female'
                              ? (isDarkTheme ? Colors.black : Colors.white)
                              : isDarkTheme
                                  ? Colors.white
                                  : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildPhysicalDetailsPage(bool isDarkTheme) {
    final weightKgController = TextEditingController(text: _weightKg?.toString() ?? '');
    final weightLbsController = TextEditingController(text: _weightLbs?.toString() ?? '');
    final heightCmController = TextEditingController(text: _heightCm?.toString() ?? '');
    final heightFeetController = TextEditingController(text: _heightFeet?.toString() ?? '');
    final heightInchesController = TextEditingController(text: _heightInches?.toString() ?? '');

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMetric = true;
                        _weightLbs = null;
                        _heightFeet = null;
                        _heightInches = null;
                        weightLbsController.clear();
                        heightFeetController.clear();
                        heightInchesController.clear();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isMetric
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Metric (kg/cm)',
                          style: TextStyle(
                            color: _isMetric
                                ? (isDarkTheme ? Colors.black : Colors.white)
                                : isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMetric = false;
                        _weightKg = null;
                        _heightCm = null;
                        weightKgController.clear();
                        heightCmController.clear();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isMetric
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Imperial (lbs/ft)',
                          style: TextStyle(
                            color: !_isMetric
                                ? (isDarkTheme ? Colors.black : Colors.white)
                                : isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildInputField(
            label: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
            isDarkTheme: isDarkTheme,
            placeholder: _isMetric ? 'Enter weight in kg' : 'Enter weight in lbs',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                if (_isMetric) {
                  _weightKg = double.tryParse(value);
                } else {
                  _weightLbs = double.tryParse(value);
                }
              });
            },
          ),
          SizedBox(height: 24),
          Text(
            _isMetric ? 'Height (cm)' : 'Height (ft/in)',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          if (_isMetric)
            _buildInputField(
              label: 'Height (cm)',
              isDarkTheme: isDarkTheme,
              placeholder: 'Enter height in cm',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _heightCm = int.tryParse(value);
                });
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Feet',
                    isDarkTheme: isDarkTheme,
                    placeholder: 'Feet',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _heightFeet = int.tryParse(value);
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    label: 'Inches',
                    isDarkTheme: isDarkTheme,
                    placeholder: 'Inches',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _heightInches = int.tryParse(value);
                      });
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage(bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Frequency',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Column(
              children: _workoutOptions.map((option) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _workoutFrequency = option;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _workoutFrequency == option
                          ? (isDarkTheme ? Colors.white : Colors.black)
                          : isDarkTheme
                              ? AppColors.darkCardBackground
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _workoutFrequency == option
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _workoutFrequency == option
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _workoutFrequency == option
                              ? (isDarkTheme ? Colors.black : Colors.white)
                              : isDarkTheme
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          option,
                          style: TextStyle(
                            color: _workoutFrequency == option
                                ? (isDarkTheme ? Colors.black : Colors.white)
                                : isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            Text(
              'Primary Goal',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Column(
              children: _goalOptions.map((option) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _goal = option;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _goal == option
                          ? (isDarkTheme ? Colors.white : Colors.black)
                          : isDarkTheme
                              ? AppColors.darkCardBackground
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _goal == option
                            ? (isDarkTheme ? Colors.white : Colors.black)
                            : isDarkTheme
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _goal == option
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _goal == option
                              ? (isDarkTheme ? Colors.black : Colors.white)
                              : isDarkTheme
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          option,
                          style: TextStyle(
                            color: _goal == option
                                ? (isDarkTheme ? Colors.black : Colors.white)
                                : isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}