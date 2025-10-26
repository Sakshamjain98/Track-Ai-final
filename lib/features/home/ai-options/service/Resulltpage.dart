import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/constants/appcolors.dart';
import '../../../../core/themes/theme_provider.dart';
import '../bodyAnalyzer.dart';
// import 'package:trackai/core/themes/theme_provider.dart'; // Assuming this imports ThemeProvider
// import '../bodyAnalyzer.dart'; // Assuming this imports AnalysisReport
// import 'package:trackai/core/constants/appcolors.dart'; // Assuming this imports AppColors



// --- Results Page (COMPLETE, UPDATED IMPLEMENTATION) ---
class ResultsPage extends StatefulWidget {
  final AnalysisReport report;
  final String gender;
  const ResultsPage({Key? key, required this.report, required this.gender}) : super(key: key);

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _showRecommendations = false;
  bool _isGeneratingRecommendations = false; // NEW LOADING STATE
  Map<String, dynamic>? _generatedRecommendations;
  String? _openMetric;

  // --- DEFINITION OF METRIC GROUPS (16 Metrics + 1 Score) ---
  final Map<String, List<String>> _metricGroups = {
    'Key Metrics': [
      'Body Weight',
      'BMI',
      'Body Fat Percentage',
      'Skeletal Muscle Mass',
      'Visceral Fat Level',
    ],
    'Mass Breakdown': [
      'Body Fat Mass',
      'Lean Mass',
      'Muscle Mass',
      'Bone Mass',
      'Water Mass',
      'Protein Mass',
    ],
    'Other Indicators': [
      'BMR', 'Metabolic Age', 'Subcutaneous Fat', 'Body Water Percentage',
    ]
  };

  final Map<String, String> _metricDescriptions = {
    'Body Weight': 'Your total weight in kilograms.',
    'BMI': 'Body Mass Index, a ratio of weight to height. Ideal range: 18.5 - 24.9.',
    'Body Fat Percentage': 'The percentage of your body composed of fat. Ideal ranges (fit): Men 10-20%, Women 18-28%.',
    'Skeletal Muscle Mass': 'The weight of muscle attached to your skeleton. Higher is generally better for metabolism and strength.',
    'Visceral Fat Level': 'Fat stored around your internal organs. A healthy level is 1-12. Levels above 13 indicate higher health risk.',
    'Body Fat Mass': 'The total mass of fat in your body. This is calculated from your weight and body fat percentage.',
    'Lean Mass': 'The total weight of your fat-free tissues, including muscle, bone, and organs.',
    'Muscle Mass': 'The total estimated weight of all muscle in your body.',
    'Bone Mass': 'The estimated weight of bone mineral in your body.',
    'Water Mass': 'The total weight of water in your body.',
    'Protein Mass': 'The estimated total amount of protein in your body.',
    'BMR': 'Basal Metabolic Rate: calories burned at rest daily.',
    'Metabolic Age': 'Your body\'s estimated age based on its metabolic rate.',
    'Subcutaneous Fat': 'The percentage of your total body fat located just under the skin.',
    'Body Water Percentage': 'The percentage of your total body weight that is water.',
    'Body Composition Score': 'An overall health score based on the combination of all analyzed metrics.',
  };

  // --- NEW: Icon Mapping Helper ---
  IconData _getMetricIcon(String metricName) {
    switch (metricName) {
      case 'Body Composition Score':
        return lucide.LucideIcons.medal;
      case 'Body Weight':
        return lucide.LucideIcons.scale;
      case 'BMI':
        return lucide.LucideIcons.ruler;
      case 'Body Fat Percentage':
        return lucide.LucideIcons.percent;
      case 'Skeletal Muscle Mass':
        return lucide.LucideIcons.armchair;
      case 'Visceral Fat Level':
        return lucide.LucideIcons.heartPulse;
      case 'Body Fat Mass':
        return lucide.LucideIcons.chartArea;
      case 'Lean Mass':
        return lucide.LucideIcons.layers;
      case 'Muscle Mass':
        return lucide.LucideIcons.dumbbell;
      case 'Bone Mass':
        return lucide.LucideIcons.bone;
      case 'Water Mass':
        return lucide.LucideIcons.droplet;
      case 'Protein Mass':
        return lucide.LucideIcons.nut;
      case 'BMR':
        return lucide.LucideIcons.zap;
      case 'Metabolic Age':
        return lucide.LucideIcons.cake;
      case 'Subcutaneous Fat':
        return lucide.LucideIcons.activity; // Default or close
      case 'Body Water Percentage':
        return lucide.LucideIcons.glassWater;
      default:
        return lucide.LucideIcons.activity;
    }
  }

  // -----------------------------


  @override
  void initState() {
    super.initState();
    if (widget.report.recommendations != null) {
      _generatedRecommendations = widget.report.recommendations;
      _showRecommendations = true;
    }
  }

  // Helper to determine the color of the score (Green for good, Red for bad)
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.lightGreen.shade400;
    if (score >= 40) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  // --- _generateAndShowRecommendations (MODIFIED for loading) ---
  void _generateAndShowRecommendations() async {
    if (_isGeneratingRecommendations) return;

    setState(() {
      _isGeneratingRecommendations = true;
      _showRecommendations = false;
    });

    // Simulate AI processing time (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // --- Start Recommendation Logic (Same as before, just wrapped in the delay) ---
    Map<String, dynamic> recommendations = {};
    List<String> focus = [];
    List<String> good = [];

    final metrics = widget.report.metrics;
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
      double? bodyWater = (metrics['Body Water Percentage'] as num?)
          ?.toDouble();
      double? boneMass = (metrics['Bone Mass'] as num?)?.toDouble();
      double? proteinMass = (metrics['Protein Mass'] as num?)?.toDouble();

      // BMI Analysis
      if (bmi > 24.9) {
        focus.add("BMI\nProblem: Your BMI of ${bmi.toStringAsFixed(
            1)} is higher than the ideal range (18.5-24.9).\nSolution: Incorporate a balanced diet and regular physical activity.");
      } else if (bmi < 18.5) {
        focus.add("BMI\nProblem: Your BMI of ${bmi.toStringAsFixed(
            1)} is in the underweight range (Ideal: 18.5-24.9).\nSolution: Consider increasing your intake of nutrient-dense foods and consult with a healthcare professional.");
      } else {
        good.add("BMI\nValue: Your BMI is ${bmi.toStringAsFixed(
            1)}.\nRecommendation: Maintain your current healthy lifestyle.");
      }

      // Body Fat Analysis
      bool isMale = widget.gender == 'Male';
      double idealBfMax = isMale ? 20.0 : 28.0;
      double idealBfMin = isMale ? 10.0 : 18.0;
      if (bf > idealBfMax) {
        focus.add(
            "Body Fat Percentage\nProblem: Your body fat percentage of ${bf
                .toStringAsFixed(
                1)}% is above the healthy range.\nSolution: Combine cardio and strength training with a calorie-controlled diet.");
      } else if (bf < idealBfMin) {
        focus.add(
            "Body Fat Percentage\nProblem: Your body fat percentage of ${bf
                .toStringAsFixed(
                1)}% is below the typical healthy range.\nSolution: Ensure you are consuming enough healthy fats and overall calories.");
      } else {
        good.add("Body Fat Percentage\nValue: Your body fat percentage is ${bf
            .toStringAsFixed(
            1)}%.\nRecommendation: Continue to monitor your composition and maintain your routine.");
      }

      // Visceral Fat Analysis
      if (vfl > 12) {
        focus.add("Visceral Fat Level\nProblem: Your visceral fat level of ${vfl
            .toStringAsFixed(
            0)} is elevated above the ideal range of 1-12.\nSolution: Incorporate 2-3 sessions of High-Intensity Interval Training (HIIT) per week, focus on sleep quality.");
      } else if (vfl < 1) {
        focus.add("Visceral Fat Level\nProblem: Your visceral fat level of ${vfl
            .toStringAsFixed(
            0)} is very low.\nSolution: Ensure adequate intake of essential fats.");
      } else {
        good.add("Visceral Fat Level\nValue: Your visceral fat level is ${vfl
            .toStringAsFixed(
            0)}.\nRecommendation: Focus on consistency in diet and exercise.");
      }

      // Metabolic Age Analysis
      if (metabolicAge != null) {
        good.add(
            "Metabolic Age\nValue: Your estimated metabolic age is $metabolicAge years.\nRecommendation: If this is higher than your actual age, prioritize healthy lifestyle choices.");
      }

      // Skeletal Muscle Mass
      if (smm != null) good.add(
          "Skeletal Muscle Mass\nValue: Your skeletal muscle mass is ${smm
              .toStringAsFixed(
              1)} kg.\nRecommendation: Focus on consistent resistance training and adequate protein intake to maintain or increase this.");

      // BMR
      if (bmr != null) good.add("BMR\nValue: Your BMR is ${bmr
          .round()} kcal/day.\nRecommendation: Ensure your caloric intake aligns with your activity level and weight goals.");

      // Muscle Mass
      if (muscleMass != null) good.add(
          "Muscle Mass\nValue: Your muscle mass is ${muscleMass.toStringAsFixed(
              1)} kg.\nRecommendation: Consistent resistance training and adequate protein intake help maintain or increase this.");

      // Lean Mass
      if (leanMass != null) good.add(
          "Lean Mass\nValue: Your lean mass is ${leanMass.toStringAsFixed(
              1)} kg.\nRecommendation: Maintaining or increasing lean mass through adequate protein and resistance training contributes positively.");

      // Body Water Percentage
      if (bodyWater != null) {
        double minWater = isMale ? 50.0 : 45.0;
        double maxWater = isMale ? 65.0 : 60.0;
        if (bodyWater < minWater) {
          focus.add(
              "Body Water Percentage\nProblem: Your body water percentage (${bodyWater
                  .toStringAsFixed(0)}%) is below the typical range (${minWater
                  .toStringAsFixed(0)}% to ${maxWater.toStringAsFixed(
                  0)}%).\nSolution: Ensure you're drinking adequate fluids throughout the day (approx. 2-3 liters).");
        } else if (bodyWater > maxWater) {
          focus.add(
              "Body Water Percentage\nProblem: Your body water percentage (${bodyWater
                  .toStringAsFixed(0)}%) is above the typical range (${minWater
                  .toStringAsFixed(0)}% to ${maxWater.toStringAsFixed(
                  0)}%).\nSolution: Consult a healthcare provider if concerned about fluid retention, and review sodium intake.");
        } else {
          good.add(
              "Body Water Percentage\nValue: Your body water percentage is ${bodyWater
                  .toStringAsFixed(
                  0)}%.\nRecommendation: Stay adequately hydrated.");
        }
      }

      // Bone Mass
      if (boneMass != null) good.add(
          "Bone Mass\nValue: Your bone mass is ${boneMass.toStringAsFixed(
              1)} kg.\nRecommendation: Maintain it through weight-bearing exercises and a diet rich in calcium and vitamin D.");

      // Protein Mass
      if (proteinMass != null) good.add(
          "Protein Mass\nValue: Your protein mass is ${proteinMass
              .toStringAsFixed(
              1)} kg.\nRecommendation: Ensure adequate protein intake for muscle repair and overall health.");

      // Overall Score
      if (score != null) {
        if (score < 60)
          focus.add(
              "Body Composition Score\nProblem: Your overall score is $score/100, indicating room for improvement in overall composition.\nSolution: Address the most critical metrics listed above (BMI, Body Fat, Visceral Fat) to boost your score.");
        else
          good.add(
              "Body Composition Score\nValue: Your score is $score/100.\nRecommendation: Continue monitoring your metrics and focusing on areas of strength.");
      }
    } catch (e) {
      print("Error generating recommendations from AI metrics: $e");
      focus.add(
          "Could not fully generate recommendations due to unexpected metric data.");
    }

    recommendations['summary'] = metrics['healthIndicator'] ??
        "Analysis complete. Review individual metrics for details.";
    recommendations['focus'] = focus.isNotEmpty ? focus : [
      "Great job! No major areas need immediate focus based on these key metrics. Maintain your healthy habits!"
    ];
    recommendations['good'] =
    good.isNotEmpty ? good : ["Continue monitoring your metrics."];
    // --- End Recommendation Logic ---

    // Update the state to show the generated recommendations
    setState(() {
      _generatedRecommendations = recommendations;
      _isGeneratingRecommendations = false;
      _showRecommendations = true;
    });
  }

  // --- _getCategoryForMetric (Unchanged) ---
  String _getCategoryForMetric(String metricName, double value) {
    switch (metricName) {
      case 'BMI':
        if (value < 18.5) return 'Underweight';
        if (value < 25) return 'Normal';
        if (value < 30) return 'Overweight';
        return 'Obese';
      case 'Body Fat Percentage':
        bool isMale = widget.gender == 'Male';
        double athMax = isMale ? 14.0 : 20.0;
        double goodMax = isMale ? 20.0 : 28.0;
        if (value < athMax) return 'Athletic';
        if (value < goodMax) return 'Good';
        return 'Excess';
      case 'Visceral Fat Level':
        if (value < 10) return 'Healthy';
        if (value < 13) return 'Acceptable';
        if (value < 16) return 'High';
        return 'Very High';
      case 'Body Water Percentage':
        bool isMale = widget.gender == 'Male';
        double minWater = isMale ? 50.0 : 45.0;
        double maxWater = isMale ? 65.0 : 60.0;
        if (value < minWater) return 'Low';
        if (value < maxWater) return 'Normal';
        return 'High';
      case 'Metabolic Age':
        return 'Value';
      case 'Body Composition Score':
        return 'Score';
      default:
        return 'Value';
    }
  }

  // --- _buildMetricGroup (Unchanged) ---
  Widget _buildMetricGroup(String title, List<String> metricKeys, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 16),
        ...metricKeys.map((key) {
          if (widget.report.metrics.containsKey(key) &&
              widget.report.metrics[key] is num) {
            final metricValue = (widget.report.metrics[key] as num).toDouble();
            final category = _getCategoryForMetric(key, metricValue);
            final description = _metricDescriptions[key] ??
                'No description available.';

            return _buildMetricCard(
              key,
              metricValue,
              category,
              description,
              isDark,
              _openMetric == key,
                  () =>
                  setState(() {
                    _openMetric = _openMetric == key ? null : key;
                  }),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider
        .of<ThemeProvider>(context)
        .isDarkMode;
    final Color primaryTextColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors
        .grey[600]!;
    final metrics = widget.report.metrics;

    // Get the score and its color/progress value
    final int score = (metrics['Body Composition Score'] as num?)?.round() ?? 0;
    final Color scoreColor = _getScoreColor(score);
    final double scoreProgress = score / 100.0;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('AI Body Composition Report', style: TextStyle(color: isDark
            ? Colors.white
            : Colors.black)),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Overall Score Card 🌟
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scoreColor.withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(color: scoreColor.withOpacity(isDark ? 0.2 : 0.1),
                      blurRadius: 10,
                      spreadRadius: 1)
                ],
              ),
              child: Column(
                children: [
                  Text('Body Composition Score', style: TextStyle(
                      fontSize: 16, color: secondaryTextColor)),
                  const SizedBox(height: 16),
                  Text(
                      '$score',
                      style: TextStyle(fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: scoreColor)
                  ),
                  Text('out of 100', style: TextStyle(fontSize: 14,
                      color: secondaryTextColor.withOpacity(0.7))),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: scoreProgress,
                    backgroundColor: isDark ? Colors.grey[800] : Colors
                        .grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    metrics['healthIndicator'] as String? ??
                        'No detailed summary provided.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: primaryTextColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- ALL 16 METRICS DISPLAYED IN GROUPS ---
            _buildMetricGroup(
                'Key Metrics', _metricGroups['Key Metrics']!, isDark),
            _buildMetricGroup(
                'Mass Breakdown', _metricGroups['Mass Breakdown']!, isDark),
            _buildMetricGroup(
                'Other Indicators', _metricGroups['Other Indicators']!, isDark),

            // --- Recommendation Section (Conditional Display with Loading) ---
            if (!_showRecommendations)
              Center(
                child: ElevatedButton.icon(
                  icon: _isGeneratingRecommendations
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : Colors.white),
                    ),
                  )
                      : Icon(lucide.LucideIcons.sparkles, size: 18),
                  label: Text(_isGeneratingRecommendations
                      ? 'Analyzing...'
                      : 'Get AI Recommendations'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isGeneratingRecommendations
                      ? null
                      : _generateAndShowRecommendations,
                ),
              )
            else
              if (_generatedRecommendations != null) ...[
                Text('AI-Powered Recommendations', style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor)),
                const SizedBox(height: 16),
                // Overall Recommendation (from AI's healthIndicator field)
                _buildRecommendationCard(
                    'Overall Summary',
                    _generatedRecommendations!['summary'] ??
                        'No summary available.',
                    lucide.LucideIcons.brainCircuit,
                    Colors.blueAccent,
                    isDark
                ),
                // Areas for Focus (Local Logic)
                _buildRecommendationCard(
                    'Areas for Focus',
                    (_generatedRecommendations!['focus'] as List<dynamic>?)
                        ?.map((item) => item.toString())
                        .join('\n\n') ?? 'None specified.',
                    lucide.LucideIcons.triangle,
                    Colors.orangeAccent,
                    isDark
                ),
                // What's Going Well (Local Logic)
                _buildRecommendationCard(
                    "What's Going Well",
                    (_generatedRecommendations!['good'] as List<dynamic>?)
                        ?.map((item) => item.toString())
                        .join('\n\n') ?? 'Keep monitoring.',
                    lucide.LucideIcons.circleCheck,
                    Colors.green,
                    isDark
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                      "Could not generate recommendations at this time.",
                      style: TextStyle(color: Colors.redAccent)),
                ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- _buildMetricCard (UPDATED for dynamic Icons) ---
  Widget _buildMetricCard(String title,
      dynamic value,
      String category,
      String description,
      bool isDark,
      bool isOpen,
      VoidCallback onTap,) {
    Color categoryColor = Colors.grey;
    Color categoryTextColor = isDark ? Colors.black : Colors.white;

    switch (category.toLowerCase()) {
      case 'underweight':
        categoryColor = Colors.blueAccent;
        categoryTextColor = Colors.white;
        break;
      case 'normal':
      case 'good':
      case 'healthy':
      case 'athletic':
      case 'value':
      case 'score':
        categoryColor = Colors.green;
        categoryTextColor = Colors.white;
        break;
      case 'overweight':
      case 'acceptable':
      case 'low':
        categoryColor = Colors.orangeAccent;
        categoryTextColor = Colors.black;
        break;
      case 'obese':
      case 'excess':
      case 'high':
      case 'very high':
        categoryColor = Colors.redAccent;
        categoryTextColor = Colors.white;
        break;
      default:
        categoryColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        categoryTextColor = isDark ? Colors.white : Colors.black;
        break;
    }

    String valueString = (value is double && ![
      'Metabolic Age',
      'Visceral Fat Level',
      'Body Composition Score',
      'BMR'
    ].contains(title))
        ? value.toStringAsFixed(1)
        : (value as num?)?.round().toString() ?? '--';

    String unit = {
      'Body Weight': 'kg',
      'Body Fat Percentage': '%',
      'Body Water Percentage': '%',
      'Skeletal Muscle Mass': 'kg',
      'Muscle Mass': 'kg',
      'Lean Mass': 'kg',
      'Body Fat Mass': 'kg',
      'Bone Mass': 'kg',
      'Water Mass': 'kg',
      'Protein Mass': 'kg',
      'BMR': 'kcal/day',
      'Metabolic Age': 'years',
      'Visceral Fat Level': 'level',
      'BMI': '',
      'Subcutaneous Fat': '%',
    }[title] ?? '';


    final Color primaryColor = isDark ? Colors.white : Colors.black;
    // Use AppColors.greenPrimary or fallback
    final Color accentColor = (AppColors.greenPrimary).withOpacity(0.8);
    final IconData metricIcon = _getMetricIcon(title); // <-- NEW ICON CALL

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Green highlight for open state
          color: isOpen ? accentColor.withOpacity(isDark ? 0.2 : 0.1) : (isDark
              ? Colors.grey[900]
              : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? accentColor : (isDark ? Colors.grey[800]! : Colors
                .grey[200]!),
            width: isOpen ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon
                          Icon(metricIcon, size: 18,
                              color: accentColor), // <-- USED DYNAMIC ICON
                          const SizedBox(width: 8),
                          // Metric Title
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category Tag
                      if (category != 'Value' && category != 'Score' &&
                          category != 'N/A')
                        Padding(
                          padding: const EdgeInsets.only(left: 26.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: categoryColor,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(category, style: TextStyle(
                                color: categoryTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
                // Value and Unit
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          valueString,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unit.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(unit, style: TextStyle(color: isDark
                            ? Colors.grey[500]
                            : Colors.grey[500], fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Expanded Description Section
            if (isOpen)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: isDark ? Colors.grey[700] : Colors.grey[300],
                        thickness: 0.5),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        height: 1.4,
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

// --- _buildRecommendationCard (Enhanced UI, better separation & colors) ---
  Widget _buildRecommendationCard(
      String title,
      String content,
      IconData icon,
      Color color,
      bool isDark,
      ) {
    // Parse sections
    final List<String> items = content
        .split('\n\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Neutral palette (material-like) — softer, more modern
    final Color surface = Colors.white;                          // card bg
    final Color onSurface = const Color(0xFF0F172A);             // near-black text
    final Color onSurfaceMuted = const Color(0xFF475569);        // body text
    final Color divider = const Color(0xFFE2E8F0);               // lines
    final Color rail = const Color(0xFFCBD5E1);                  // left rail

    // Accents for categories (accessible on white)
    final Color focusAccent = const Color(0xFFB45309);           // amber-700
    final Color focusChipBg = const Color(0xFFFEF3C7);           // amber-100
    final Color goodAccent = const Color(0xFF047857);            // emerald-700
    final Color goodChipBg = const Color(0xFFD1FAE5);            // emerald-100
    final Color overallHeaderBg = const Color(0xFFF8FAFC);       // slate-50
    final Color sectionTitle = const Color(0xFF111827);          // slate-900

    final bool isOverall = title == 'Overall Summary';
    final bool isFocusArea = title == 'Areas for Focus';

    // Card border and header tint
    final Color cardBorder = isOverall
        ? divider
        : (isFocusArea ? const Color(0xFFF59E0B) : const Color(0xFF34D399)); // amber-500 / emerald-400
    final Color headerBg = isOverall
        ? overallHeaderBg
        : (isFocusArea ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5));  // amber-50 / emerald-50
    final Color accent = isFocusArea ? focusAccent : goodAccent;
    final Color chipBgDefault = isFocusArea ? focusChipBg : goodChipBg;

    // Numeric highlighter
    TextSpan _highlightNumerics(String text, Color baseColor) {
      final reg = RegExp(r'(-?\d{1,3}(?:,\d{3})*(?:\.\d+)?%?|\d{1,2}-\d{1,2})');
      final spans = <TextSpan>[];
      int last = 0;
      for (final m in reg.allMatches(text)) {
        if (m.start > last) {
          spans.add(TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.55),
          ));
        }
        spans.add(TextSpan(
          text: m.group(0),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            height: 1.55,
          ),
        ));
        last = m.end;
      }
      if (last < text.length) {
        spans.add(TextSpan(
          text: text.substring(last),
          style: TextStyle(color: baseColor, fontSize: 13.5, height: 1.55),
        ));
      }
      return TextSpan(children: spans);
    }

    // Label style config
    Map<String, (Color, Color)> labelStyleOf(bool isFocus) => {
      'Problem': (isFocus ? const Color(0xFFB91C1C) : const Color(0xFF7F1D1D), const Color(0xFFFEF2F2)),      // red-700 on red-50
      'Solution': (goodAccent, goodChipBg),
      'Recommendation': (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE)),                                    // blue-700 / blue-100
      'Value': (sectionTitle, const Color(0xFFF1F5F9)),                                                         // slate-900 / slate-100
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: isOverall ? 1 : 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isOverall ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // subtle left icon in circular bg
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isOverall
                        ? lucide.LucideIcons.brainCircuit
                        : (isFocusArea
                        ? lucide.LucideIcons.target
                        : lucide.LucideIcons.circleCheck),
                    size: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: sectionTitle,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                // small status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: divider),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverall ? 'Summary' : (isFocusArea ? 'Focus' : 'Good'),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area with left rail for stronger separation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left rail
              Container(
                width: 3,
                height: 1,
                margin: const EdgeInsets.only(left: 0),
                color: Colors.transparent,
              ),
              Container(
                width: 3,
                margin: const EdgeInsets.only(left: 0),
                decoration: BoxDecoration(
                  color: rail,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // Main column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOverall)
                        Text(
                          content.replaceAll('\n', ' '),
                          style: TextStyle(
                            fontSize: 14,
                            color: onSurfaceMuted,
                            height: 1.6,
                          ),
                          softWrap: true,
                        )
                      else
                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final parts = item.split('\n');
                          final metricTitle = parts.isNotEmpty
                              ? parts.first.replaceAll(':', '').trim()
                              : '';
                          final details =
                          parts.length > 1 ? parts.sublist(1) : <String>[];

                          return Container(
                            margin: EdgeInsets.only(
                              bottom: index < items.length - 1 ? 14 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: divider, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: (isFocusArea
                                              ? focusChipBg
                                              : goodChipBg)
                                              .withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isFocusArea
                                              ? lucide.LucideIcons.triangleAlert
                                              : lucide.LucideIcons.check,
                                          size: 16,
                                          color: accent,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          metricTitle,
                                          style: TextStyle(
                                            color: onSurface,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Details: stacked chips + paragraph
                                ...details.map((detail) {
                                  final isProblem = detail.startsWith('Problem:');
                                  final isSolution = detail.startsWith('Solution:');
                                  final isRecommendation =
                                  detail.startsWith('Recommendation:');
                                  final isValue = detail.startsWith('Value:');

                                  String label = '';
                                  if (isProblem) label = 'Problem';
                                  if (isSolution) label = 'Solution';
                                  if (isRecommendation) label = 'Recommendation';
                                  if (isValue) label = 'Value';

                                  final styles = labelStyleOf(isFocusArea)[label] ??
                                      (onSurfaceMuted, chipBgDefault);
                                  final Color labelColor = styles.$1;
                                  final Color labelBg = styles.$2;

                                  final String detailText = detail.contains(':')
                                      ? detail.substring(detail.indexOf(':') + 1).trim()
                                      : detail.trim();

                                  if (detailText.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: labelBg,
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: labelColor,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text.rich(
                                          _highlightNumerics(
                                              detailText, onSurfaceMuted),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                // soft internal divider to separate long content blocks
                                if (!isFocusArea && index < items.length - 1)
                                  Padding(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                    child: Divider(
                                      color: divider,
                                      thickness: 1,
                                      height: 12,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
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

}