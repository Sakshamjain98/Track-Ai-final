import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_generative_ai/google_generative_ai.dart'; // No longer needed here
// import 'package:http/http.dart' as http; // No longer needed here
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/constants/appcolors.dart';

import '../../settings/service/geminiservice.dart'; // Assuming AppColors is here


// --- AnalysisReport class (keep as is) ---
class AnalysisReport { /* ... same as before ... */
  final String id;
  final DateTime date;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic>? recommendations; // Make recommendations nullable

  AnalysisReport({required this.id, required this.date, required this.metrics, this.recommendations}); // Update constructor

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    return AnalysisReport(
      id: json['id'],
      date: DateTime.parse(json['date']),
      metrics: Map<String, dynamic>.from(json['metrics']),
      // Handle potential null recommendations during loading
      recommendations: json['recommendations'] != null ? Map<String, dynamic>.from(json['recommendations']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'metrics': metrics,
      'recommendations': recommendations, // Store null if not generated yet
    };
  }
}

// --- BodyCompositionAnalyzer Widget ---
class BodyCompositionAnalyzer extends StatefulWidget {
  const BodyCompositionAnalyzer({Key? key}) : super(key: key);

  @override
  State<BodyCompositionAnalyzer> createState() => _BodyCompositionAnalyzerState();
}

class _BodyCompositionAnalyzerState extends State<BodyCompositionAnalyzer> {
  final PageController _pageController = PageController();

  // Controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();

  // State
  int _currentPage = 0;
  String _selectedGender = '';
  String _selectedUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedActivityLevel = ''; // Ensure this is collected
  bool _isAnalyzing = false;

  List<AnalysisReport> _history = [];
  // _currentReport is not strictly needed if we navigate directly
  // AnalysisReport? _currentReport;

  // Options (keep as before)
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
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    // ... dispose controllers ...
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- Data Persistence (_loadHistory, _saveHistory, _deleteReport) ---
  // ... Keep these methods as they are ...
  Future<void> _loadHistory() async { /* ... same ... */
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('analysisHistory') ?? '[]';
    final List<dynamic> historyJson = jsonDecode(historyString);
    setState(() {
      _history = historyJson.map((json) => AnalysisReport.fromJson(json)).toList();
      _history.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    });
  }

  Future<void> _saveHistory() async { /* ... same ... */
    final prefs = await SharedPreferences.getInstance();
    final String historyString = jsonEncode(_history.map((report) => report.toJson()).toList());
    await prefs.setString('analysisHistory', historyString);
  }

  Future<void> _deleteReport(String id) async { /* ... same ... */
    setState(() {
      _history.removeWhere((report) => report.id == id);
    });
    await _saveHistory();
  }

  // --- Navigation & Validation ---
  void _nextPage() { /* ... same ... */
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  void _previousPage() { /* ... same ... */
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  bool _validateCurrentPage() { /* ... same validation logic ... */
    String errorMessage = '';
    switch (_currentPage) {
      case 0: if (_ageController.text.isEmpty || int.tryParse(_ageController.text) == null || int.parse(_ageController.text) <= 0) errorMessage = 'Please enter a valid age.'; break;
      case 1: if (_selectedGender.isEmpty) errorMessage = 'Please select your gender.'; break;
      case 2: if (_selectedUnit.isEmpty) errorMessage = 'Please select a weight unit.'; break;
      case 3: if (_weightController.text.isEmpty || double.tryParse(_weightController.text) == null || double.parse(_weightController.text) <= 0) errorMessage = 'Please enter a valid weight.'; break;
      case 4: if (_selectedHeightUnit.isEmpty) errorMessage = 'Please select a height unit.'; break;
      case 5:
        if (_selectedHeightUnit == 'cm' && (_heightController.text.isEmpty || double.tryParse(_heightController.text) == null || double.parse(_heightController.text) <= 0)) {
          errorMessage = 'Please enter a valid height in cm.';
        } else if (_selectedHeightUnit != 'cm') {
          final feet = int.tryParse(_feetController.text);
          final inches = double.tryParse(_inchesController.text); // Allow decimal for inches
          if (feet == null || feet < 0 || inches == null || inches < 0 || inches >= 12) {
            errorMessage = 'Please enter valid feet (>=0) and inches (0-11.9).';
          }
        }
        break;
      case 6: if (_selectedActivityLevel.isEmpty) errorMessage = 'Please select your activity level.'; break;
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
      return false;
    }
    return true;
  }

  // --- **** CORE LOGIC UPDATED TO CALL GEMINI **** ---
  Future<void> _analyzeBodyComposition() async {
    if (!_validateCurrentPage()) return; // Final validation
    setState(() => _isAnalyzing = true);

    try {
      // --- 1. Gather Inputs ---
      final age = int.parse(_ageController.text);
      final weightInput = double.parse(_weightController.text);
      double heightCm;
      if (_selectedHeightUnit == 'cm') {
        heightCm = double.parse(_heightController.text);
      } else {
        final feet = double.parse(_feetController.text);
        final inches = double.parse(_inchesController.text);
        heightCm = (feet * 30.48) + (inches * 2.54);
      }
      double weightKg = _selectedUnit == 'kg' ? weightInput : weightInput * 0.453592;
      // Map activity level string to a simpler value if needed by API prompt (e.g., 'moderate')
      String activityLevelMapped = _mapActivityLevel(_selectedActivityLevel);


      // --- 2. Call Gemini Service ---
      print('Calling Gemini for Body Comp Analysis...');
      final Map<String, dynamic> aiMetrics = await GeminiService.getBodyCompositionAnalysis(
        age: age,
        gender: _selectedGender.toLowerCase(), // Ensure lowercase
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevelMapped,
      );
      print('Received AI Metrics: $aiMetrics');


      // --- 3. Create Report (without local recommendations initially) ---
      final newReport = AnalysisReport(
          id: DateTime.now().toIso8601String(),
          date: DateTime.now(),
          metrics: aiMetrics, // Use metrics directly from AI
          recommendations: null // Recommendations will be generated on ResultsPage
      );

      // --- 4. Update History and Navigate ---
      setState(() {
        _isAnalyzing = false;
        // _currentReport = newReport; // Not strictly needed
        _history.insert(0, newReport); // Add to history
      });
      await _saveHistory(); // Save updated history

      // Navigate to ResultsPage, passing the AI-generated report
      Navigator.pushReplacement( // Use pushReplacement if you don't want users going back to the input pages
          context,
          MaterialPageRoute(builder: (_) => ResultsPage(
              report: newReport,
              gender: _selectedGender // Pass original gender string for local recommendation logic
          ))
      );

    } catch (e) {
      print("Error in _analyzeBodyComposition (UI): $e");
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Analysis Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.redAccent));
    }
  }

  // Helper to map UI activity level to simpler terms if needed
  String _mapActivityLevel(String uiLevel) {
    switch(uiLevel) {
      case 'Sedentary (little/no exercise)': return 'sedentary';
      case 'Light (1-3 days/week)': return 'light';
      case 'Moderate (3-5 days/week)': return 'moderate';
      case 'Active (6-7 days a week)': return 'active';
      case 'Very Active (very hard exercise)': return 'very_active';
      default: return 'moderate';
    }
  }


  // --- REMOVED _generateRecommendations - This logic moves to ResultsPage ---


  // --- UI Widgets ---
  @override
  Widget build(BuildContext context) {
    // ... The build method using PageView remains the same ...
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar( /* ... AppBar ... */
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            leading: _currentPage == 0
                ? IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20), onPressed: () => Navigator.pop(context))
                : null, // Hide back button on subsequent pages
            title: Text('Body Analysis', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.history, color: isDark ? Colors.white : Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryPage(
                      history: _history,
                      onDelete: _deleteReport,
                    )),
                  ).then((_) => _loadHistory()); // Refresh history on return
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildProgressIndicator(isDark),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildQuestionPage(isDark: isDark, icon: Icons.calendar_today_outlined, title: 'What is your age?', subtitle: 'This helps personalize your analysis', child: _buildTextField(controller: _ageController, hint: 'Enter your age', keyboardType: TextInputType.number, isDark: isDark, maxLength: 3)),
                    _buildQuestionPage(isDark: isDark, icon: Icons.person_outline, title: 'What is your biological gender?', subtitle: 'Gender affects body composition calculations', child: _buildSelectionGroup(_genderOptions, _selectedGender, (val) => setState(() => _selectedGender = val), isDark)),
                    _buildQuestionPage(isDark: isDark, icon: Icons.straighten, title: 'Select weight unit', subtitle: 'Choose your preferred measurement unit', child: _buildSelectionGroup(_unitOptions, _selectedUnit, (val) => setState(() => _selectedUnit = val), isDark)),
                    _buildQuestionPage(isDark: isDark, icon: Icons.monitor_weight_outlined, title: 'What is your weight?', subtitle: 'Enter your current body weight in $_selectedUnit', child: _buildTextField(controller: _weightController, hint: 'Enter weight in $_selectedUnit', keyboardType: const TextInputType.numberWithOptions(decimal: true), isDark: isDark)),
                    _buildQuestionPage(isDark: isDark, icon: Icons.height, title: 'Select height unit', subtitle: 'Choose how you want to enter your height', child: _buildSelectionGroup(_heightUnits, _selectedHeightUnit, (val) {setState(() {_selectedHeightUnit = val; _heightController.clear(); _feetController.clear(); _inchesController.clear();});}, isDark)),
                    _buildHeightPage(isDark),
                    _buildQuestionPage(isDark: isDark, icon: Icons.fitness_center, title: 'Activity level?', subtitle: 'Select your typical weekly exercise routine', child: _buildSelectionGroup(_activityLevels, _selectedActivityLevel, (val) => setState(() => _selectedActivityLevel = val), isDark)),
                  ],
                ),
              ),
              _buildNavigationButtons(isDark), // This now calls _analyzeBodyComposition on the last step
            ],
          ),
        );
      },
    );
  }

  // --- Helper UI Widgets ---
  // _buildProgressIndicator, _buildQuestionPage, _buildSelectionGroup,
  // _buildSelectionCard, _buildHeightPage, _buildTextField, _buildNavigationButtons
  // remain the same as in your provided code. Ensure _buildNavigationButtons
  // calls _analyzeBodyComposition on the last step (_currentPage == 6).
  // ... (Paste the existing UI helper widgets here) ...
  Widget _buildProgressIndicator(bool isDark) { /* ... same ... */
    int totalSteps = 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: index <= _currentPage ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 10),
          Text('Step ${_currentPage + 1} of $totalSteps', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({required bool isDark, required IconData icon, required String title, required String subtitle, required Widget child}) { /* ... same ... */
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(16)), child: Icon(icon, size: 40, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 100), // Space for nav button
        ],
      ),
    );
  }

  Widget _buildSelectionGroup(List<String> options, String selectedValue, Function(String) onSelect, bool isDark) { /* ... same ... */
    return Column(
      children: options.map((option) => _buildSelectionCard(
        title: option,
        isSelected: selectedValue == option,
        onTap: () => onSelect(option),
        isDark: isDark,
      )).toList(),
    );
  }

  Widget _buildSelectionCard({required String title, required bool isSelected, required VoidCallback onTap, required bool isDark}) { /* ... same ... */
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey[900] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.grey[800]! : Colors.grey[300]!), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black)))),
            if (isSelected) Icon(Icons.check_circle, color: isDark ? Colors.black : Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightPage(bool isDark) { /* ... same ... */
    return _buildQuestionPage(
      isDark: isDark,
      icon: Icons.height,
      title: 'What is your height?',
      subtitle: _selectedHeightUnit == 'cm' ? 'Enter your height in centimeters' : 'Enter your height in feet and inches',
      child: _selectedHeightUnit == 'cm'
          ? _buildTextField(controller: _heightController, hint: 'Enter height in cm', keyboardType: TextInputType.number, isDark: isDark)
          : Row(
        children: [
          Expanded(child: _buildTextField(controller: _feetController, hint: 'Feet', keyboardType: TextInputType.number, isDark: isDark)),
          const SizedBox(width: 16),
          Expanded(child: _buildTextField(controller: _inchesController, hint: 'Inches', keyboardType: const TextInputType.numberWithOptions(decimal: true), isDark: isDark)), // Allow decimal inches
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required bool isDark, TextInputType? keyboardType, int? maxLength}) { /* ... same ... */
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: keyboardType == TextInputType.number || keyboardType == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))] // Allow numbers and decimal point
          : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white : Colors.black, width: 2)),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) { /* ... same ... */
    // Calls _analyzeBodyComposition on the last step (_currentPage == 6)
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? Colors.black : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[200]!))),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(onPressed: _previousPage, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Back', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600, fontSize: 16))),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 6 ? (_isAnalyzing ? null : _analyzeBodyComposition) : _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isAnalyzing && _currentPage == 6 // Show loading only on last step during analysis
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.black : Colors.white)))
                  : Text(_currentPage == 6 ? 'Analyze' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

} // End Analyzer State

// --- Results Page (Needs significant modification) ---
class ResultsPage extends StatefulWidget { // Make it StatefulWidget
  final AnalysisReport report;
  final String gender;
  const ResultsPage({Key? key, required this.report, required this.gender}) : super(key: key);

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _showRecommendations = false;
  Map<String, dynamic>? _generatedRecommendations; // Store generated recommendations

  @override
  void initState() {
    super.initState();
    // Initially, recommendations are not generated or shown
    // If the report loaded from history already has recommendations, show them
    if (widget.report.recommendations != null) {
      _generatedRecommendations = widget.report.recommendations;
      _showRecommendations = true;
    }
  }


  // --- Logic to generate recommendations LOCALLY based on AI METRICS ---
  // (Moved from _BodyCompositionAnalyzerState)
  void _generateAndShowRecommendations() {
    Map<String, dynamic> recommendations = {};
    List<String> focus = [];
    List<String> good = [];

    final metrics = widget.report.metrics; // Use metrics from the report

    // --- Analyze AI Metrics ---
    // Use try-catch or null checks for safety as AI might not return all keys
    try {
      double bmi = (metrics['BMI'] as num? ?? 0.0).toDouble();
      double bf = (metrics['Body Fat Percentage'] as num? ?? 0.0).toDouble();
      double vfl = (metrics['Visceral Fat Level'] as num? ?? 0.0).toDouble();
      int? metabolicAge = (metrics['Metabolic Age'] as num?)?.round();
      int? score = (metrics['Body Composition Score'] as num?)?.round();
      double? smm = (metrics['Skeletal Muscle Mass'] as num?)?.toDouble();
      double? bmr = (metrics['BMR'] as num?)?.toDouble();
      double? muscleMass = (metrics['Muscle Mass'] as num?)?.toDouble();
      double? leanMass = (metrics['Lean Mass'] as num?)?.toDouble();
      double? bodyWater = (metrics['Body Water Percentage'] as num?)?.toDouble();
      double? boneMass = (metrics['Bone Mass'] as num?)?.toDouble();
      double? proteinMass = (metrics['Protein Mass'] as num?)?.toDouble();

      // BMI Analysis
      if (bmi > 24.9) { focus.add("BMI\nProblem: Your BMI of ${bmi.toStringAsFixed(1)} falls into the overweight range (Ideal: 18.5-24.9).\nSolution: Focus on a combination of a balanced calorie-controlled diet and regular cardiovascular exercise (e.g., 150 minutes of moderate-intensity activity per week)."); }
      else if (bmi < 18.5) { focus.add("BMI\nProblem: Your BMI of ${bmi.toStringAsFixed(1)} is in the underweight range (Ideal: 18.5-24.9).\nSolution: Consider increasing your intake of nutrient-dense foods and consult with a healthcare provider or dietitian to ensure healthy weight gain."); }
      else { good.add("BMI\nCongratulations! Your BMI of ${bmi.toStringAsFixed(1)} falls within the healthy range of 18.5-24.9. Maintaining a BMI in this range is associated with a lower risk of various health issues."); }

      // Body Fat Analysis
      bool isMale = widget.gender == 'Male';
      double idealBfMax = isMale ? 20.0 : 28.0; // Adjusted ideal ranges slightly
      double idealBfMin = isMale ? 10.0 : 18.0;
      if (bf > idealBfMax) { focus.add("Body Fat Percentage\nProblem: Your body fat percentage of ${bf.toStringAsFixed(1)}% is above the ideal range (${idealBfMin.toStringAsFixed(0)}-${idealBfMax.toStringAsFixed(0)}%).\nSolution: Incorporate more cardiovascular exercise (like running, cycling, swimming) and strength training (2-3 times/week) into your routine, and focus on a balanced diet with adequate protein and controlled calories."); }
      else if (bf < idealBfMin) { focus.add("Body Fat Percentage\nProblem: Your body fat percentage of ${bf.toStringAsFixed(1)}% is below the typical healthy range (${idealBfMin.toStringAsFixed(0)}-${idealBfMax.toStringAsFixed(0)}%).\nSolution: Ensure you are consuming enough healthy fats and overall calories. Consult a healthcare provider if concerned."); }
      else { good.add("Body Fat Percentage\nYour body fat percentage of ${bf.toStringAsFixed(1)}% is within the ideal range of ${idealBfMin.toStringAsFixed(0)}-${idealBfMax.toStringAsFixed(0)}%."); }

      // Visceral Fat Analysis
      if (vfl > 12) { focus.add("Visceral Fat Level\nProblem: Your visceral fat level of ${vfl.toStringAsFixed(0)} is elevated above the ideal range of 1-12.\nSolution: Focus on reducing overall body fat through diet (limit processed foods, sugary drinks) and regular exercise, particularly including 2-3 sessions of High-Intensity Interval Training (HIIT) per week if appropriate for your fitness level."); }
      else if (vfl < 1) { focus.add("Visceral Fat Level\nProblem: Your visceral fat level of ${vfl.toStringAsFixed(0)} is very low. While generally good, extremely low levels can sometimes be indicative of other issues.\nSolution: Ensure adequate intake of essential fats. If concerned, consult a healthcare provider.");} // Added low VFL case
      else { good.add("Visceral Fat Level\nYour visceral fat level of ${vfl.toStringAsFixed(0)} is within the ideal range of 1-12."); }

      // Metabolic Age Analysis (Compare to actual age if available, or just state the value)
      // Assuming age is available from the report or can be calculated if DoB was stored
      // For now, just present the value and general advice.
      if (metabolicAge != null) {
        // You might fetch the user's actual age here if needed for comparison
        focus.add("Metabolic Age\nValue: Your estimated metabolic age is $metabolicAge years.\nSolution: If this is higher than your actual age, prioritize healthy lifestyle choices like regular exercise (both cardio and strength) and a balanced, whole-foods diet to potentially lower your metabolic age over time.");
      } else {
        good.add("Metabolic Age\nYour metabolic age was estimated. Maintaining a healthy lifestyle supports a youthful metabolic rate.");
      }

      // --- Add 'Good' comments for other metrics ---
      if (smm != null) good.add("Skeletal Muscle Mass\nYour skeletal muscle mass is ${smm.toStringAsFixed(1)} kg. Maintaining or gradually increasing it through consistent resistance training (2-3 sessions/week) supports strength, metabolism, and overall health.");
      if (bmr != null) good.add("BMR\nYour BMR is ${bmr.round()} kcal/day. Ensure your daily intake supports this baseline metabolic rate, adjusting for activity. Consult a dietitian for specific needs.");
      if (muscleMass != null) good.add("Muscle Mass\nYour muscle mass is ${muscleMass.toStringAsFixed(1)} kg. Consistent resistance training and adequate protein intake help maintain or increase this, supporting overall health.");
      if (leanMass != null) good.add("Lean Mass\nYour lean mass is ${leanMass.toStringAsFixed(1)} kg. Maintaining or increasing lean mass through adequate protein and resistance training contributes positively to your metabolism.");
      if (bodyWater != null) {
        double minWater = isMale ? 50.0 : 45.0;
        double maxWater = isMale ? 65.0 : 60.0;
        if(bodyWater >= minWater && bodyWater <= maxWater) {
          good.add("Body Water Percentage\nYour body water percentage is ${bodyWater.toStringAsFixed(0)}%. This is within the typical healthy range (${minWater.toStringAsFixed(0)}-${maxWater.toStringAsFixed(0)}% for ${widget.gender}). Stay adequately hydrated.");
        } else if (bodyWater < minWater) {
          focus.add("Body Water Percentage\nProblem: Your body water percentage (${bodyWater.toStringAsFixed(0)}%) is below the typical range (${minWater.toStringAsFixed(0)}-${maxWater.toStringAsFixed(0)}%).\nSolution: Increase your daily water intake significantly. Aim for consistent hydration throughout the day.");
        } else { // bodyWater > maxWater
          focus.add("Body Water Percentage\nProblem: Your body water percentage (${bodyWater.toStringAsFixed(0)}%) is above the typical range (${minWater.toStringAsFixed(0)}-${maxWater.toStringAsFixed(0)}%).\nSolution: While hydration is good, very high levels might indicate fluid retention. Consult a healthcare provider if concerned, and review sodium intake.");
        }
      }
      if (boneMass != null) good.add("Bone Mass\nYour bone mass is ${boneMass.toStringAsFixed(1)} kg. Maintain it through weight-bearing exercises (walking, strength training) and a diet rich in calcium and vitamin D.");
      if (proteinMass != null) good.add("Protein Mass\nYour protein mass is ${proteinMass.toStringAsFixed(1)} kg. Ensure adequate protein intake (e.g., 0.8-1.5g per kg body weight, depending on activity) for muscle repair and overall health.");
      if (score != null) good.add("Body Composition Score\nYour score is $score/100. While not a standalone diagnostic, improving areas like body fat or visceral fat can increase this score over time.");


    } catch (e) {
      print("Error generating recommendations from AI metrics: $e");
      focus.add("Could not fully generate recommendations due to unexpected metric data.");
    }


    // Use the AI's healthIndicator as the overall summary
    recommendations['summary'] = metrics['healthIndicator'] ?? "Analysis complete. Review individual metrics for details.";
    recommendations['focus'] = focus.isNotEmpty ? focus : ["Great job! No major areas need immediate focus based on these key metrics. Maintain your healthy habits!"];
    recommendations['good'] = good.isNotEmpty ? good : ["Continue monitoring your metrics."];

    // Update the state to show the generated recommendations
    setState(() {
      _generatedRecommendations = recommendations;
      _showRecommendations = true;
    });
  }


  // --- Helper to get category (same as before) ---
  String _getCategoryForMetric(String metricName, double value) { /* ... same as before ... */
    switch (metricName) {
      case 'BMI':
        if (value < 18.5) return 'Underweight'; if (value < 25) return 'Normal'; if (value < 30) return 'Overweight'; return 'Obese';
      case 'Body Fat Percentage':
        bool isMale = widget.gender == 'Male';
        double athMax = isMale ? 14.0 : 20.0; // Adjusted athletic ranges
        double goodMax = isMale ? 20.0 : 28.0; // Adjusted good ranges
        if (value < athMax) return 'Athletic'; if (value < goodMax) return 'Good'; return 'Excess';
    // --- Keep 'Subcutaneous Fat' if AI returns it ---
    // case 'Subcutaneous Fat':
    //   bool isMale = widget.gender == 'Male';
    //   double goodMax = isMale ? 16.0 : 22.0;
    //   if (value < goodMax) return 'Good'; return 'Excess';
      case 'Visceral Fat Level':
        if (value < 10) return 'Healthy'; if (value < 13) return 'Acceptable'; if (value < 16) return 'High'; return 'Very High'; // Refined VFL categories
      case 'Body Water Percentage':
        bool isMale = widget.gender == 'Male';
        double minWater = isMale ? 50.0 : 45.0;
        double maxWater = isMale ? 65.0 : 60.0;
        if (value < minWater) return 'Low'; if (value < maxWater) return 'Normal'; return 'High';
    // --- Add categories for other metrics if desired, otherwise default ---
      case 'Metabolic Age': return 'Value'; // Just show the value
      case 'Body Composition Score': return 'Score'; // Just show the score
      default: return 'Value'; // Default category if none specific apply
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar( /* ... AppBar ... */
        title: Text('Analysis Results', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card (uses AI metric)
            Container( /* ... Score Card Decoration ... */
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
              child: Column(
                children: [
                  Text('Body Score', style: TextStyle(fontSize: 16, color: secondaryTextColor)), // Renamed for clarity
                  const SizedBox(height: 16),
                  Text(
                      '${(widget.report.metrics['Body Composition Score'] as num?)?.round() ?? '--'}', // Use AI Score
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: primaryTextColor)
                  ),
                  Text('out of 100', style: TextStyle(fontSize: 14, color: secondaryTextColor.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Key Metrics Section (uses AI metrics)
            Text('Key Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
            const SizedBox(height: 16),
            ...widget.report.metrics.entries
                .where((e) => e.key != 'Body Composition Score' && e.key != 'healthIndicator') // Filter out score & summary
                .map((entry) {
              // Safely attempt to convert value to double for category check
              double? metricValue = (entry.value as num?)?.toDouble();
              String category = metricValue != null ? _getCategoryForMetric(entry.key, metricValue) : 'N/A';
              return _buildMetricCard( entry.key, entry.value, category, isDark );
            }),
            const SizedBox(height: 32),

            // --- Recommendation Section (Conditional Display) ---
            if (!_showRecommendations)
              Center( // Center the button
                child: ElevatedButton.icon(
                  icon: Icon(lucide.LucideIcons.brainCircuit, size: 18), // AI icon
                  label: Text('Get AI Recommendations'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDark ? Colors.black : Colors.white, backgroundColor: isDark ? Colors.white : Colors.black, // Contrasting colors
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _generateAndShowRecommendations, // Trigger local generation
                ),
              )
            else if (_generatedRecommendations != null) ...[ // Use else if to ensure it exists
              Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryTextColor)),
              const SizedBox(height: 16),
              _buildRecommendationCard(
                  'Overall Recommendation',
                  _generatedRecommendations!['summary'] ?? 'No summary available.', // Use AI summary
                  Icons.article_outlined, // More appropriate icon
                  Colors.blueAccent, // Consistent color
                  isDark
              ),
              _buildRecommendationCard(
                  'Areas for Focus',
                  (_generatedRecommendations!['focus'] as List<dynamic>?)?.map((item) => "- $item").join('\n\n') ?? 'None specified.', // Format list
                  Icons.track_changes_outlined, // More appropriate icon
                  Colors.orangeAccent, // Consistent color
                  isDark
              ),
              _buildRecommendationCard(
                  "What's Going Well",
                  (_generatedRecommendations!['good'] as List<dynamic>?)?.map((item) => "- $item").join('\n\n') ?? 'Keep monitoring.', // Format list
                  Icons.check_circle_outline, // More appropriate icon
                  Colors.green, // Consistent color
                  isDark
              ),
            ] else // Case where generation might fail unexpectedly
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                    "Could not generate recommendations at this time.",
                    style: TextStyle(color: Colors.redAccent)
                ),
              ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets (_buildMetricCard, _buildRecommendationCard) ---
  // Keep these mostly the same, ensure they handle the data types correctly
  Widget _buildMetricCard(String title, dynamic value, String category, bool isDark) { /* ... same as before ... */
    Color categoryColor = Colors.grey; // Default
    Color categoryTextColor = isDark ? Colors.black : Colors.white; // Default text on grey

    // Define colors based on category - refine these as needed
    switch(category.toLowerCase()) {
      case 'underweight': categoryColor = Colors.blueAccent; categoryTextColor = Colors.white; break;
      case 'normal':
      case 'good':
      case 'healthy':
      case 'athletic':
      case 'value':
      case 'score': categoryColor = Colors.green; categoryTextColor = Colors.white; break;
      case 'overweight':
      case 'acceptable':
      case 'low': categoryColor = Colors.orangeAccent; categoryTextColor = Colors.black; break;
      case 'obese':
      case 'excess':
      case 'high':
      case 'very high': categoryColor = Colors.redAccent; categoryTextColor = Colors.white; break;
      default: categoryColor = isDark ? Colors.grey[700]! : Colors.grey[300]!; categoryTextColor = isDark ? Colors.white : Colors.black; break; // Use subtle grey for unknown/default
    }


    // Format value: Show 1 decimal for doubles, 0 for integers/levels
    String valueString = (value is double && !['Metabolic Age', 'Visceral Fat Level', 'Body Composition Score'].contains(title))
        ? value.toStringAsFixed(1)
        : (value as num?)?.round().toString() ?? '--'; // Handle null or non-num


    // Updated unit map - ensure keys match PascalCase from AI
    String unit = {
      'Body Weight': 'kg',
      'Body Fat Percentage': '%',
      'Body Water Percentage': '%',
      //'Subcutaneous Fat': '%', // Keep if AI returns it
      'Skeletal Muscle Mass': 'kg',
      'Muscle Mass': 'kg',
      'Lean Mass': 'kg',
      'Body Fat Mass': 'kg',
      'Bone Mass': 'kg',
      'Water Mass': 'kg',
      'Protein Mass': 'kg',
      'BMR': 'kcal/day',
      'Metabolic Age': 'years',
      'Visceral Fat Level': '', // No unit, just level
      'BMI': '', // No unit
    }[title] ?? '';

    return Container( /* ... Decoration ... */
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3, // Give more space to title/category
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (category != 'Value' && category != 'Score' && category != 'N/A') // Only show category chip if meaningful
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(8)), // Use direct color
                    child: Text(category, style: TextStyle(color: categoryTextColor, fontSize: 11, fontWeight: FontWeight.bold))), // Use contrasting text
            ]),
          ),
          const SizedBox(width: 10),
          Expanded( // Value and unit
            flex: 2,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align value to the right
                crossAxisAlignment: CrossAxisAlignment.baseline, // Align baseline of value and unit
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible( // Allow value to wrap if extremely long (unlikely)
                    child: Text(
                      valueString,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold), // Slightly smaller value text
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 4), child: Text(unit, style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500], fontSize: 12))),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String content, IconData icon, Color color, bool isDark) { /* ... same as before ... */
    // Improved formatting for lists within the content
    content = content.replaceAll('- ', '\n • ').trim(); // Add bullet points

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ]),
        const SizedBox(height: 12),
        Text(content, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.6)), // Increased line height
      ]),
    );
  }

}


// History Page (keep as is)
class HistoryPage extends StatefulWidget { /* ... same ... */
  final List<AnalysisReport> history;
  final Function(String) onDelete;
  const HistoryPage({Key? key, required this.history, required this.onDelete}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}
class _HistoryPageState extends State<HistoryPage> { /* ... same state and methods ... */
  List<String> _selectedIds = [];

  void _toggleSelection(String id) { /* ... same ... */
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select up to 2 reports to compare.'), backgroundColor: Colors.orangeAccent));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) { /* ... same build method ... */
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Analysis History', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          if (_selectedIds.length == 2) IconButton(
            icon: Icon(Icons.compare_arrows, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              final report1 = widget.history.firstWhere((r) => r.id == _selectedIds[0]);
              final report2 = widget.history.firstWhere((r) => r.id == _selectedIds[1]);
              // --- Ensure Gender is passed if ComparisonPage needs it ---
              String gender1 = report1.metrics['gender'] == 'female' ? 'Female' : 'Male'; // Determine gender from metrics
              Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonPage(
                report1: report1.date.isBefore(report2.date) ? report1 : report2,
                report2: report1.date.isAfter(report2.date) ? report1 : report2,
                // gender: gender1, // Pass gender if ComparisonPage needs it for category display
              )));
            },
          )
        ],
      ),
      body: widget.history.isEmpty
          ? Center(child: Text('No history found.', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.history.length,
        itemBuilder: (context, index) {
          final report = widget.history[index];
          final isSelected = _selectedIds.contains(report.id);
          return GestureDetector(
            onTap: () {
              // Determine gender from metrics for ResultsPage
              String gender = report.metrics['gender'] == 'female' ? 'Female' : 'Male';
              Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsPage(report: report, gender: gender)));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: isSelected ? Colors.blue.withOpacity(0.1) : (isDark ? Colors.grey[900] : Colors.grey[50]), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.blue : (isDark ? Colors.grey[800]! : Colors.grey[200]!))),
              child: Row(
                children: [
                  Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(report.id)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat('MMM d, yyyy - h:mm a').format(report.date), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      Text('Score: ${report.metrics['Body Composition Score'] ?? '--'}', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])), // Use AI Score
                    ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: Text('Delete Report?'),
                        content: Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                          TextButton(onPressed: () { widget.onDelete(report.id); setState((){ _selectedIds.remove(report.id); }); Navigator.pop(ctx); }, child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Comparison Page (keep as is)
class ComparisonPage extends StatelessWidget { /* ... same ... */
  final AnalysisReport report1;
  final AnalysisReport report2;
  // final String gender; // Add gender if needed for categories

  const ComparisonPage({Key? key, required this.report1, required this.report2 /*, required this.gender*/}) : super(key: key);

  @override
  Widget build(BuildContext context) { /* ... same build method ... */
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final allKeys = (report1.metrics.keys.toList()..addAll(report2.metrics.keys.toList()))
        .toSet()
        .where((key) => key != 'healthIndicator' && report1.metrics[key] is num && report2.metrics[key] is num)
        .toList();
    allKeys.sort((a, b) => a.compareTo(b));

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Comparison', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(flex: 3, child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                Expanded(flex: 2, child: Text(DateFormat('MMM d').format(report1.date), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                Expanded(flex: 2, child: Text(DateFormat('MMM d').format(report2.date), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                Expanded(flex: 2, child: Text('Change', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
              ]),
            ),
            const SizedBox(height: 8),
            // Metric Rows
            ...allKeys.map((key) => _buildComparisonRow(key, report1.metrics[key], report2.metrics[key], isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String metric, dynamic val1, dynamic val2, bool isDark) { /* ... same ... */
    final v1 = (val1 as num).toDouble();
    final v2 = (val2 as num).toDouble();
    final diff = v2 - v1;
    bool isImprovement = (metric.contains('Fat') || metric.contains('BMI') || metric.contains('Age') || metric.contains('Level')) ? diff < 0 : diff > 0;
    Color diffColor = diff == 0 ? (isDark ? Colors.grey[400]! : Colors.grey[600]!) : (isImprovement ? Colors.green : Colors.red);
    IconData diffIcon = diff == 0 ? Icons.remove : (diff > 0 ? Icons.arrow_upward : Icons.arrow_downward);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(metric, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black))),
          Expanded(flex: 2, child: Text(v1.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          Expanded(flex: 2, child: Text(v2.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          Expanded( flex: 2, child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(diffIcon, color: diffColor, size: 14), const SizedBox(width: 4),
            Text(diff.abs().toStringAsFixed(1), style: TextStyle(color: diffColor, fontWeight: FontWeight.bold)), // Show absolute difference
          ],),
          ),
        ],
      ),
    );
  }
}