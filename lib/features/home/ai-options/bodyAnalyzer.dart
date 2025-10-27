import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/home/ai-options/service/Resulltpage.dart';
import 'dart:typed_data';
import '../../settings/service/geminiservice.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// For web PDF download
import 'package:universal_html/html.dart' as html;

// --- AnalysisReport class ---
class AnalysisReport {
  final String id;
  final DateTime date;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic>? recommendations;

  AnalysisReport({
    required this.id,
    required this.date,
    required this.metrics,
    this.recommendations,
  });

  factory AnalysisReport.fromJson(Map<String, dynamic> json) {
    return AnalysisReport(
      id: json['id'],
      date: DateTime.parse(json['date']),
      metrics: Map<String, dynamic>.from(json['metrics']),
      recommendations: json['recommendations'] != null
          ? Map<String, dynamic>.from(json['recommendations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'metrics': metrics,
      'recommendations': recommendations,
    };
  }
}

class BodyCompositionAnalyzer extends StatefulWidget {
  const BodyCompositionAnalyzer({Key? key}) : super(key: key);

  @override
  State<BodyCompositionAnalyzer> createState() => _BodyCompositionAnalyzerState();
}

class _BodyCompositionAnalyzerState extends State<BodyCompositionAnalyzer> {
  final PageController _pageController = PageController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();

  int _currentPage = 0;
  String _selectedGender = '';
  String _selectedUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedActivityLevel = '';
  bool _isAnalyzing = false;
  List<AnalysisReport> _history = [];

  final List<String> _genderOptions = ['Male', 'Female','Other'];
  final List<String> _unitOptions = ['kg', 'lbs'];
  final List<String> _heightUnits = ['cm', 'ft/in'];
  final List<String> _activityLevels = [
    'Light (1-3 days/week)',
    'Moderate (3-5 days/week)',
    'Active (6-7 days a week)',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

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

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('analysisHistory') ?? '[]';
    final List<dynamic> historyJson = jsonDecode(historyString);
    setState(() {
      _history = historyJson.map((json) => AnalysisReport.fromJson(json)).toList();
      _history.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyString = jsonEncode(_history.map((report) => report.toJson()).toList());
    await prefs.setString('analysisHistory', historyString);
  }

  Future<void> _deleteReport(String id) async {
    setState(() {
      _history.removeWhere((report) => report.id == id);
    });
    await _saveHistory();
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- REVERTED/UPDATED: Validation Logic for 5 Steps ---
  bool _validateCurrentPage() {
    String errorMessage = '';
    switch (_currentPage) {
      case 0: // Gender (New Step 0)
        if (_selectedGender.isEmpty) errorMessage = 'Please select your gender.';
        break;
      case 1: // Age (New Step 1)
        if (_ageController.text.isEmpty ||
            int.tryParse(_ageController.text) == null ||
            int.parse(_ageController.text) <= 0) {
          errorMessage = 'Please enter a valid age.';
        }
        break;
      case 2: // Weight Unit & Input (New Step 2)
        if (_selectedUnit.isEmpty) errorMessage = 'Please select a weight unit.';
        if (_weightController.text.isEmpty ||
            double.tryParse(_weightController.text) == null ||
            double.parse(_weightController.text) <= 0) {
          errorMessage = 'Please enter a valid weight in $_selectedUnit.';
        }
        break;
      case 3: // Height Unit & Input (New Step 3)
        if (_selectedHeightUnit.isEmpty) errorMessage = 'Please select a height unit.';
        if (_selectedHeightUnit == 'cm' &&
            (_heightController.text.isEmpty ||
                double.tryParse(_heightController.text) == null ||
                double.parse(_heightController.text) <= 0)) {
          errorMessage = 'Please enter a valid height in cm.';
        } else if (_selectedHeightUnit != 'cm') {
          final feet = int.tryParse(_feetController.text);
          final inches = double.tryParse(_inchesController.text);
          if (feet == null || feet < 0 || inches == null || inches < 0 || inches >= 12) {
            errorMessage = 'Please enter valid feet (>=0) and inches (0-11.9).';
          }
        }
        break;
      case 4: // Activity Level (New Step 4)
        if (_selectedActivityLevel.isEmpty) errorMessage = 'Please select your activity level.';
        break;
    }

    if (errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent)
      );
      return false;
    }
    return true;
  }

  Future<void> _analyzeBodyComposition() async {
    // Check validation on the last page (Step 4, which is index 4)
    if (!_validateCurrentPage()) return;
    setState(() => _isAnalyzing = true);

    try {
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
      String activityLevelMapped = _mapActivityLevel(_selectedActivityLevel);

      final Map<String, dynamic> aiMetrics = await GeminiService.getBodyCompositionAnalysis(
        age: age,
        gender: _selectedGender.toLowerCase(),
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevelMapped,
      );

      final newReport = AnalysisReport(
          id: DateTime.now().toIso8601String(),
          date: DateTime.now(),
          metrics: aiMetrics,
          recommendations: null
      );

      setState(() {
        _isAnalyzing = false;
        _history.insert(0, newReport);
      });
      await _saveHistory();

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultsPage(
              report: newReport,
              gender: _selectedGender
          ))
      );

    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Analysis Failed: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.redAccent
      ));
    }
  }

  String _mapActivityLevel(String uiLevel) {
    switch(uiLevel) {
      case 'Light (1-3 days/week)': return 'light';
      case 'Moderate (3-5 days/week)': return 'moderate';
      case 'Active (6-7 days a week)': return 'active';
      default: return 'moderate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            leading: _currentPage == 0
                ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : Colors.black,
                    size: 20),
                onPressed: () => Navigator.pop(context))
                : null,
            title: Text('Body Analysis',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600
                )),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryPage(
                      history: _history,
                      onDelete: _deleteReport,
                    )),
                  ).then((_) => _loadHistory());
                },
                child: Text(
                  'History',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
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
                    // Step 0: Gender (NEW STARTING PAGE)
                    _buildGenderPage(isDark),

                    // Step 1: Age
                    _buildQuestionPage(
                        isDark: isDark,
                        title: 'How old are you?',
                        subtitle: 'This helps personalize your analysis',
                        child: _buildTextField(
                            controller: _ageController,
                            hint: 'Enter your age',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            maxLength: 3
                        )
                    ),

                    // Step 2: Weight
                    _buildWeightPage(isDark),

                    // Step 3: Height
                    _buildHeightPage(isDark),

                    // Step 4: Activity Level
                    _buildQuestionPage(
                        isDark: isDark,
                        title: 'Activity level?',
                        subtitle: 'Select your typical weekly exercise routine',
                        child: _buildSelectionGroup(_activityLevels, _selectedActivityLevel,
                                (val) => setState(() => _selectedActivityLevel = val), isDark)
                    ),
                  ],
                ),
              ),
              _buildNavigationButtons(isDark),
            ],
          ),
        );
      },
    );
  }

  // --- UPDATED: _buildProgressIndicator to reflect 5 steps ---
  Widget _buildProgressIndicator(bool isDark) {
    int totalSteps = 5; // <--- CHANGE: Total steps is now 5
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Left-align for progress text
        children: [
          Row(
            children: List.generate(totalSteps, (index) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: index <= _currentPage ?
                  (isDark ? Colors.white : Colors.black) :
                  (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 10),
          Text('Step ${_currentPage + 1} of $totalSteps',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13
              )),
        ],
      ),
    );
  }

  // --- _buildQuestionPage (left-aligned) ---
  Widget _buildQuestionPage({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(title,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]
              )),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- NEW: _buildGenderPage (as requested) ---
  Widget _buildGenderPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What\'s your gender?',
      subtitle: 'This provides more accurate body composition recommendations.',
      child: Column(
        children: _genderOptions.map((gender) {
          IconData icon;
          switch (gender) {
            case 'Male':
              icon = Icons.male;
              break;
            case 'Female':
              icon = Icons.female;
              break;
            default:
              icon = Icons.transgender;
          }
          return _buildSelectionCard(
            title: gender,
            isSelected: _selectedGender == gender,
            onTap: () {
              setState(() {
                _selectedGender = gender;
              });
            },
            isDark: isDark,
            icon: icon, // Passed to the updated _buildSelectionCard
          );
        }).toList(),
      ),
    );
  }

  // --- NEW: _buildWeightPage (Combined Unit Selector + Input) ---
  Widget _buildWeightPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your weight?',
      subtitle: 'Select your preferred unit and enter your weight.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight Unit Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: _unitOptions.map((option) =>
                  _buildSelectionCard(
                    title: option == 'kg' ? 'Kilograms (kg)' : 'Pounds (lbs)',
                    isSelected: _selectedUnit == option,
                    onTap: () => setState(() => _selectedUnit = option),
                    isDark: isDark,
                    isUnitSelector: true,
                  )
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Weight Input Field
          _buildTextField(
            controller: _weightController,
            hint: 'Enter weight in $_selectedUnit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- NEW: _buildHeightPage (Combined Unit Selector + Input) ---
  Widget _buildHeightPage(bool isDark) {
    return _buildQuestionPage(
      isDark: isDark,
      title: 'What is your height?',
      subtitle: 'Select your preferred unit and enter your height.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Height Unit Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[200],
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: _heightUnits.map((option) =>
                  _buildSelectionCard(
                    title: option == 'cm' ? 'Centimeters (cm)' : 'Feet/Inches (ft/in)',
                    isSelected: _selectedHeightUnit == option,
                    onTap: () {
                      setState(() {
                        _selectedHeightUnit = option;
                        _heightController.clear();
                        _feetController.clear();
                        _inchesController.clear();
                      });
                    },
                    isDark: isDark,
                    isUnitSelector: true,
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

  Widget _buildSelectionGroup(
      List<String> options,
      String selectedValue,
      Function(String) onSelect,
      bool isDark
      ) {
    // This is primarily used for the Activity Level page now.
    return Column(
      children: options.map((option) => _buildSelectionCard(
        title: option,
        isSelected: selectedValue == option,
        onTap: () => onSelect(option),
        isDark: isDark,
        icon: Icons.fitness_center_outlined, // Default icon for activity level
      )).toList(),
    );
  }

  // --- UPDATED: _buildSelectionCard to accept an IconData ---
  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isUnitSelector = false,
    IconData? icon, // NEW: Optional icon parameter
  }) {
    // Unit Selector Style (used for Weight and Height pages)
    if (isUnitSelector) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, // Only color the selected part
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Gender/Activity Selector Style (as requested)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ?
          (isDark ? Colors.white : Colors.black) :
          (isDark ? Colors.grey[900] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ?
              (isDark ? Colors.white : Colors.black) :
              (isDark ? Colors.grey[800]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1
          ),
        ),
        child: Row(
          children: [
            if (icon != null) // Display icon if provided
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(icon,
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white : Colors.black),
                    size: 24
                ),
              ),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ?
                      (isDark ? Colors.black : Colors.white) :
                      (isDark ? Colors.white : Colors.black)
                  )),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: isDark ? Colors.black : Colors.white,
                  size: 22
              ),
          ],
        ),
      ),
    );
  }


  // --- _buildTextField (Required helper method) ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int? maxLength
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: keyboardType == TextInputType.number ||
          keyboardType == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
          : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        counterText: '',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!
            )
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: isDark ? Colors.white : Colors.black,
                width: 2
            )
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  // --- UPDATED: Navigation Buttons Logic for 5 Steps ---
  Widget _buildNavigationButtons(bool isDark) {
    int totalSteps = 5; // <--- Use new step count
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border(
              top: BorderSide(color: isDark ? Colors.grey[900]! : Colors.grey[200]!)
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
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)
                      )
                  ),
                  child: Text('Back',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16
                      )
                  )
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == totalSteps - 1 ? // Check against 4 (0-indexed)
              (_isAnalyzing ? null : _analyzeBodyComposition) : _nextPage,
              style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                  )
              ),
              child: _isAnalyzing && _currentPage == totalSteps - 1
                  ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : Colors.white
                      )
                  )
              )
                  : Text(
                  _currentPage == totalSteps - 1 ? 'Analyze' : 'Continue', // Check against 4 (0-indexed)
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
}
// History Page
class HistoryPage extends StatefulWidget {
  final List<AnalysisReport> history;
  final Function(String) onDelete;
  const HistoryPage({Key? key, required this.history, required this.onDelete}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<String> _selectedIds = [];

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Select up to 2 reports to compare.'),
                  backgroundColor: Colors.orangeAccent
              )
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Analysis History',
            style: TextStyle(color: isDark ? Colors.white : Colors.black)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          if (_selectedIds.length == 2)
            TextButton(
              onPressed: () {
                final report1 = widget.history.firstWhere((r) => r.id == _selectedIds[0]);
                final report2 = widget.history.firstWhere((r) => r.id == _selectedIds[1]);
                final olderReport = report1.date.isBefore(report2.date) ? report1 : report2;
                final newerReport = report1.date.isAfter(report2.date) ? report1 : report2;

                Navigator.push(context, MaterialPageRoute(builder: (_) => ComparisonPage(
                  report1: olderReport,
                  report2: newerReport,
                )));
              },
              child: Text(
                'Compare',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
        ],
      ),
      body: widget.history.isEmpty
          ? Center(
          child: Text('No history found.',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600]
              )
          )
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.history.length,
        itemBuilder: (context, index) {
          final report = widget.history[index];
          final isSelected = _selectedIds.contains(report.id);
          return GestureDetector(
            onTap: () {
              String gender = report.metrics['gender'] == 'female' ? 'Female' : 'Male';
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResultsPage(
                      report: report,
                      gender: gender
                  ))
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: isSelected ?
                  Colors.blue.withOpacity(0.1) :
                  (isDark ? Colors.grey[900] : Colors.grey[50]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isSelected ?
                      Colors.blue :
                      (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                  )
              ),
              child: Row(
                children: [
                  Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(report.id)
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            DateFormat('MMM d, yyyy - h:mm a').format(report.date),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black
                            )
                        ),
                        Text(
                            'Score: ${report.metrics['Body Composition Score'] ?? '--'}',
                            style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600]
                            )
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Delete Report?'),
                            content: Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel')
                              ),
                              TextButton(
                                  onPressed: () {
                                    widget.onDelete(report.id);
                                    setState((){
                                      _selectedIds.remove(report.id);
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: Text('Delete',
                                      style: TextStyle(color: Colors.red)
                                  )
                              ),
                            ],
                          )
                      );
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
// The rest of the file and classes above ComparisonPage remain unchanged.

class ComparisonPage extends StatelessWidget {
  final AnalysisReport report1;
  final AnalysisReport report2;

  const ComparisonPage({
    Key? key,
    required this.report1,
    required this.report2,
  }) : super(key: key);

  // Helper method to format metric names for better readability
  String _formatMetricName(String metric) {
    final Map<String, String> metricNames = {
      'bmi': 'BMI',
      'bmr': 'BMR',
      'bodyFat': 'Body Fat %',
      'visceralFat': 'Visceral Fat',
      'muscleMass': 'Muscle Mass',
      'boneMass': 'Bone Mass',
      'water': 'Water %',
      'protein': 'Protein %',
    };

    return metricNames[metric.toLowerCase()] ?? metric;
  }

  // --- PDF Generation (Only relevant color section is updated for black text) ---
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    final String date1 = formatter.format(report1.date);
    final String date2 = formatter.format(report2.date);

    final allKeys = (report1.metrics.keys.toSet()
      ..addAll(report2.metrics.keys.toSet()))
        .where((key) =>
    key != 'healthIndicator' && report1.metrics[key] is num &&
        report2.metrics[key] is num)
        .toList();
    allKeys.sort((a, b) => a.compareTo(b));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Body Composition Analysis',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black, // FORCED BLACK
                    ),
                  ),
                  pw.Text(
                    'Comparison Report',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700, // Dark Gray
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Report Dates
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('First Report',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColors.black // FORCED BLACK
                              )
                          ),
                          pw.Text(date1, style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.black)),
                          // FORCED BLACK
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        // Changed background from black to light gray for text visibility
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Second Report',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColors.black // FORCED BLACK
                              )
                          ),
                          pw.Text(date2, style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.black)),
                          // FORCED BLACK
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Comparison Table Title
              pw.Text(
                'Body Metrics Comparison',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black, // FORCED BLACK
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header Row (Text is already bold and assumed readable on grey300)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text('METRIC',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.black // FORCED BLACK
                            )
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(date1,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.black // FORCED BLACK
                            ),
                            textAlign: pw.TextAlign.center
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(date2,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.black // FORCED BLACK
                            ),
                            textAlign: pw.TextAlign.center
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text('CHANGE',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                                color: PdfColors.black // FORCED BLACK
                            ),
                            textAlign: pw.TextAlign.center
                        ),
                      ),
                    ],
                  ),

                  // Data Rows
                  ...allKeys.map((metric) {
                    final val1 = report1.metrics[metric] as num;
                    final val2 = report2.metrics[metric] as num;
                    final diff = val2.toDouble() - val1.toDouble();

                    String diffString;
                    PdfColor diffColor;

                    if (diff == 0) {
                      diffString = '0.0';
                      diffColor = PdfColors.grey600;
                    } else {
                      diffString = diff > 0
                          ? '+${diff.toStringAsFixed(1)}'
                          : diff.toStringAsFixed(1);

                      bool isDecreaseGood = metric.contains('Fat') ||
                          metric.contains('BMI') ||
                          metric.contains('Age') ||
                          metric.contains('Level');
                      bool isImprovement = (diff < 0 && isDecreaseGood) ||
                          (diff > 0 && !isDecreaseGood);
                      // KEEPING RED/GREEN FOR CHANGE VALUE, but making them strong
                      diffColor =
                      isImprovement ? PdfColors.green : PdfColors.red;
                    }

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text(_formatMetricName(metric),
                              style: const pw.TextStyle(fontSize: 10,
                                  color: PdfColors.black) // FORCED BLACK
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text(val1.toStringAsFixed(1),
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.black),
                              // FORCED BLACK
                              textAlign: pw.TextAlign.center
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text(val2.toStringAsFixed(1),
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.black),
                              // FORCED BLACK
                              textAlign: pw.TextAlign.center
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text(diffString,
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  color: diffColor // KEEPING RED/GREEN HERE
                              ),
                              textAlign: pw.TextAlign.center
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 30),

              // Summary Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black, // FORCED BLACK
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'This comparison shows your body composition changes between $date1 and $date2. '
                          'Track your progress and consult with healthcare professionals for personalized advice.',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.black), // FORCED BLACK
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Footer (Keeping original dark/grey colors as they are secondary info)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Generated by TrackAI - Body Composition Analyzer',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on ${DateFormat('MMM d, yyyy HH:mm').format(
                          DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- NEW: View/Share PDF Function (Unchanged) ---
  Future<void> _viewOrSharePdf(BuildContext context) async {
    try {
      // 1. Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 2. Generate PDF Bytes
      final pdfBytes = await _generatePdf();
      final fileName = 'body_comparison_report.pdf';

      if (kIsWeb) {
        // 3a. Web: Create a blob and open it in a new tab for viewing
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Open in a new tab for viewing/printing
        html.window.open(url, '_blank');

        // Clean up
        html.Url.revokeObjectUrl(url);

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report opened in a new tab for viewing/printing.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 3b. Mobile/Desktop: Save temporarily and use Share dialog
        Directory? tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          // Use share_plus to open the native share sheet
          await Share.shareXFiles([XFile(file.path)],
              subject: 'Body Composition Comparison Report',
              text: 'Here is my body composition comparison report from TrackAI.');
        }

        // Clean up the temporary file (optional but good practice)
        await file.delete();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('PDF View/Share Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    // 🎯 FORCING ALL PRIMARY/SECONDARY TEXT TO BLACK/DARK GRAY
    final primaryColor = Colors.black;
    final secondaryColor = Colors.grey[800]!;
    final tertiaryColor = Colors.grey[700]!;

    final allKeys = (report1.metrics.keys.toSet()
      ..addAll(report2.metrics.keys.toSet()))
        .where((key) =>
    key != 'healthIndicator' &&
        report1.metrics[key] is num &&
        report2.metrics[key] is num)
        .toList();
    allKeys.sort((a, b) => a.compareTo(b));

    return Scaffold(
      // Keep background dynamic, but force text to contrast
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Comparison',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: primaryColor),
            onPressed: () => _viewOrSharePdf(context),
            tooltip: 'View and Share PDF Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Metric',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('MMM d').format(report1.date),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('MMM d').format(report2.date),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Change',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Metric Rows
            ...allKeys.map((key) =>
                _buildComparisonRow(
                  key,
                  report1.metrics[key],
                  report2.metrics[key],
                  isDark,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                )),

            const SizedBox(height: 30),

            // Footer note
            Text(
              'Comparing reports from ${DateFormat('MMM d, yyyy').format(
                  report1.date)} and ${DateFormat('MMM d, yyyy').format(
                  report2.date)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: tertiaryColor, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Download PDF Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () => _viewOrSharePdf(context),
                icon: Icon(Icons.visibility, color: Colors.white),
                label: Text(
                  'View / Share PDF Report',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Inside the ComparisonPage class

  Widget _buildComparisonRow(String metric, dynamic val1, dynamic val2,
      bool isDark, {
        required Color primaryColor,
        required Color secondaryColor,
      }) {
    if (val1 is! num || val2 is! num) return const SizedBox.shrink();

    final v1 = val1.toDouble();
    final v2 = val2.toDouble();
    final diff = v2 - v1;

    bool isDecreaseGood = metric.contains('Fat') ||
        metric.contains('BMI') ||
        metric.contains('Age') ||
        metric.contains('Level');

    bool isImprovement = (diff < 0 && isDecreaseGood) ||
        (diff > 0 && !isDecreaseGood);

    Color diffColor;
// IconData diffIcon; // REMOVED ICON VARIABLE


    if (diff == 0) {
      diffColor = secondaryColor; // Dark Gray for no change
      // icon removed
    } else if (diff < 0) {
      // If negative, color is RED
      diffColor = Colors.red.shade700;
    } else { // diff > 0
      // If positive, color is GREEN
      diffColor = Colors.green.shade700;
    }

    String diffString;
    if (diff == 0) {
      diffString = diff.toStringAsFixed(1);
    } else {
      // 🎯 FIX: If diff is positive (green color), explicitly prepend a '+' sign.
      // If diff is negative (red color), the '-' sign is included automatically.
      diffString = diff > 0
          ? '+${diff.toStringAsFixed(1)}'
          : diff.toStringAsFixed(1);
    }

    String v1String = v1.toStringAsFixed(1);
    String v2String = v2.toStringAsFixed(1);
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                _formatMetricName(metric),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryColor, // Black
                  fontSize: 14.5,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                v1String,
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryColor), // Dark Gray
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                v2String,
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryColor), // Dark Gray
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FIX 2: Removed Icon conditional rendering entirely

                  // const SizedBox(width: 4), // Removed space before the number
                  Text(
                    diffString,
                    style: TextStyle(
                      color: diffColor, // Retains red/green logic
                      fontWeight: FontWeight.bold,
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