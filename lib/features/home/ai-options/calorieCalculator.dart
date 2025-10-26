import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

import '../../settings/service/geminiservice.dart';

// NOTE: Assuming GeminiService, AppColors, etc., are available.

// --- CommonActivity Class Definition ---
class CommonActivity {
  final String label;
  final String value;
  final int defaultDuration;
  const CommonActivity({ required this.label, required this.value, required this.defaultDuration});
}

const List<CommonActivity> _commonActivities = [
  CommonActivity(label: "Running", value: "Running at a moderate pace for 30 minutes", defaultDuration: 30),
  CommonActivity(label: "Walking", value: "Walking briskly for 45 minutes", defaultDuration: 45),
  CommonActivity(label: "Cycling", value: "Cycling at a steady pace for 60 minutes", defaultDuration: 60),
  CommonActivity(label: "Swimming", value: "Swimming laps for 30 minutes", defaultDuration: 30),
  CommonActivity(label: "Lifting", value: "General weightlifting session for 45 minutes", defaultDuration: 45),
  CommonActivity(label: "Yoga", value: "Yoga session for 60 minutes", defaultDuration: 60),
  CommonActivity(label: "HIIT", value: "High-Intensity Interval Training (HIIT) for 20 minutes", defaultDuration: 20),
  CommonActivity(label: "Rowing", value: "Rowing machine at a moderate pace for 30 minutes", defaultDuration: 30),
  CommonActivity(label: "Stair Climber", value: "Using a stair climber machine for 20 minutes", defaultDuration: 20),
  CommonActivity(label: "Elliptical", value: "Elliptical trainer workout for 30 minutes", defaultDuration: 30),
  CommonActivity(label: "Hiking", value: "Hiking on a trail for 90 minutes", defaultDuration: 90),
  CommonActivity(label: "Dancing", value: "Dancing (e.g., zumba, aerobic) for 45 minutes", defaultDuration: 45),
  CommonActivity(label: "Pilates", value: "Pilates session for 50 minutes", defaultDuration: 50),
  CommonActivity(label: "Jumping Rope", value: "Jumping rope for 15 minutes", defaultDuration: 15),
  CommonActivity(label: "Football (Soccer)", value: "Playing a game of football (soccer) for 60 minutes", defaultDuration: 60),
  CommonActivity(label: "Basketball", value: "Playing a game of basketball for 60 minutes", defaultDuration: 60),
  CommonActivity(label: "Tennis", value: "Playing a game of tennis for 60 minutes", defaultDuration: 60),
  CommonActivity(label: "Badminton", value: "Playing a game of badminton for 45 minutes", defaultDuration: 45),
];


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
  final _activityController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedWeightUnit = 'kg';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _selectedActivityLabel; // NEW: Store selected activity label for styling

  // Options
  final List<String> _weightUnits = ['kg', 'lb'];
  static const int _totalInputSteps = 3;


  @override
  void dispose() {
    _weightController.dispose();
    _durationController.dispose();
    _activityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    bool valid = false;
    switch (_currentPage) {
      case 0: valid = _validateActivity(); break;
      case 1: valid = _validateDuration(); break;
      case 2: valid = _validateWeightAndUnit(); break;
      default: valid = true;
    }

    if (valid) {
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- Validation Functions ---
  bool _validateActivity() {
    if (_activityController.text.trim().isEmpty) {
      _showValidationError("Please describe the activity.");
      return false;
    }
    return true;
  }
  bool _validateDuration() {
    final duration = double.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      _showValidationError("Please enter a valid duration in minutes.");
      return false;
    }
    return true;
  }
  bool _validateWeightAndUnit() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showValidationError("Please enter a valid positive weight.");
      return false;
    }
    if (_selectedWeightUnit.isEmpty) {
      _showValidationError("Please select a weight unit.");
      return false;
    }
    return true;
  }
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- MODIFIED: _calculateCalories calls Gemini API ---
  Future<void> _calculateCalories() async {
    FocusScope.of(context).unfocus();

    if (!_validateActivity() || !_validateDuration() || !_validateWeightAndUnit()) {
      _showValidationError("Please ensure all fields are valid before calculating.");
      return;
    }

    setState(() { _isLoading = true; _result = null; });

    try {
      final activityDescription = _activityController.text.trim();
      final duration = double.parse(_durationController.text);
      final weight = double.parse(_weightController.text);
      double weightInKg = _selectedWeightUnit == 'kg' ? weight : weight * 0.453592;

      String combinedDescription = activityDescription;
      if (!RegExp(r'\b\d+\s*(?:minute|min|hour|hr)s?\b', caseSensitive: false).hasMatch(combinedDescription)) {
        combinedDescription += ' for ${duration.round()} minutes';
      }

      // --- Call Gemini Service ---
      final apiResult = await GeminiService.calculateCaloriesBurned(
          activityDescriptionWithDuration: combinedDescription,
          userWeightKg: weightInKg
      );

      if (apiResult != null) {
        setState(() {
          _result = {
            'activity': activityDescription,
            'duration': duration,
            'weight': weight,
            'weightUnit': _selectedWeightUnit,
            'estimatedCaloriesBurned': apiResult['estimatedCaloriesBurned'],
            'explanation': apiResult['explanation'],
          };
          _isLoading = false;
        });
        // Navigate to results page (index 3)
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        throw Exception("Received null result from API service without specific error.");
      }

    } catch (e) {
      print("Error in _calculateCalories (UI): $e");
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleActivityButtonTap(String description, int duration, String label) {
    setState(() {
      _activityController.text = description;
      _durationController.text = duration.toString(); // Pre-fill duration
      _selectedActivityLabel = label; // Set label for styling
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final Color primaryTextColor = isDark ? Colors.white : Colors.black;
        // Use AppColors.background(isDark) for app bar/nav bar to match primary background
        final Color backgroundFillColor = isDark ? AppColors.darkCardBackground : Colors.white;

        return Scaffold(
          // --- SCRAFFOLD/BACKGROUND FIX ---
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: backgroundFillColor,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon( Icons.arrow_back_ios_new, color: primaryTextColor, size: 20 ),
            ),
            title: Text( 'Calorie Burn Calculator', style: TextStyle( color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProgressIndicator(isDark),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) { setState(() { _currentPage = index; }); },
                    children: [
                      // Page 0: Activity
                      _buildActivityPage(isDark),

                      // Page 1: Duration
                      _buildDurationPage(isDark),

                      // Page 2: Weight & Unit (COMBINED)
                      _buildWeightPage(isDark),

                      // Page 3: Results
                      _buildResultsPage(isDark),
                    ],
                  ),
                ),
                // Navigation Buttons
                if (_result == null) _buildNavigationButtons(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  // =================================================================
  // WIDGETS (UNIFIED STYLING AND LAYOUTS)
  // =================================================================

  Widget _buildProgressIndicator(bool isDark) {
    const int totalSteps = _totalInputSteps;
    final Color activeColor = isDark ? Colors.white : Colors.black;
    final Color inactiveColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!))
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _currentPage < totalSteps ? 'Step ${_currentPage + 1} of $totalSteps' : 'Result',
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

  // --- UNIFIED Question Page Header/Layout ---
  Widget _buildQuestionPage({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      // --- BACKGROUND FIX ---
      color: isDark ? Colors.black : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text( title, style: TextStyle( fontSize: 24, fontWeight: FontWeight.bold, color: primaryTextColor, height: 1.3)),
            const SizedBox(height: 8),
            Text( subtitle, style: TextStyle( fontSize: 15, color: secondaryTextColor, height: 1.5)),
            const SizedBox(height: 24),
            child,
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // --- Page 0: Activity (Fixed Three Column Layout) ---
  Widget _buildActivityPage(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final isActivitySelected = _selectedActivityLabel != null;

    return _buildQuestionPage(
      isDark: isDark,
      title: 'Activity Description',
      subtitle: 'Describe the activity including intensity, or select a common one.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _activityController,
            hint: "E.g., Running vigorously for 25 min, Light swimming laps for 1 hour",
            isDark: isDark,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Text(
            'Or, select a common activity (duration included):',
            style: TextStyle( fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          // --- Fixed Three-Column Layout ---
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 8.0;
              final double totalWidth = constraints.maxWidth;
              final double itemWidth = (totalWidth - (2 * spacing)) / 3.0;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _commonActivities.map((activity) {
                  final isSelected = _selectedActivityLabel == activity.label;
                  final Color buttonBg = isSelected ? AppColors.black : AppColors.cardBackground(isDark);
                  final Color buttonFg = isSelected ? AppColors.white : primaryTextColor;

                  return SizedBox(
                    width: itemWidth,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        // --- Button Style Fix ---
                        backgroundColor: buttonBg,
                        side: BorderSide(
                            color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                            width: isSelected ? 2 : 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _handleActivityButtonTap(activity.value, activity.defaultDuration, activity.label),
                      child: Text(
                        activity.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: buttonFg, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            "Tip: Be specific for a better estimate (e.g., 'fast cycling uphill'). 🚴‍♀️",
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[700]),
          )
        ],
      ),
    );
  }

  // --- Page 1: Duration ---
  Widget _buildDurationPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'Duration',
      subtitle: 'Confirm or enter the duration in minutes.',
      child: _buildTextField(
        controller: _durationController,
        hint: 'Enter duration in minutes',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        isDark: isDark,
      ),
    );
  }

  // --- Page 2: Weight & Unit (Combined, Unified UI) ---
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
              color: isDark ? AppColors.inputFill(true) : Colors.grey[200],
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
                              color: _selectedWeightUnit == option ? AppColors.white : primaryTextColor,
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
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            isDark: isDark,
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
    int? maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color inputFillColor = isDark ? AppColors.inputFill(true) : Colors.white;
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final Color focusedBorderColor = isDark ? Colors.white : Colors.black;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: TextStyle(color: primaryTextColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder( borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: focusedBorderColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) { return 'This field is required'; }
        return null;
      },
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    final bool isLastInputStep = _currentPage == _totalInputSteps - 1;
    final Color primaryButtonBg = isDark ? Colors.white : Colors.black;
    final Color primaryButtonFg = isDark ? Colors.black : Colors.white;
    final Color secondaryButtonBorder = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: secondaryButtonBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Back', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading && isLastInputStep
                  ? null
                  : (isLastInputStep ? _calculateCalories : _nextPage),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonBg, foregroundColor: primaryButtonFg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: _isLoading && isLastInputStep
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primaryButtonFg))),
                const SizedBox(width: 10),
                Text('Calculating...', style: TextStyle(color: primaryButtonFg)),
              ],)
                  : Text( isLastInputStep ? 'Calculate' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage(bool isDark) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final Color mutedBg = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    if (_result == null) {
      return Container(
          color: isDark ? Colors.black : Colors.grey[50],
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink()
      );
    }

    return Container(
      color: isDark ? Colors.black : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildResultCard(_result!, isDark, isRecent: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPage = 0; _result = null; _activityController.clear();
                    _durationController.clear(); _weightController.clear();
                    _selectedWeightUnit = 'kg';
                    _selectedActivityLabel = null;
                  });
                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTextColor, foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.refresh, size: 20), SizedBox(width: 10),
                  Text('Calculate Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> resultData, bool isDark, {bool isRecent = false}) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final Color mutedBg = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Card(
      elevation: isRecent ? 0 : 1,
      color: cardBg,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecent ? BorderSide.none : BorderSide(color: borderColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calorie Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(color: mutedBg, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Column( children: [
                Text('Estimated Calories Burned', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                    (resultData['estimatedCaloriesBurned'] as double?)?.round().toString() ?? '--',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryTextColor)
                ),
                Text('kcal', style: TextStyle(color: secondaryTextColor, fontSize: 16)),
              ],),),
            ),
            const SizedBox(height: 16),
            // Explanation Section (ExpansionTile)
            Container(
              decoration: BoxDecoration(
                color: mutedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                iconColor: primaryTextColor,
                collapsedIconColor: primaryTextColor,
                title: Text(
                  "Detailed Breakdown",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor),
                ),
                children: <Widget>[
                  Divider(height: 1, color: borderColor),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      resultData['explanation'] as String? ?? 'No explanation provided by AI.',
                      style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.5),
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
}