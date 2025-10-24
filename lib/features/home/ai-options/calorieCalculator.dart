import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

import '../../settings/service/geminiservice.dart';
// --- IMPORT YOUR GEMINI SERVICE ---

// CommonActivity class definition (outside State)
class CommonActivity { /* ... as before ... */
  final String label;
  final String value;
  final int defaultDuration;
  const CommonActivity({ required this.label, required this.value, required this.defaultDuration});
}

const List<CommonActivity> _commonActivities = [ /* ... as before ... */
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
  final _durationController = TextEditingController(); // Keep for explicit entry
  final _activityController = TextEditingController();

  // State variables
  int _currentPage = 0;
  String _selectedWeightUnit = 'kg';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  // REMOVED _extractedDuration as we now require explicit duration input
  // String? _apiError; // Optional: Store API error message

  // Options
  final List<String> _weightUnits = ['kg', 'lb'];

  // REMOVED local MET estimation function and map

  @override
  void dispose() {
    _weightController.dispose();
    _durationController.dispose();
    _activityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate before moving
    bool valid = false;
    switch (_currentPage) {
      case 0: valid = _validateActivity(); break;
      case 1: valid = _validateDuration(); break;
      case 2: valid = _validateWeight(); break;
      case 3: valid = _validateWeightUnit(); break;
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
  bool _validateActivity() { /* ... as before ... */
    if (_activityController.text.trim().isEmpty) {
      _showValidationError("Please describe the activity.");
      return false;
    }
    return true;
  }
  bool _validateDuration() { /* ... as before ... */
    final duration = double.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      _showValidationError("Please enter a valid duration in minutes.");
      return false;
    }
    return true;
  }
  bool _validateWeight() { /* ... as before ... */
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      _showValidationError("Please enter a valid positive weight.");
      return false;
    }
    return true;
  }
  bool _validateWeightUnit() { /* ... as before ... */
    if (_selectedWeightUnit.isEmpty) {
      _showValidationError("Please select a weight unit.");
      return false;
    }
    return true;
  }
  void _showValidationError(String message) { /* ... as before ... */
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- MODIFIED: _calculateCalories calls Gemini API ---
  Future<void> _calculateCalories() async {
    FocusScope.of(context).unfocus();

    // Final validation of all fields before calling API
    if (!_validateActivity() || !_validateDuration() || !_validateWeight() || !_validateWeightUnit()) {
      _showValidationError("Please ensure all fields are valid before calculating.");
      return;
    }

    setState(() { _isLoading = true; _result = null; /* _apiError = null; */ });

    try {
      final activityDescription = _activityController.text.trim();
      final duration = double.parse(_durationController.text); // Use explicit duration
      final weight = double.parse(_weightController.text);
      double weightInKg = _selectedWeightUnit == 'kg' ? weight : weight * 0.453592;

      // --- Combine description and duration for the API ---
      // Ensure duration is clearly stated, append if not obvious from description
      String combinedDescription = activityDescription;
      // Simple check if description already mentions duration (you might refine this regex)
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
            // Store original inputs along with API results if needed
            'activity': activityDescription,
            'duration': duration, // Store original duration
            'weight': weight,
            'weightUnit': _selectedWeightUnit,
            // Results from API
            'estimatedCaloriesBurned': apiResult['estimatedCaloriesBurned'],
            'explanation': apiResult['explanation'],
          };
          _isLoading = false;
        });
        // Navigate to results page
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // This case should ideally be handled by exceptions in the service
        throw Exception("Received null result from API service without specific error.");
      }

    } catch (e) {
      print("Error in _calculateCalories (UI): $e");
      setState(() {
        _isLoading = false;
        // _apiError = e.toString().replaceFirst("Exception: ", ""); // Optional: store error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Show the specific error from the service/API
            content: Text(e.toString().replaceFirst("Exception: ", "")), // Clean up message
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Explanation is now provided by the API, so this function is not needed
  // String _generateExplanation(...) { ... } // REMOVED

  void _handleActivityButtonTap(String description, int duration) {
    setState(() {
      _activityController.text = description;
      _durationController.text = duration.toString(); // Pre-fill duration
    });
  }


  @override
  Widget build(BuildContext context) {
    // ... rest of build method is the same, including PageView setup ...
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final Color primaryTextColor = isDark ? Colors.white : Colors.black;
        final Color cardBackgroundColor = isDark ? AppColors.darkCardBackground : Colors.white;

        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.grey[50],
          appBar: AppBar( /* ... AppBar setup ... */
            backgroundColor: cardBackgroundColor,
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
                _buildProgressIndicator(isDark), // Uses _currentPage
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) { setState(() { _currentPage = index; }); },
                    children: [
                      // Page 0: Activity
                      _buildQuestionPage(
                        isDark: isDark,
                        icon: lucide.LucideIcons.activity,
                        title: 'Activity Description',
                        subtitle: 'Describe the activity including intensity (e.g., light walk, vigorous run), or select a common one.',
                        child: Column( /* ... Activity Input Widgets ... */
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
                              style: TextStyle( fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8.0, runSpacing: 8.0,
                              children: _commonActivities.map((activity) => OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () => _handleActivityButtonTap(activity.value, activity.defaultDuration),
                                child: Text(activity.label, style: TextStyle(fontSize: 12, color: primaryTextColor)),
                              )).toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Tip: Be specific for a better estimate (e.g., 'fast cycling uphill'). 🚴‍♀️",
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[700]),
                            )
                          ],
                        ),
                      ),
                      // Page 1: Duration
                      _buildQuestionPage(
                        isDark: isDark,
                        icon: lucide.LucideIcons.timer,
                        title: 'Duration',
                        subtitle: 'Confirm or enter the duration in minutes.', // Updated subtitle
                        child: _buildTextField(
                          controller: _durationController,
                          hint: 'Enter duration in minutes',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          isDark: isDark,
                        ),
                      ),
                      // Page 2: Weight
                      _buildQuestionPage(
                        isDark: isDark,
                        icon: lucide.LucideIcons.scale,
                        title: 'Your Weight',
                        subtitle: 'Enter your current weight.',
                        child: _buildTextField(
                          controller: _weightController,
                          hint: 'Enter weight value',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          isDark: isDark,
                        ),
                      ),
                      // Page 3: Weight Unit
                      _buildQuestionPage(
                        isDark: isDark,
                        icon: Icons.straighten,
                        title: 'Weight Unit',
                        subtitle: 'Select the unit for the weight entered.',
                        child: Column(
                          children: _weightUnits.map((unit) {
                            return _buildSelectionCard(
                              title: unit == 'kg' ? 'Kilograms (kg)' : 'Pounds (lb)',
                              isSelected: _selectedWeightUnit == unit,
                              onTap: () { setState(() { _selectedWeightUnit = unit; }); },
                              isDark: isDark,
                              icon: Icons.fitness_center,
                            );
                          }).toList(),
                        ),
                      ),
                      // Page 4: Results
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

  // --- WIDGETS ---
  // _buildProgressIndicator, _buildQuestionPage, _buildSelectionCard,
  // _buildTextField, _buildNavigationButtons, _buildResultsPage, _buildResultCard
  // remain largely the same. Ensure _buildNavigationButtons calls _calculateCalories on the last step (index 3).

  Widget _buildProgressIndicator(bool isDark) {
    const int totalSteps = 4; // Activity, Duration, Weight, Unit
    final Color activeColor = isDark ? Colors.white : Colors.black;
    final Color inactiveColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container( /* ... Decoration ... */
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

  Widget _buildQuestionPage({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container( /* ... Decoration ... */
      color: isDark ? Colors.black : Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text( title, style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor, height: 1.3)),
            const SizedBox(height: 8),
            Text( subtitle, style: TextStyle( fontSize: 14, color: secondaryTextColor, height: 1.5)),
            const SizedBox(height: 24),
            child,
            const SizedBox(height: 100), // Space for nav buttons
          ],
        ),
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
    // ... Selection Card implementation ...
    final Color selectedBg = isDark ? Colors.white : Colors.black;
    final Color selectedFg = isDark ? Colors.black : Colors.white;
    final Color unselectedBg = isDark ? AppColors.inputFill(true) : Colors.white;
    final Color unselectedFg = isDark ? Colors.white : Colors.black;
    final Color unselectedBorder = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return GestureDetector( /* ... GestureDetector setup ... */
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBg : unselectedBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow( color: selectedBg.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text( title, style: TextStyle( fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? selectedFg : unselectedFg)),
            ),
            if (isSelected) Icon(Icons.check_circle, color: selectedFg, size: 20),
            if (!isSelected) Container(
              width: 20, height: 20,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: unselectedBorder, width: 2)),
            )
          ],
        ),
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
    // ... TextField implementation ...
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
        border: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: focusedBorderColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) { return 'This field is required'; }
        if (keyboardType == TextInputType.number || keyboardType == const TextInputType.numberWithOptions(decimal: true)) {
          final number = double.tryParse(value);
          if (number == null || number <= 0) { return 'Please enter a valid positive number'; }
        }
        return null;
      },
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    // Updated: Last input step is now 3
    final bool isLastInputStep = _currentPage == 3;
    final Color primaryButtonBg = isDark ? Colors.white : Colors.black;
    final Color primaryButtonFg = isDark ? Colors.black : Colors.white;
    final Color secondaryButtonBorder = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Container( /* ... Decoration ... */
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded( /* ... Back Button ... */
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
              // --- UPDATE: Call _calculateCalories on the last step (Weight Unit page) ---
              onPressed: _isLoading && isLastInputStep
                  ? null
                  : (isLastInputStep ? _calculateCalories : _nextPage), // Directly call _calculateCalories
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonBg, foregroundColor: primaryButtonFg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: _isLoading && isLastInputStep // Show loading only when calculating
                  ? Row( /* ... Loading Indicator ... */
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
    // ... Results Page implementation (mostly the same) ...
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color cardBg = isDark ? AppColors.darkCardBackground : Colors.white;

    if (_result == null) {
      // Show loading indicator *while* calculating (controlled by _isLoading)
      // Or just an empty container if _isLoading is false but _result is still null (e.g., initial state)
      return Container(
          color: isDark ? Colors.black : Colors.grey[50],
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink()
      );
    }

    // Show results once calculation is done and _result is populated
    return Container(
      color: isDark ? Colors.black : Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // --- Use API result here ---
            _buildResultCard(_result!, isDark, isRecent: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { // Reset logic
                  setState(() {
                    _currentPage = 0; _result = null; _activityController.clear();
                    _durationController.clear(); _weightController.clear();
                    _selectedWeightUnit = 'kg';
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

  // Result Card Widget (Displays API result)
  Widget _buildResultCard(Map<String, dynamic> resultData, bool isDark, {bool isRecent = false}) {
    // ... Result Card implementation ...
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final Color mutedBg = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final Color borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Card( /* ... Card setup ... */
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
            Container( /* ... Calorie Display ... */
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(color: mutedBg, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Column( children: [
                Text('Estimated Calories Burned', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                // --- Use API value ---
                Text(
                    (resultData['estimatedCaloriesBurned'] as double?)?.round().toString() ?? '--', // Handle potential null from API
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryTextColor)
                ),
                Text('kcal', style: TextStyle(color: secondaryTextColor, fontSize: 16)),
              ],),),
            ),
            const SizedBox(height: 16),
            Row( /* ... Explanation Section ... */
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(lucide.LucideIcons.info, size: 16, color: primaryTextColor), const SizedBox(width: 8),
              Expanded(child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Explanation:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primaryTextColor)), const SizedBox(height: 8),
                Container( padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: mutedBg, borderRadius: BorderRadius.circular(8)),
                  // --- Use API value ---
                  child: Text(
                      resultData['explanation'] as String? ?? 'No explanation provided by AI.', // Handle potential null
                      style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.5)
                  ),
                ),
              ],),),
            ],),
          ],
        ),
      ),
    );
  }

} // End of State class

// Removed _BmiCategoryLabel widget