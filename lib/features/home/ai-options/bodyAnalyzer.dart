import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Bodyanalyzer extends StatefulWidget {
  const Bodyanalyzer({Key? key}) : super(key: key);

  @override
  State<Bodyanalyzer> createState() => _BodyanalyzerState();
}

class _BodyanalyzerState extends State<Bodyanalyzer> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final PageController _pageController = PageController();

  String _selectedGender = '';
  String _selectedUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedActivityLevel = '';
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  bool _showAllMetrics = false;
  String? _aiRecommendation;
  bool _isLoadingRecommendation = false;
  List<DocumentSnapshot> _pastAnalyses = [];
  bool _isLoadingHistory = false;
  bool _isRecentAnalysesExpanded = false;
  int _currentPage = 0;
  String? _openMetric;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _unitOptions = ['kg', 'lbs'];
  final List<String> _heightUnits = ['cm', 'ft/in'];
  final List<String> _activityLevels = [
    'Sedentary (little/no exercise)',
    'Light (light exercise/sports 1-3 days/week)',
    'Moderate (moderate exercise/sports 3-5 days/week)',
    'Active (hard exercise/sports 6-7 days a week)',
    'Very Active (very hard exercise & physical job)',
  ];

  @override
  void initState() {
    super.initState();
    _loadPastAnalyses();
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

  Future<void> _loadPastAnalyses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_analyses')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      setState(() {
        _pastAnalyses = querySnapshot.docs;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading past analyses: $e');
      setState(() {
        _isLoadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _savePastAnalysis() async {
    final user = _auth.currentUser;
    if (user == null || _analysisResult == null) return;

    try {
      final analysisData = {
        'timestamp': FieldValue.serverTimestamp(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'weight': double.parse(_weightController.text),
        'weightUnit': _selectedUnit,
        'height': _selectedHeightUnit == 'cm'
            ? double.parse(_heightController.text)
            : (double.parse(_feetController.text) * 12 +
                double.parse(_inchesController.text)),
        'heightUnit': _selectedHeightUnit,
        'activityLevel': _selectedActivityLevel,
        'results': _analysisResult,
        'aiRecommendation': _aiRecommendation,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('body_analyses')
          .add(analysisData);

      await _loadPastAnalyses();
    } catch (e) {
      print('Error saving analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving analysis: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  BoxDecoration getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkTheme ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Future<void> _analyzeBodyComposition() async {
    if (!_formKey.currentState!.validate()) return;

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
        _analysisResult = _generateAIAnalysis(
          weightKg,
          heightCm,
          age,
          _selectedGender,
        );
        _isAnalyzing = false;
      });

      await _savePastAnalysis();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing data: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Map<String, dynamic> _generateAIAnalysis(
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
    if (bodyFatMass.isNaN || bodyFatMass.isInfinite) bodyFatMass = 0.0;

    double leanMass = weight - bodyFatMass;
    if (leanMass.isNaN || leanMass.isInfinite || leanMass < 0) leanMass = 0.0;

    double skeletalMuscleMass = leanMass * (gender == 'Male' ? 0.45 : 0.36);
    if (skeletalMuscleMass.isNaN || skeletalMuscleMass.isInfinite) skeletalMuscleMass = 0.0;

    double boneMass = weight * (gender == 'Male' ? 0.15 : 0.12);
    if (boneMass.isNaN || boneMass.isInfinite) boneMass = 0.0;

    double organMass = weight * 0.06;
    if (organMass.isNaN || organMass.isInfinite) organMass = 0.0;

    double waterMass = leanMass * 0.73;
    if (waterMass.isNaN || waterMass.isInfinite) waterMass = 0.0;

    double proteinMass = leanMass * 0.20;
    if (proteinMass.isNaN || proteinMass.isInfinite) proteinMass = 0.0;

    double bmr;
    if (gender == 'Male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    if (bmr.isNaN || bmr.isInfinite || bmr < 0) bmr = 0.0;

    int metabolicAge = _calculateMetabolicAge(bmi, bodyFatPercent, age, gender);
    int visceralFatRating = _calculateVisceralFat(bmi, age, gender);
    double subcutaneousFat = bodyFatPercent * 0.85;
    if (subcutaneousFat.isNaN || subcutaneousFat.isInfinite) subcutaneousFat = 0.0;

    double bodyWaterPercent = (waterMass / weight) * 100;
    if (bodyWaterPercent.isNaN || bodyWaterPercent.isInfinite) bodyWaterPercent = 0.0;

    int overallScore = _calculateOverallScore(
      bmi,
      bodyFatPercent,
      visceralFatRating,
      age,
      gender,
    );

    return {
      'overallScore': overallScore,
      'bodyWeight': weight,
      'bmi': bmi,
      'bodyFat': bodyFatPercent,
      'skeletalMuscle': skeletalMuscleMass,
      'visceralFat': visceralFatRating,
      'bodyFatMass': bodyFatMass,
      'leanMass': leanMass,
      'muscleMass': skeletalMuscleMass * 1.2,
      'boneMass': boneMass,
      'organMass': organMass,
      'waterMass': waterMass,
      'proteinMass': proteinMass,
      'bmr': bmr,
      'metabolicAge': metabolicAge,
      'subcutaneousFat': subcutaneousFat,
      'bodyWater': bodyWaterPercent,
    };
  }

  int _calculateMetabolicAge(
    double bmi,
    double bodyFat,
    int chronologicalAge,
    String gender,
  ) {
    double ageFactor = chronologicalAge.toDouble();

    if (bmi < 18.5)
      ageFactor += 3;
    else if (bmi > 25)
      ageFactor += (bmi - 25) * 1.5;

    double optimalBodyFat = gender == 'Male' ? 15.0 : 23.0;
    ageFactor += (bodyFat - optimalBodyFat).abs() * 0.5;

    return ageFactor.round().clamp(
      chronologicalAge - 10,
      chronologicalAge + 20,
    );
  }

  int _calculateVisceralFat(double bmi, int age, String gender) {
    double rating = 1.0;

    if (bmi > 30)
      rating += 8;
    else if (bmi > 25)
      rating += 4;

    if (age > 40) rating += (age - 40) * 0.1;
    if (gender == 'Male') rating += 1;

    return rating.round().clamp(1, 30);
  }

  int _calculateOverallScore(
    double bmi,
    double bodyFat,
    int visceralFat,
    int age,
    String gender,
  ) {
    double score = 100.0;

    double optimalBMI = 22.0;
    score -= (bmi - optimalBMI).abs() * 2;

    double optimalBodyFat = gender == 'Male' ? 15.0 : 23.0;
    score -= (bodyFat - optimalBodyFat).abs() * 1.5;

    if (visceralFat > 10) score -= (visceralFat - 10) * 3;

    if (age > 30) score -= (age - 30) * 0.2;

    return score.round().clamp(20, 100);
  }

  String _getBMICategory(double? bmi) {
    if (bmi == null || bmi.isNaN || bmi.isInfinite) return 'N/A';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _getBodyFatCategory(double? bodyFat, String gender) {
    if (bodyFat == null || bodyFat.isNaN || bodyFat.isInfinite) return 'N/A';
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

  String _getVisceralFatCategory(int? visceralFat) {
    if (visceralFat == null) return 'N/A';
    if (visceralFat <= 12) return 'Healthy';
    if (visceralFat <= 16) return 'Excess';
    return 'High Risk';
  }

  String _getSkeletalMuscleCategory(double? muscleMass, double? bodyWeight, String gender) {
    if (muscleMass == null || bodyWeight == null || bodyWeight == 0) return 'N/A';
    double musclePercentage = (muscleMass / bodyWeight) * 100;
    if (gender == 'Male') {
      if (musclePercentage > 40) return 'Excellent';
      if (musclePercentage > 35) return 'Good';
      if (musclePercentage > 30) return 'Normal';
      return 'Low';
    } else {
      if (musclePercentage > 35) return 'Excellent';
      if (musclePercentage > 30) return 'Good';
      if (musclePercentage > 25) return 'Normal';
      return 'Low';
    }
  }

  String _getBoneMassCategory(double? boneMass, String gender) {
    if (boneMass == null || boneMass.isNaN || boneMass.isInfinite) return 'N/A';
    if (gender == 'Male') {
      if (boneMass > 3.5) return 'Excellent';
      if (boneMass > 2.8) return 'Good';
      if (boneMass > 2.2) return 'Normal';
      return 'Low';
    } else {
      if (boneMass > 2.8) return 'Excellent';
      if (boneMass > 2.3) return 'Good';
      if (boneMass > 1.8) return 'Normal';
      return 'Low';
    }
  }

  String _getBMRCategory(double? bmr, String gender, double? bodyWeight) {
    if (bmr == null || bodyWeight == null || bmr.isNaN || bmr.isInfinite) return 'N/A';
    double expectedBMR = gender == 'Male'
        ? 88.362 + (13.397 * bodyWeight)
        : 447.593 + (9.247 * bodyWeight);
    if (bmr > expectedBMR * 1.1) return 'High';
    if (bmr > expectedBMR * 0.9) return 'Normal';
    return 'Low';
  }

  String _getMetabolicAgeCategory(int? metabolicAge, int? chronologicalAge) {
    if (metabolicAge == null || chronologicalAge == null) return 'N/A';
    if (metabolicAge < chronologicalAge) return 'Excellent';
    if (metabolicAge <= chronologicalAge + 5) return 'Good';
    if (metabolicAge <= chronologicalAge + 10) return 'Normal';
    return 'High';
  }

  String _getBodyWaterCategory(double? bodyWater, String gender) {
    if (bodyWater == null || bodyWater.isNaN || bodyWater.isInfinite) return 'N/A';
    if (gender == 'Male') {
      if (bodyWater > 60) return 'Excellent';
      if (bodyWater > 55) return 'Good';
      if (bodyWater > 50) return 'Normal';
      return 'Low';
    } else {
      if (bodyWater > 55) return 'Excellent';
      if (bodyWater > 50) return 'Good';
      if (bodyWater > 45) return 'Normal';
      return 'Low';
    }
  }

  String _generateAIReport() {
    if (_analysisResult == null) return '';

    final bmi = _analysisResult!['bmi'] as double?;
    final bodyFat = _analysisResult!['bodyFat'] as double?;
    final visceralFat = _analysisResult!['visceralFat'] as int?;

    String report = '';

    if (bmi != null) {
      if (bmi >= 18.5 && bmi < 25) {
        report += 'Your BMI is within the healthy range, ';
      } else if (bmi < 18.5) {
        report += 'Your BMI indicates underweight status, ';
      } else if (bmi < 30) {
        report += 'Your BMI indicates overweight status, ';
      } else {
        report += 'Your BMI indicates obesity, ';
      }
    } else {
      report += 'BMI data unavailable, ';
    }

    report +=
        'and your lean mass is also good, suggesting a decent level of muscle. ';

    if (visceralFat != null) {
      if (visceralFat <= 12) {
        report += 'Your visceral fat level is healthy. ';
      } else {
        report +=
            'A slight concern is the visceral fat level, which is at the upper end of the healthy range. ';
        report +=
            'Maintaining this level or lowering it towards the lower end of the 1-12 range is recommended. ';
      }
    } else {
      report += 'Visceral fat data unavailable. ';
    }

    if (bodyFat != null) {
      final optimalBodyFat = _selectedGender == 'Male' ? 20.0 : 25.0;
      if (bodyFat <= optimalBodyFat) {
        report += 'Your body fat percentage is excellent. ';
      } else {
        report +=
            'Your body fat percentage is acceptable, aiming to keep it below ${optimalBodyFat.toInt()}% could bring further health benefits.';
      }
    } else {
      report += 'Body fat data unavailable.';
    }

    return report;
  }

  Future<void> _getAIRecommendation() async {
    if (_analysisResult == null) return;

    setState(() {
      _isLoadingRecommendation = true;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found in environment variables');
      }

      final prompt =
          """
As a certified fitness and nutrition expert, provide personalized health recommendations based on this comprehensive body composition analysis:

**Personal Profile:**
- Age: ${_ageController.text} years
- Gender: $_selectedGender
- Activity Level: $_selectedActivityLevel

**Body Composition Analysis:**
- Body Weight: ${_analysisResult!['bodyWeight']?.toStringAsFixed(1) ?? 'N/A'} kg
- BMI: ${_analysisResult!['bmi']?.toStringAsFixed(1) ?? 'N/A'} (${_getBMICategory(_analysisResult!['bmi'])})
- Body Fat: ${_analysisResult!['bodyFat']?.toStringAsFixed(1) ?? 'N/A'}% (${_getBodyFatCategory(_analysisResult!['bodyFat'], _selectedGender)})
- Skeletal Muscle: ${_analysisResult!['skeletalMuscle']?.toStringAsFixed(1) ?? 'N/A'} kg
- Visceral Fat Level: ${_analysisResult!['visceralFat']?.toString() ?? 'N/A'} (${_getVisceralFatCategory(_analysisResult!['visceralFat'])})
- Lean Mass: ${_analysisResult!['leanMass']?.toStringAsFixed(1) ?? 'N/A'} kg
- Muscle Mass: ${_analysisResult!['muscleMass']?.toStringAsFixed(1) ?? 'N/A'} kg
- Bone Mass: ${_analysisResult!['boneMass']?.toStringAsFixed(1) ?? 'N/A'} kg
- Body Water: ${_analysisResult!['bodyWater']?.toStringAsFixed(1) ?? 'N/A'}%
- BMR: ${_analysisResult!['bmr']?.toStringAsFixed(0) ?? 'N/A'} kcal/day
- Metabolic Age: ${_analysisResult!['metabolicAge']?.toString() ?? 'N/A'} years
- Overall Health Score: ${_analysisResult!['overallScore']?.toString() ?? 'N/A'}/100

**Provide detailed recommendations in exactly this format:**

## Overall Health Assessment
[2-3 sentences analyzing current health status and key areas of concern]

## Priority Focus Areas
**1. [Most Important Metric]**
- Current status and what it means
- Specific improvement target
- Timeline for improvement

**2. [Second Priority]**
- Current status and what it means
- Specific improvement target
- Timeline for improvement

**3. [Third Priority]**
- Current status and what it means
- Specific improvement target
- Timeline for improvement

## Exercise Recommendations
**Strength Training:**
- [Specific exercises and frequency]
- [Progressive overload guidance]

**Cardiovascular Training:**
- [Type, intensity, and duration]
- [Weekly schedule]

**Flexibility & Recovery:**
- [Specific recovery protocols]

## Nutrition Strategy
**Caloric Requirements:**
- Daily calorie target: [specific number] kcal
- Protein target: [specific grams] g/day
- Carbohydrate timing and amounts

**Meal Planning:**
- [3-4 specific meal/snack recommendations]
- [Hydration requirements]
- [Supplement considerations if any]

## Expected Timeline & Milestones
- Week 2-4: [Expected changes]
- Month 2-3: [Expected improvements]
- Month 6+: [Long-term goals]

**Important Note:** Consult healthcare providers before making significant changes to diet or exercise routines.
""";

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1200,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          setState(() {
            _aiRecommendation =
                data['candidates'][0]['content']['parts'][0]['text'];
            _isLoadingRecommendation = false;
          });

          await _savePastAnalysis();
        } else {
          throw Exception('Invalid response structure from Gemini API');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRecommendation = false;
        _aiRecommendation = '''Error generating AI recommendation: $e

Please ensure:
1. Your Gemini API key is properly configured
2. You have an active internet connection
3. The API service is available

Get your free API key at: https://makersuite.google.com/app/apikey''';
      });
    }
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    required bool isDarkTheme,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.textPrimary(isDarkTheme)),
          decoration: InputDecoration(
            hintText: placeholder,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
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
          validator: validator,
        ),
      ],
    );
  }

  Widget buildDropdownField({
    required String? value,
    required String label,
    required List<String> options,
    required bool isDarkTheme,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isExpanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: isExpanded,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          dropdownColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          validator: validator,
        ),
      ],
    );
  }

  Widget buildMetricCard(
    String title,
    String value,
    String unit,
    String? category,
    bool isDarkTheme, {
    bool isMainMetric = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMainMetric ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDarkTheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: isMainMetric ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMainMetric ? 12 : 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: isMainMetric ? 28 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: isMainMetric ? 18 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (category != null && category.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              category,
              style: TextStyle(
                color: _getCategoryColor(category),
                fontSize: isMainMetric ? 13 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'normal':
      case 'healthy':
      case 'athletic':
      case 'good':
      case 'excellent':
        return AppColors.successColor;
      case 'overweight':
      case 'excess':
        return AppColors.warningColor;
      case 'obese':
      case 'high risk':
      case 'high':
        return AppColors.errorColor;
      case 'underweight':
      case 'essential':
      case 'low':
        return AppColors.lightGrey;
      default:
        return AppColors.lightGrey;
    }
  }

  Widget buildRecentAnalysesSection(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isRecentAnalysesExpanded = !_isRecentAnalysesExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  lucide.LucideIcons.history,
                  color: AppColors.black,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Body Analyses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkTheme),
                    ),
                  ),
                ),
                Icon(
                  _isRecentAnalysesExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.black,
                  size: 20,
                ),
              ],
            ),
          ),
          if (_isRecentAnalysesExpanded) ...[
            SizedBox(height: 16),
            if (_isLoadingHistory)
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.black,
                ),
              )
            else if (_pastAnalyses.isNotEmpty) ...[
              ..._pastAnalyses.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                final results = data['results'] as Map<String, dynamic>? ?? {};

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(isDarkTheme),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI: ${results['bmi']?.toStringAsFixed(1) ?? 'N/A'} • Body Fat: ${results['bodyFat']?.toStringAsFixed(1) ?? 'N/A'}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(isDarkTheme),
                              ),
                            ),
                            Text(
                              timestamp != null
                                  ? '${timestamp.day}/${timestamp.month}/${timestamp.year} • Score: ${results['overallScore']?.toInt() ?? 0}/100'
                                  : 'Date N/A • Score: ${results['overallScore']?.toInt() ?? 0}/100',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(isDarkTheme),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.visibility,
                          size: 20,
                          color: AppColors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _analysisResult = results;
                            _aiRecommendation = data['aiRecommendation'];
                            _isRecentAnalysesExpanded = false;
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No recent analyses found. Complete your first body analysis above!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(isDarkTheme),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getScoreDescription(int score) {
    if (score >= 85) return 'Excellent Health';
    if (score >= 70) return 'Good Health';
    if (score >= 55) return 'Fair Health';
    if (score >= 40) return 'Needs Improvement';
    return 'Poor Health';
  }

  Widget _buildEnhancedMetricItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required bool isDarkTheme,
    String? category,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDarkTheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.black, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (category != null) ...[
                  SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                      color: _getCategoryColor(category),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    SizedBox(width: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDarkTheme),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResultsDisplay(bool isDarkTheme) {
    if (_analysisResult == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.sparkles,
                color: AppColors.black,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Body Composition Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDarkTheme),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            child: Text(
              _generateAIReport(),
              style: TextStyle(
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDarkTheme),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Overall Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(isDarkTheme),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '${_analysisResult!['overallScore']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDarkTheme ? AppColors.darkGrey : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_analysisResult!['overallScore'] is num ? _analysisResult!['overallScore'] / 100 : 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDarkTheme),
            ),
          ),
          SizedBox(height: 16),
          _buildMetricItem(
            title: 'Body Weight',
            value: _analysisResult!['bodyWeight']?.toString() ?? '0.0',
            unit: 'kg',
            isDarkTheme: isDarkTheme,
          ),
          _buildMetricItem(
            title: 'BMI',
            value: _analysisResult!['bmi']?.toString() ?? '0.0',
            unit: '',
            isDarkTheme: isDarkTheme,
          ),
          _buildMetricItem(
            title: 'Body Fat',
            value: _analysisResult!['bodyFat']?.toString() ?? '0.0',
            unit: '%',
            isDarkTheme: isDarkTheme,
          ),
          _buildMetricItem(
            title: 'Skeletal Muscle',
            value: _analysisResult!['skeletalMuscle']?.toString() ?? '0.0',
            unit: 'kg',
            isDarkTheme: isDarkTheme,
          ),
          _buildMetricItem(
            title: 'Visceral Fat',
            value: _analysisResult!['visceralFat']?.toString() ?? '0',
            unit: 'level',
            isDarkTheme: isDarkTheme,
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _showAllMetrics = !_showAllMetrics),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.black.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAllMetrics ? 'Show Less' : 'Show All 17 Metrics',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _showAllMetrics
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.black,
                  ),
                ],
              ),
            ),
          ),
          if (_showAllMetrics) ...[
            SizedBox(height: 20),
            Text(
              'Mass Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkTheme),
              ),
            ),
            SizedBox(height: 16),
            _buildMetricItem(
              title: 'Body Fat Mass',
              value: _analysisResult!['bodyFatMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Lean Mass',
              value: _analysisResult!['leanMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Muscle Mass',
              value: _analysisResult!['muscleMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Bone Mass',
              value: _analysisResult!['boneMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Water Mass',
              value: _analysisResult!['waterMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Protein Mass',
              value: _analysisResult!['proteinMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
            SizedBox(height: 20),
            Text(
              'Other Indicators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkTheme),
              ),
            ),
            SizedBox(height: 16),
            _buildMetricItem(
              title: 'BMR',
              value: _analysisResult!['bmr']?.toString() ?? '0.0',
              unit: 'kcal/day',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Metabolic Age',
              value: _analysisResult!['metabolicAge']?.toString() ?? '0',
              unit: 'years',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Subcutaneous Fat',
              value: _analysisResult!['subcutaneousFat']?.toString() ?? '0.0',
              unit: '%',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Body Water',
              value: _analysisResult!['bodyWater']?.toString() ?? '0.0',
              unit: '%',
              isDarkTheme: isDarkTheme,
            ),
            _buildMetricItem(
              title: 'Organ Mass',
              value: _analysisResult!['organMass']?.toString() ?? '0.0',
              unit: 'kg',
              isDarkTheme: isDarkTheme,
            ),
          ],
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _analysisResult = null;
                  _aiRecommendation = null;
                  _showAllMetrics = false;
                  _ageController.clear();
                  _weightController.clear();
                  _heightController.clear();
                  _feetController.clear();
                  _inchesController.clear();
                  _selectedGender = '';
                  _selectedActivityLevel = '';
                  _currentPage = 0;
                  _pageController.jumpToPage(0);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: AppColors.white),
                  SizedBox(width: 8),
                  Text(
                    'Calculate New',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.successColor;
    if (score >= 60) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  Widget buildAIRecommendationSection(bool isDarkTheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoadingRecommendation ? null : _getAIRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoadingRecommendation
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI Generating Recommendations...',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(lucide.LucideIcons.sparkles, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        'Get AI Health Recommendations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_aiRecommendation != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.sparkles,
                      color: AppColors.black,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Health Coach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkTheme),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground(isDarkTheme),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  child: Text(
                    _aiRecommendation!,
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPage1(bool isDarkTheme, double fontSize, double space) {
    return Container(
      padding: EdgeInsets.all(space * 0.025),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.black,
                size: fontSize * 0.05,
              ),
              SizedBox(width: space * 0.01),
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: fontSize * 0.045,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
            ],
          ),
          SizedBox(height: space * 0.01),
          Text(
            'Enter your age and gender to start the analysis.',
            style: TextStyle(
              fontSize: fontSize * 0.035,
              color: AppColors.textSecondary(isDarkTheme),
            ),
          ),
          SizedBox(height: space * 0.03),
          buildInputField(
            label: 'Age',
            controller: _ageController,
            placeholder: 'Enter your age',
            isDarkTheme: isDarkTheme,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter your age';
              final age = int.tryParse(value);
              if (age == null || age < 10 || age > 120)
                return 'Please enter a valid age (10-120)';
              return null;
            },
          ),
          SizedBox(height: space * 0.02),
          buildDropdownField(
            value: _selectedGender.isEmpty ? null : _selectedGender,
            label: 'Gender',
            options: _genderOptions,
            isDarkTheme: isDarkTheme,
            onChanged: (value) => setState(() => _selectedGender = value ?? ''),
            validator: (value) => value == null || value.isEmpty
                ? 'Please select your gender'
                : null,
          ),
          SizedBox(height: space * 0.03),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                    ),
                  ),
                ),
              if (_currentPage > 0) SizedBox(width: space * 0.015),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.borderColor(isDarkTheme)),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(bool isDarkTheme, double fontSize, double space) {
    return Container(
      padding: EdgeInsets.all(space * 0.025),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: AppColors.black,
                size: fontSize * 0.05,
              ),
              SizedBox(width: space * 0.01),
              Text(
                'Body Measurements',
                style: TextStyle(
                  fontSize: fontSize * 0.045,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
            ],
          ),
          SizedBox(height: space * 0.01),
          Text(
            'Enter your weight and height details.',
            style: TextStyle(
              fontSize: fontSize * 0.035,
              color: AppColors.textSecondary(isDarkTheme),
            ),
          ),
          SizedBox(height: space * 0.02),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: buildInputField(
                  label: 'Weight',
                  controller: _weightController,
                  placeholder: 'Enter weight',
                  isDarkTheme: isDarkTheme,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) return 'Invalid weight';
                    return null;
                  },
                ),
              ),
              SizedBox(width: space * 0.015),
              Expanded(
                flex: 2,
                child: buildDropdownField(
                  value: _selectedUnit,
                  label: 'Unit',
                  options: _unitOptions,
                  isDarkTheme: isDarkTheme,
                  onChanged: (value) => setState(() => _selectedUnit = value ?? 'kg'),
                ),
              ),
            ],
          ),
          SizedBox(height: space * 0.02),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _selectedHeightUnit == 'cm'
                    ? buildInputField(
                        label: 'Height',
                        controller: _heightController,
                        placeholder: 'Enter height in cm',
                        isDarkTheme: isDarkTheme,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Required';
                          final height = double.tryParse(value);
                          if (height == null || height < 100 || height > 250)
                            return 'Invalid height';
                          return null;
                        },
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: buildInputField(
                              label: 'Feet',
                              controller: _feetController,
                              placeholder: 'ft',
                              isDarkTheme: isDarkTheme,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final feet = double.tryParse(value);
                                if (feet == null || feet < 3 || feet > 8) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: space * 0.015),
                          Expanded(
                            child: buildInputField(
                              label: 'Inches',
                              controller: _inchesController,
                              placeholder: 'in',
                              isDarkTheme: isDarkTheme,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final inches = double.tryParse(value);
                                if (inches == null || inches < 0 || inches >= 12)
                                  return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(width: space * 0.015),
              Expanded(
                flex: 2,
                child: buildDropdownField(
                  value: _selectedHeightUnit,
                  label: 'Unit',
                  options: _heightUnits,
                  isDarkTheme: isDarkTheme,
                  onChanged: (value) => setState(() => _selectedHeightUnit = value ?? 'cm'),
                ),
              ),
            ],
          ),
          SizedBox(height: space * 0.03),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
              SizedBox(width: space * 0.015),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.borderColor(isDarkTheme)),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(bool isDarkTheme, double fontSize, double space) {
    return Container(
      padding: EdgeInsets.all(space * 0.025),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_run,
                color: AppColors.black,
                size: fontSize * 0.05,
              ),
              SizedBox(width: space * 0.01),
              Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: fontSize * 0.045,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
            ],
          ),
          SizedBox(height: space * 0.01),
          Text(
            'Select your activity level to complete the analysis.',
            style: TextStyle(
              fontSize: fontSize * 0.035,
              color: AppColors.textSecondary(isDarkTheme),
            ),
          ),
          SizedBox(height: space * 0.03),
          buildDropdownField(
            value: _selectedActivityLevel.isEmpty ? null : _selectedActivityLevel,
            label: 'Activity Level',
            options: _activityLevels,
            isDarkTheme: isDarkTheme,
            isExpanded: true,
            onChanged: (value) => setState(() => _selectedActivityLevel = value ?? ''),
            validator: (value) => value == null || value.isEmpty
                ? 'Please select activity level'
                : null,
          ),
          SizedBox(height: space * 0.03),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                ),
              ),
              SizedBox(width: space * 0.015),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : () {
                    if (_formKey.currentState!.validate()) {
                      _analyzeBodyComposition();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColors.borderColor(isDarkTheme)),
                    ),
                    elevation: 2,
                  ),
                  child: _isAnalyzing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: fontSize * 0.045,
                              height: fontSize * 0.045,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.white),
                              ),
                            ),
                            SizedBox(width: space * 0.015),
                            Text(
                              'Analyzing...',
                              style: TextStyle(fontSize: fontSize * 0.04, color: AppColors.white),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(lucide.LucideIcons.sparkles, size: fontSize * 0.05, color: AppColors.white),
                            SizedBox(width: space * 0.01),
                            Text(
                              'Analyze',
                              style: TextStyle(
                                fontSize: fontSize * 0.04,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String unit,
    required bool isDarkTheme,
    IconData? fallbackIcon,
  }) {
    Map<String, dynamic> getMetricDetails(String title) {
      switch (title) {
        case 'Body Weight':
          return {
            'icon': lucide.LucideIcons.personStanding,
            'description': 'Your total weight in kilograms.',
            'category': null,
          };
        case 'BMI':
          return {
            'icon': lucide.LucideIcons.personStanding,
            'description': 'Body Mass Index, a ratio of weight to height. Ideal range: 18.5 - 24.9.',
            'category': _getBMICategory(_analysisResult!['bmi']),
          };
        case 'Body Fat':
          return {
            'icon': lucide.LucideIcons.heartPulse,
            'description': 'The percentage of your body composed of fat. Ideal ranges (fit): Men 10-20%, Women 18-28%.',
            'category': _getBodyFatCategory(_analysisResult!['bodyFat'], _selectedGender),
          };
        case 'Skeletal Muscle':
          return {
            'icon': lucide.LucideIcons.beef,
            'description': 'The weight of muscle attached to your skeleton. Higher is generally better for metabolism and strength.',
            'category': _getSkeletalMuscleCategory(_analysisResult!['skeletalMuscle'], _analysisResult!['bodyWeight'], _selectedGender),
          };
        case 'Visceral Fat':
          return {
            'icon': lucide.LucideIcons.shieldCheck,
            'description': 'Fat stored around your internal organs. A healthy level is 1-12. Levels above 13 indicate higher health risk.',
            'category': _getVisceralFatCategory(_analysisResult!['visceralFat']),
          };
        case 'Body Fat Mass':
          return {
            'icon': lucide.LucideIcons.heartPulse,
            'description': 'The total mass of fat in your body. This is calculated from your weight and body fat percentage.',
            'category': null,
          };
        case 'Lean Mass':
          return {
            'icon': lucide.LucideIcons.personStanding,
            'description': 'The total weight of your fat-free tissues, including muscle, bone, and organs.',
            'category': null,
          };
        case 'Muscle Mass':
          return {
            'icon': lucide.LucideIcons.beef,
            'description': 'The total estimated weight of all muscle in your body.',
            'category': null,
          };
        case 'Bone Mass':
          return {
            'icon': lucide.LucideIcons.bone,
            'description': 'The estimated weight of bone mineral in your body.',
            'category': _getBoneMassCategory(_analysisResult!['boneMass'], _selectedGender),
          };
        case 'Water Mass':
          return {
            'icon': lucide.LucideIcons.droplets,
            'description': 'The total weight of water in your body.',
            'category': null,
          };
        case 'Protein Mass':
          return {
            'icon': lucide.LucideIcons.droplets,
            'description': 'The estimated total amount of protein in your body.',
            'category': null,
          };
        case 'BMR':
          return {
            'icon': lucide.LucideIcons.brainCircuit,
            'description': 'Basal Metabolic Rate: calories burned at rest daily.',
            'category': _getBMRCategory(_analysisResult!['bmr'], _selectedGender, _analysisResult!['bodyWeight']),
          };
        case 'Metabolic Age':
          return {
            'icon': lucide.LucideIcons.brainCircuit,
            'description': 'Your body\'s estimated age based on its metabolic rate.',
            'category': _getMetabolicAgeCategory(_analysisResult!['metabolicAge'], int.tryParse(_ageController.text)),
          };
        case 'Subcutaneous Fat':
          return {
            'icon': lucide.LucideIcons.heartPulse,
            'description': 'The percentage of your total body fat located just under the skin.',
            'category': null,
          };
        case 'Body Water':
          return {
            'icon': lucide.LucideIcons.droplets,
            'description': 'The percentage of your total body weight that is water.',
            'category': _getBodyWaterCategory(_analysisResult!['bodyWater'], _selectedGender),
          };
        case 'Organ Mass':
          return {
            'icon': lucide.LucideIcons.heart,
            'description': 'The estimated weight of your internal organs.',
            'category': null,
          };
        default:
          return {
            'icon': fallbackIcon ?? lucide.LucideIcons.activity,
            'description': 'No description available.',
            'category': null,
          };
      }
    }

    final metricDetails = getMetricDetails(title);
    final isOpen = _openMetric == title;

    String formattedValue = 'N/A';
    try {
      if (value.isNotEmpty) {
        if (title == 'Visceral Fat' || title == 'Metabolic Age') {
          formattedValue = int.tryParse(value)?.toString() ?? 'N/A';
        } else {
          formattedValue = double.tryParse(value)?.toStringAsFixed(1) ?? 'N/A';
        }
      }
    } catch (e) {
      print('Error formatting value for $title: $value, Error: $e');
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _openMetric = isOpen ? null : title;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(isDarkTheme),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen
                ? AppColors.black.withOpacity(0.5)
                : isDarkTheme
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
            width: isOpen ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkTheme ? Colors.black.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metricDetails['icon'], color: AppColors.black, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (metricDetails['category'] != null && metricDetails['category'] != 'N/A') ...[
                        SizedBox(height: 2),
                        Text(
                          metricDetails['category'],
                          style: TextStyle(
                            color: _getCategoryColor(metricDetails['category']),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedValue,
                          style: TextStyle(
                            color: AppColors.textPrimary(isDarkTheme),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (unit.isNotEmpty && formattedValue != 'N/A') ...[
                          SizedBox(width: 2),
                          Text(
                            unit,
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (isOpen) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  metricDetails['description'],
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkTheme = Provider.of<ThemeProvider>(context).isDarkMode;

    double font(double size) => screenWidth * size;
    double space(double h) => screenHeight * h;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            lucide.LucideIcons.arrowLeft,
            color: AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Body Analyzer',
          style: TextStyle(
            fontSize: font(0.05),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space(0.025),
            vertical: space(0.015),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_analysisResult == null) ...[
                  SizedBox(
                    height: screenHeight * 0.7,
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildPage1(isDarkTheme, font(1), space(1)),
                        _buildPage2(isDarkTheme, font(1), space(1)),
                        _buildPage3(isDarkTheme, font(1), space(1)),
                      ],
                    ),
                  ),
                ],
                if (_analysisResult != null) ...[
                  buildResultsDisplay(isDarkTheme),
                  SizedBox(height: space(0.03)),
                  buildAIRecommendationSection(isDarkTheme),
                ],
                SizedBox(height: space(0.03)),
                buildRecentAnalysesSection(isDarkTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}