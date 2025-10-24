// Fixed analytics_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math' as math;

class AnalyticsProvider extends ChangeNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get _currentUserId => _auth.currentUser?.uid;
  Color bmiStatusColor = Colors.grey;
  String bmiStatusLabel = "";

  // Removed the duplicate 'double? currentBMI;'

  // Removed the duplicate 'final TextEditingController heightCmController = TextEditingController();'
  // Removed the duplicate 'final TextEditingController weightController = TextEditingController();'

  // Private fields for BMI
  double? _currentBMI;
  String _heightUnit = 'Centimeters (cm)';
  String _weightUnit = 'Kilograms (kg)';
  final TextEditingController _heightCmController = TextEditingController();
  final TextEditingController _heightFeetController = TextEditingController();
  final TextEditingController _heightInchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();


  List<String> _selectedTrackers = [];
  String _selectedTimeframe = 'This Week';
  String _selectedAnalyticsType = 'Dashboard & Summary';
  Map<String, dynamic> _dashboardConfig = {};
  String _overallSummary = '';
  bool _isLoadingSummary = false;
  bool _isLoadingCorrelations = false;
  Map<String, List<Map<String, dynamic>>> _trackerData = {};
  List<Map<String, dynamic>> _correlationResults = [];
  Map<String, dynamic> _progressData = {};
  Map<String, dynamic> _periodData = {};

  // Period tracking - FIXED STATE MANAGEMENT
  bool _isLoggingPeriod = false;
  DateTime? _selectedPeriodDate;
  List<String> _selectedSymptoms = [];
  bool _isLoadingPeriodData = false;
  String? _cachedInsights; // Cache insights to prevent unnecessary regeneration
  DateTime? _lastInsightsUpdate; // Track when insights were last generated

  // Getters
  List<String> get selectedTrackers => _selectedTrackers;
  String get selectedTimeframe => _selectedTimeframe;
  String get selectedAnalyticsType => _selectedAnalyticsType;
  Map<String, dynamic> get dashboardConfig => _dashboardConfig;
  String get overallSummary => _overallSummary;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingCorrelations => _isLoadingCorrelations;
  Map<String, List<Map<String, dynamic>>> get trackerData => _trackerData;
  List<Map<String, dynamic>> get correlationResults => _correlationResults;
  Map<String, dynamic> get progressData => _progressData;
  Map<String, dynamic> get periodData => _periodData;
  bool get isLoggingPeriod => _isLoggingPeriod;
  bool get isLoadingPeriodData => _isLoadingPeriodData;
  DateTime? get selectedPeriodDate => _selectedPeriodDate;
  List<String> get selectedSymptoms => _selectedSymptoms;

  // BMI Getters (Used the existing private fields and their getters)
  double? get currentBMI => _currentBMI;
  String get heightUnit => _heightUnit;
  String get weightUnit => _weightUnit;
  TextEditingController get heightCmController => _heightCmController;
  TextEditingController get heightFeetController => _heightFeetController;
  TextEditingController get heightInchesController => _heightInchesController;
  TextEditingController get weightController => _weightController;

  final List<String> availableTrackers = [
    'Sleep Tracker',
    'Mood Tracker',
    'Meditation Tracker',
    'Expense Tracker',
    'Savings Tracker',
    'Alcohol Tracker',
    'Study Time Tracker',
    'Mental Well-being Tracker',
    'Workout Tracker',
    'Weight Tracker',
    'Menstrual Cycle',
  ];

  final List<String> analyticsTypes = [
    'Dashboard & Summary',

    'Progress Overview',

  ];

  final List<String> timeframes = [
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
  ];

  final List<String> periodSymptoms = [
    'Cramps',
    'Bloating',
    'Headache',
    'Mood swings',
    'Fatigue',
    'Back pain',
    'Breast tenderness',
    'Food cravings',
    'Acne',
    'Nausea',
  ];

  void setSelectedAnalyticsType(String type) {
    _selectedAnalyticsType = type;
    notifyListeners();

    switch (type) {
      case 'Dashboard & Summary':
        if (_selectedTrackers.isNotEmpty) {
          loadTrackerData();
          generateOverallSummary();
        }
        break;
      case 'Correlation Labs':
      // Don't auto-load for correlation labs, let user select trackers
        break;
      case 'Progress Overview':
        if (_selectedTrackers.isNotEmpty) {
          loadTrackerData().then((_) => loadProgressData());
        }
        break;
      case 'Period Cycle':
        loadPeriodData();
        break;
    }
  }

  void setSelectedTimeframe(String timeframe) {
    _selectedTimeframe = timeframe;
    // Clear cached insights when timeframe changes
    _cachedInsights = null;
    notifyListeners();
    if (_selectedTrackers.isNotEmpty) {
      loadTrackerData();
    }
  }

  // Consolidated BMI calculation logic, keeping the full implementation
  // and removing the duplicate basic one from the original code.
  Future<double?> calculateBMIForCmAndKg() async {
    try {
      double heightInMeters;
      double weightInKg;

      // Only supporting cm and kg units as in your image
      final heightCm = double.tryParse(heightCmController.text);
      final weight = double.tryParse(weightController.text);

      if (heightCm == null || heightCm <= 0 || weight == null || weight <= 0) {
        return null;
      }
      heightInMeters = heightCm / 100;
      weightInKg = weight;

      final bmi = weightInKg / (heightInMeters * heightInMeters);
      _currentBMI = bmi; // Use the private field

      // Update label and color according to BMI category
      if (bmi < 18.5) {
        bmiStatusLabel = "Underweight";
        bmiStatusColor = Colors.blue;
      } else if (bmi < 25) {
        bmiStatusLabel = "Healthy";
        bmiStatusColor = Colors.green;
      } else if (bmi < 30) {
        bmiStatusLabel = "Overweight";
        bmiStatusColor = Colors.orange;
      } else {
        bmiStatusLabel = "Obese";
        bmiStatusColor = Colors.red;
      }
      notifyListeners();
      return bmi;
    } catch (e) {
      debugPrint("Error calculating BMI: $e");
      return null;
    }
  }

  void toggleTrackerSelection(String tracker) {
    if (_selectedTrackers.contains(tracker)) {
      _selectedTrackers.remove(tracker);
    } else {
      _selectedTrackers.add(tracker);
    }
    _saveDashboardConfig();
    notifyListeners();
  }

  DateTime _getTimeframeStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'Last Week':
        return now.subtract(Duration(days: now.weekday + 6));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return lastMonth;
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Last 6 Months':
        return DateTime(now.year, now.month - 6, now.day);
      default:
        return now.subtract(Duration(days: 7));
    }
  }

  Future<void> loadDashboardConfig() async {
    if (_currentUserId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analytics_data')
          .doc('dashboard_config')
          .get();

      if (doc.exists) {
        _dashboardConfig = doc.data() ?? {};
        _selectedTrackers = List<String>.from(
          _dashboardConfig['selectedTrackers'] ?? [],
        );
        if (_selectedTrackers.isNotEmpty) {
          await loadTrackerData();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard config: $e');
    }
  }

  Future<void> _saveDashboardConfig() async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analytics_data')
          .doc('dashboard_config')
          .set({
        'selectedTrackers': _selectedTrackers,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving dashboard config: $e');
    }
  }

  Future<void> loadTrackerData() async {
    if (_currentUserId == null || _selectedTrackers.isEmpty) return;

    try {
      final Map<String, List<Map<String, dynamic>>> data = {};
      final startDate = _getTimeframeStartDate(_selectedTimeframe);

      for (String tracker in _selectedTrackers) {
        final trackerId = _getTrackerIdFromName(tracker);
        final entries = await _getTrackerEntries(trackerId, startDate);
        data[tracker] = entries;
        debugPrint('Loaded ${entries.length} entries for $tracker');
      }

      _trackerData = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tracker data: $e');
    }
  }

  Future<void> generateOverallSummary() async {
    if (_trackerData.isEmpty) return;

    _isLoadingSummary = true;
    notifyListeners();

    try {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiApiKey == null || geminiApiKey.isEmpty) {
        throw Exception('Gemini API key not found in .env file');
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: geminiApiKey);

      final prompt = _buildSummaryPrompt();
      final response = await model.generateContent([Content.text(prompt)]);

      _overallSummary = response.text ?? 'Unable to generate summary';
    } catch (e) {
      _overallSummary = 'Error generating summary: ${e.toString()}';
      debugPrint('Error generating summary: $e');
    }

    _isLoadingSummary = false;
    notifyListeners();
  }

  String _buildSummaryPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'Analyze the following tracking data and provide 3 concise insights in this format:',
    );
    buffer.writeln('1. One positive trend or achievement');
    buffer.writeln('2. One area that needs attention or improvement');
    buffer.writeln('3. One actionable recommendation');
    buffer.writeln('Keep each insight to 2 sentences maximum.\n');

    _trackerData.forEach((tracker, entries) {
      if (entries.isNotEmpty) {
        buffer.writeln(
          '$tracker (${entries.length} entries in ${_selectedTimeframe.toLowerCase()}):',
        );

        // Calculate basic stats
        final values = entries
            .map((e) => double.tryParse(e['value']?.toString() ?? '0') ?? 0.0)
            .where((v) => v > 0)
            .toList();

        if (values.isNotEmpty) {
          final avg = values.reduce((a, b) => a + b) / values.length;
          final min = values.reduce((a, b) => a < b ? a : b);
          final max = values.reduce((a, b) => a > b ? a : b);
          buffer.writeln(
            '  Average: ${avg.toStringAsFixed(1)}, Range: $min - $max',
          );
        }

        // Show recent entries
        for (int i = 0; i < entries.length && i < 3; i++) {
          final entry = entries[i];
          final date = DateTime.tryParse(entry['timestamp'] ?? '');
          final dateStr = date != null ? '${date.month}/${date.day}' : 'Recent';
          buffer.writeln('  $dateStr: ${entry['value'] ?? 'N/A'}');
        }
        buffer.writeln();
      }
    });

    return buffer.toString();
  }

  Future<List<Map<String, dynamic>>> _getTrackerEntries(
      String trackerId,
      DateTime startDate,
      ) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc(trackerId)
          .collection('entries')
          .where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      )
          .orderBy('timestamp', descending: true)
          .limit(100);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting tracker entries for $trackerId: $e');
      return [];
    }
  }

  String _getTrackerIdFromName(String trackerName) {
    final Map<String, String> trackerMap = {
      'Sleep Tracker': 'sleep',
      'Mood Tracker': 'mood',
      'Meditation Tracker': 'meditation',
      'Expense Tracker': 'expense',
      'Savings Tracker': 'savings',
      'Alcohol Tracker': 'alcohol',
      'Study Time Tracker': 'study',
      'Mental Well-being Tracker': 'mental_wellbeing',
      'Workout Tracker': 'workout',
      'Weight Tracker': 'weight',
      'Menstrual Cycle': 'menstrual',
    };
    return trackerMap[trackerName] ??
        trackerName.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> analyzeCorrelations() async {
    if (_selectedTrackers.length < 2) {
      debugPrint('Need at least 2 trackers for correlation analysis');
      return;
    }

    _isLoadingCorrelations = true;
    _correlationResults.clear();
    notifyListeners();

    try {
      debugPrint(
        'Starting correlation analysis with ${_selectedTrackers.length} trackers',
      );

      // Make sure we have fresh data
      await loadTrackerData();

      final List<Map<String, dynamic>> correlations = [];

      for (int i = 0; i < _selectedTrackers.length; i++) {
        for (int j = i + 1; j < _selectedTrackers.length; j++) {
          final tracker1 = _selectedTrackers[i];
          final tracker2 = _selectedTrackers[j];

          final data1 = _trackerData[tracker1] ?? [];
          final data2 = _trackerData[tracker2] ?? [];

          debugPrint(
            'Analyzing correlation between $tracker1 (${data1.length} entries) and $tracker2 (${data2.length} entries)',
          );

          if (data1.isNotEmpty && data2.isNotEmpty) {
            final correlation = _calculateCorrelation(data1, data2);
            debugPrint('Calculated correlation: $correlation');

            // Calculate stats and common dates for the correlation results
            final commonDates = _findCommonDates(data1, data2);
            final stats1 = _calculateTrackerStats(data1);
            final stats2 = _calculateTrackerStats(data2);

            // Generate AI insights for this correlation
            final insight = await _generateCorrelationInsight(
              tracker1,
              tracker2,
              correlation,
              data1,
              data2,
            );

            correlations.add({
              'tracker1': tracker1,
              'tracker2': tracker2,
              'correlation': correlation,
              'strength': _getCorrelationStrength(correlation),
              'insight': insight,
              'dataPoints': commonDates['count'],
              'trend': '${stats1['trend']} vs ${stats2['trend']}',
            });
          }
        }
      }

      _correlationResults = correlations;
      debugPrint('Generated ${correlations.length} correlation results');
    } catch (e) {
      debugPrint('Error analyzing correlations: $e');
    }

    _isLoadingCorrelations = false;
    notifyListeners();
  }

  Future<String> _generateCorrelationInsight(
      String tracker1,
      String tracker2,
      double correlation,
      List<Map<String, dynamic>> data1,
      List<Map<String, dynamic>> data2,
      ) async {
    try {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiApiKey == null || geminiApiKey.isEmpty) {
        return _getDefaultCorrelationInsight(tracker1, tracker2, correlation);
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: geminiApiKey);

      final strength = _getCorrelationStrength(correlation);
      final direction = correlation > 0 ? 'positive' : 'negative';
      final commonDates = _findCommonDates(data1, data2);

      // Calculate basic statistics for both trackers
      final stats1 = _calculateTrackerStats(data1);
      final stats2 = _calculateTrackerStats(data2);

      final prompt =
      '''
I need you to analyze the correlation between two health/lifestyle trackers and provide detailed, actionable insights.

TRACKER ANALYSIS:
Tracker 1: $tracker1
- Entries: ${data1.length}
- Average: ${stats1['average']?.toStringAsFixed(2)}
- Range: ${stats1['min']} - ${stats1['max']}
- Recent trend: ${stats1['trend']}

Tracker 2: $tracker2  
- Entries: ${data2.length}
- Average: ${stats2['average']?.toStringAsFixed(2)}
- Range: ${stats2['min']} - ${stats2['max']}
- Recent trend: ${stats2['trend']}

CORRELATION ANALYSIS:
- Correlation coefficient: ${correlation.toStringAsFixed(3)}
- Strength: $strength
- Direction: $direction
- Data points used: ${commonDates['count']}
- Timeframe: ${_selectedTimeframe}

REQUESTED INSIGHT FORMAT:
Please provide a comprehensive analysis with these sections:

1. **Relationship Interpretation**: Explain what this correlation might mean in practical terms for these specific trackers. Consider common physiological or psychological connections.

2. **Actionable Recommendations**: Provide 2-3 specific, practical suggestions the user could implement based on this relationship. Make them concrete and measurable.

3. **Potential Caveats**: Mention any limitations or considerations about this correlation (sample size, timeframe, external factors).

4. **Monitoring Suggestions**: Suggest how the user could track this relationship going forward and what to look for.

Keep the tone professional yet accessible, and focus on practical wellness applications. Each section should be 2-3 sentences maximum.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ??
          _getDefaultCorrelationInsight(tracker1, tracker2, correlation);
    } catch (e) {
      debugPrint('Error generating correlation insight: $e');
      return _getDefaultCorrelationInsight(tracker1, tracker2, correlation);
    }
  }

  Map<String, dynamic> _findCommonDates(
      List<Map<String, dynamic>> data1,
      List<Map<String, dynamic>> data2,
      ) {
    final Map<String, double> values1 = {};
    final Map<String, double> values2 = {};

    for (var entry in data1) {
      final date = entry['timestamp']?.toString().split('T')[0];
      final value = double.tryParse(entry['value']?.toString() ?? '0') ?? 0.0;
      if (date != null && value > 0) {
        values1[date] = value;
      }
    }

    for (var entry in data2) {
      final date = entry['timestamp']?.toString().split('T')[0];
      final value = double.tryParse(entry['value']?.toString() ?? '0') ?? 0.0;
      if (date != null && value > 0) {
        values2[date] = value;
      }
    }

    final commonDates = values1.keys.toSet().intersection(values2.keys.toSet());

    return {'dates': commonDates.toList(), 'count': commonDates.length};
  }

  Map<String, dynamic> _calculateTrackerStats(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {'average': 0, 'min': 0, 'max': 0, 'trend': 'Insufficient data'};
    }

    final values = data
        .map((e) => double.tryParse(e['value']?.toString() ?? '0') ?? 0.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) {
      return {'average': 0, 'min': 0, 'max': 0, 'trend': 'No valid values'};
    }

    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    String trend = 'Stable';
    if (values.length >= 4) {
      final half = (values.length / 2).floor();
      final firstHalfAvg =
          values.sublist(0, half).reduce((a, b) => a + b) / half;
      final secondHalfAvg =
          values.sublist(half).reduce((a, b) => a + b) / (values.length - half);

      if (secondHalfAvg > firstHalfAvg * 1.1)
        trend = 'Increasing';
      else if (secondHalfAvg < firstHalfAvg * 0.9) trend = 'Decreasing';
    }

    return {'average': avg, 'min': min, 'max': max, 'trend': trend};
  }

  String _getDefaultCorrelationInsight(
      String tracker1,
      String tracker2,
      double correlation,
      ) {
    final strength = _getCorrelationStrength(correlation);
    final direction = correlation > 0 ? 'positive' : 'negative';
    return '$strength $direction correlation detected between $tracker1 and $tracker2. Consider how changes in one might affect the other.';
  }

  double _calculateCorrelation(
      List<Map<String, dynamic>> data1,
      List<Map<String, dynamic>> data2,
      ) {
    try {
      final Map<String, double> values1 = {};
      final Map<String, double> values2 = {};

      for (var entry in data1) {
        final date = entry['timestamp']?.toString().split('T')[0];
        final value = double.tryParse(entry['value']?.toString() ?? '0') ?? 0.0;
        if (date != null && value > 0) {
          values1[date] = value;
        }
      }

      for (var entry in data2) {
        final date = entry['timestamp']?.toString().split('T')[0];
        final value = double.tryParse(entry['value']?.toString() ?? '0') ?? 0.0;
        if (date != null && value > 0) {
          values2[date] = value;
        }
      }

      final commonDates = values1.keys
          .toSet()
          .intersection(values2.keys.toSet())
          .toList();

      debugPrint('Found ${commonDates.length} common dates for correlation');

      if (commonDates.length < 2) return 0.0;

      final List<double> x = commonDates.map((date) => values1[date]!).toList();
      final List<double> y = commonDates.map((date) => values2[date]!).toList();

      if (x.isEmpty || y.isEmpty) return 0.0;

      final double meanX = x.reduce((a, b) => a + b) / x.length;
      final double meanY = y.reduce((a, b) => a + b) / y.length;

      double numerator = 0.0;
      double sumSqX = 0.0;
      double sumSqY = 0.0;

      for (int i = 0; i < x.length; i++) {
        final diffX = x[i] - meanX;
        final diffY = y[i] - meanY;
        numerator += diffX * diffY;
        sumSqX += diffX * diffX;
        sumSqY += diffY * diffY;
      }

      final denominator = math.sqrt(sumSqX * sumSqY);
      final correlation = denominator > 0 ? numerator / denominator : 0.0;

      return correlation.clamp(-1.0, 1.0);
    } catch (e) {
      debugPrint('Error calculating correlation: $e');
      return 0.0;
    }
  }

  String _getCorrelationStrength(double correlation) {
    final abs = correlation.abs();
    if (abs >= 0.7) return 'Strong';
    if (abs >= 0.4) return 'Moderate';
    if (abs >= 0.2) return 'Weak';
    return 'Very Weak';
  }

  Future<void> loadProgressData() async {
    try {
      final Map<String, dynamic> progress = {};

      for (String tracker in _selectedTrackers) {
        final trackerId = _getTrackerIdFromName(tracker);

        final thisWeekStart = DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1),
        );
        final lastWeekStart = thisWeekStart.subtract(Duration(days: 7));

        final allEntries = await _getTrackerEntries(
          trackerId,
          lastWeekStart.subtract(Duration(days: 30)),
        );

        final thisWeekData = allEntries.where((entry) {
          final date = DateTime.tryParse(entry['timestamp'] ?? '');
          return date != null && date.isAfter(thisWeekStart);
        }).toList();

        final lastWeekData = allEntries.where((entry) {
          final date = DateTime.tryParse(entry['timestamp'] ?? '');
          return date != null &&
              date.isAfter(lastWeekStart) &&
              date.isBefore(thisWeekStart);
        }).toList();

        if (allEntries.isNotEmpty) {
          progress[tracker] = {
            'thisWeek': thisWeekData,
            'lastWeek': lastWeekData,
            'total': allEntries.length,
            'average': _calculateAverage(allEntries),
            'thisWeekAvg': _calculateAverage(thisWeekData),
            'lastWeekAvg': _calculateAverage(lastWeekData),
          };
        }
      }

      _progressData = progress;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    }
  }

  double _calculateAverage(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 0.0;

    final values = entries
        .map((e) => double.tryParse(e['value']?.toString() ?? '0') ?? 0.0)
        .where((v) => v > 0)
        .toList();

    return values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
  }

  // FIXED PERIOD TRACKING METHODS
  void setSelectedPeriodDate(DateTime? date) {
    _selectedPeriodDate = date;
    notifyListeners();
  }

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    // Clear cached insights when symptoms change
    _cachedInsights = null;
    notifyListeners();
  }

  // COMPLETELY REWRITTEN LOG PERIOD ENTRY METHOD
  Future<void> logPeriodEntry() async {
    if (_currentUserId == null || _selectedPeriodDate == null) {
      debugPrint('Cannot log period: missing user ID or date');
      return;
    }

    // Prevent multiple simultaneous operations
    if (_isLoggingPeriod) {
      debugPrint('Already logging period entry, skipping');
      return;
    }

    _isLoggingPeriod = true;
    notifyListeners();

    try {
      debugPrint('Starting to log period entry for date: $_selectedPeriodDate');

      // Calculate cycle day based on previous entries
      final previousEntries = await _getTrackerEntries(
        'menstrual',
        DateTime.now().subtract(Duration(days: 365)),
      );

      int cycleDay = 1;
      String phase = 'Menstrual';

      if (previousEntries.isNotEmpty) {
        // Find the most recent period start
        final periodStartEntries = previousEntries
            .where((entry) => entry['value'] == 'Period Start')
            .toList();

        if (periodStartEntries.isNotEmpty) {
          // Sort by timestamp to get the most recent
          periodStartEntries.sort((a, b) {
            final dateA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
            return dateB.compareTo(dateA); // Most recent first
          });

          final lastPeriodEntry = periodStartEntries.first;
          final lastDate = DateTime.tryParse(lastPeriodEntry['timestamp'] ?? '');

          if (lastDate != null) {
            cycleDay = _selectedPeriodDate!.difference(lastDate).inDays + 1;
            phase = _getCyclePhase(cycleDay);
            debugPrint('Calculated cycle day: $cycleDay, phase: $phase');
          }
        }
      }

      // Create the new entry
      final entryData = {
        'timestamp': Timestamp.fromDate(_selectedPeriodDate!),
        'value': 'Period Start',
        'symptoms': List.from(_selectedSymptoms), // Create a copy
        'cycleDay': cycleDay,
        'phase': phase,
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('Adding entry to Firestore: $entryData');

      // Add to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tracking')
          .doc('menstrual')
          .collection('entries')
          .add(entryData);

      debugPrint('Successfully added period entry with ID: ${docRef.id}');

      // CRITICAL: Clear form state BEFORE reloading data
      // Removed unused local variables tempDate and tempSymptoms
      _selectedPeriodDate = null;
      _selectedSymptoms.clear();
      _cachedInsights = null; // Force insights regeneration
      _lastInsightsUpdate = null;

      debugPrint('Cleared form state - Date: $_selectedPeriodDate, Symptoms: $_selectedSymptoms');

      // Reset loading state BEFORE reload to prevent UI issues
      _isLoggingPeriod = false;
      notifyListeners(); // Notify immediately so UI updates

      // Now reload the period data with fresh insights
      await loadPeriodData(forceRefresh: true);

      debugPrint('Period entry logging completed successfully');

    } catch (e) {
      debugPrint('Error logging period entry: $e');
      // Reset loading state on error
      _isLoggingPeriod = false;
      notifyListeners();
      rethrow; // Re-throw so UI can handle the error
    }
  }

  // IMPROVED LOAD PERIOD DATA WITH FORCED REFRESH OPTION
  Future<void> loadPeriodData({bool forceRefresh = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoadingPeriodData && !forceRefresh) {
      debugPrint('Already loading period data, skipping');
      return;
    }

    _isLoadingPeriodData = true;
    if (forceRefresh) {
      _cachedInsights = null;
      _lastInsightsUpdate = null;
    }
    notifyListeners();

    try {
      debugPrint('Loading period data...');

      final entries = await _getTrackerEntries(
        'menstrual',
        DateTime.now().subtract(Duration(days: 365)),
      );

      debugPrint('Retrieved ${entries.length} menstrual entries');

      final Map<String, dynamic> periodAnalysis = {};

      if (entries.isNotEmpty) {
        // Analyze period cycle data
        final cycles = _analyzeMenstrualCycles(entries);
        periodAnalysis['cycles'] = cycles;
        periodAnalysis['averageCycleLength'] = _calculateAverageCycleLength(cycles);
        periodAnalysis['nextPredictedPeriod'] = _predictNextPeriod(cycles);
        periodAnalysis['recentEntries'] = entries.take(10).toList();

        debugPrint('Analysis complete - Cycles: ${cycles.length}, Avg length: ${periodAnalysis['averageCycleLength']}');

        // Only generate new insights if we don't have cached ones or if forced refresh
        if (_cachedInsights == null || forceRefresh) {
          debugPrint('Generating fresh period insights...');
          final insights = await _generatePeriodInsights(entries, cycles);
          _cachedInsights = insights;
          _lastInsightsUpdate = DateTime.now();
          periodAnalysis['insights'] = insights;
        } else {
          debugPrint('Using cached period insights');
          periodAnalysis['insights'] = _cachedInsights;
        }
      } else {
        periodAnalysis['cycles'] = [];
        periodAnalysis['averageCycleLength'] = 28.0;
        periodAnalysis['nextPredictedPeriod'] = null;
        periodAnalysis['recentEntries'] = [];
        periodAnalysis['insights'] = 'Start logging your cycle to get personalized insights about your menstrual health.';
      }

      _periodData = periodAnalysis;
      debugPrint('Period data loaded successfully');
    } catch (e) {
      debugPrint('Error loading period data: $e');
    }

    _isLoadingPeriodData = false;
    notifyListeners();
  }

  // OPTIMIZED INSIGHTS GENERATION WITH CACHING
  Future<String> _generatePeriodInsights(
      List<Map<String, dynamic>> entries,
      List<Map<String, dynamic>> cycles,
      ) async {
    // Check if we have recent cached insights (within 1 hour)
    if (_cachedInsights != null && _lastInsightsUpdate != null) {
      final hoursSinceUpdate = DateTime.now().difference(_lastInsightsUpdate!).inHours;
      if (hoursSinceUpdate < 1) {
        debugPrint('Using cached insights (generated ${hoursSinceUpdate} hours ago)');
        return _cachedInsights!;
      }
    }

    try {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiApiKey == null || geminiApiKey.isEmpty) {
        return _generateDetailedOfflineInsights(entries, cycles);
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: geminiApiKey);

      final averageLength = _calculateAverageCycleLength(cycles);
      final symptomCounts = <String, int>{};
      final phaseCounts = <String, int>{};
      final recentDates = <DateTime>[];

      for (var entry in entries) {
        final symptoms = List<String>.from(entry['symptoms'] ?? []);
        for (var symptom in symptoms) {
          symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
        }

        final date = DateTime.tryParse(entry['timestamp'] ?? '');
        if (date != null) recentDates.add(date);
      }

      for (var cycle in cycles) {
        final phase = cycle['phase'] ?? 'Unknown';
        phaseCounts[phase] = (phaseCounts[phase] ?? 0) + 1;
      }

      recentDates.sort((a, b) => b.compareTo(a));
      final trackingDays = recentDates.isNotEmpty ?
      DateTime.now().difference(recentDates.last).inDays : 0;

      final topSymptoms = symptomCounts.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final prompt = '''
As a women's health AI assistant, analyze this detailed menstrual cycle data and provide comprehensive, personalized insights:

**CYCLE DATA ANALYSIS:**
• Total period entries logged: ${entries.length}
• Tracking duration: $trackingDays days
• Average cycle length: ${averageLength.toStringAsFixed(1)} days
• Cycle phases tracked: ${phaseCounts.keys.join(', ')}

**SYMPTOM PATTERNS:**
${topSymptoms.take(5).map((e) => '• ${e.key}: ${e.value} occurrences').join('\n')}

**RECENT TRACKING BEHAVIOR:**
• Most recent entry: ${recentDates.isNotEmpty ? recentDates.first.toString().split(' ')[0] : 'None'}
• Consistency: ${entries.length >= 3 ? 'Good tracking habits' : 'Building tracking routine'}

**REQUESTED ANALYSIS:**
Please provide a comprehensive response covering:

1. **Cycle Health Assessment** (2-3 sentences):
   - Evaluate cycle regularity and what it indicates about hormonal health
   - Compare to healthy ranges and note any patterns

2. **Symptom Pattern Insights** (2-3 sentences):
   - Analyze most common symptoms and their timing
   - Provide specific management strategies for top symptoms

3. **Personalized Recommendations** (3-4 actionable points):
   - Lifestyle adjustments based on cycle patterns
   - Tracking improvements to gather better insights
   - Phase-specific optimization tips
   - When to consult healthcare providers

4. **Future Predictions & Goals** (2 sentences):
   - What patterns to watch for with continued tracking
   - Timeline for more reliable cycle predictions

Keep the tone supportive, educational, and medically appropriate. Focus on actionable insights that empower better cycle management. Use specific data points from the analysis above.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final insights = response.text ?? _generateDetailedOfflineInsights(entries, cycles);

      // Cache the insights
      _cachedInsights = insights;
      _lastInsightsUpdate = DateTime.now();

      return insights;
    } catch (e) {
      debugPrint('Error generating period insights: $e');
      return _generateDetailedOfflineInsights(entries, cycles);
    }
  }

  String _generateDetailedOfflineInsights(
      List<Map<String, dynamic>> entries,
      List<Map<String, dynamic>> cycles,
      ) {
    final insights = StringBuffer();
    final averageLength = _calculateAverageCycleLength(cycles);
    final symptomCounts = <String, int>{};
    final dates = <DateTime>[];

    for (var entry in entries) {
      final symptoms = List<String>.from(entry['symptoms'] ?? []);
      for (var symptom in symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }

      final date = DateTime.tryParse(entry['timestamp'] ?? '');
      if (date != null) dates.add(date);
    }

    dates.sort();
    final trackingDays = dates.isNotEmpty ? dates.last.difference(dates.first).inDays : 0;
    final topSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Cycle Health Assessment
    insights.writeln('**CYCLE HEALTH ASSESSMENT**');
    if (entries.length >= 3) {
      if (averageLength >= 21 && averageLength <= 35) {
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle falls within the healthy range (21-35 days), indicating balanced hormonal function. ');
      } else if (averageLength < 21) {
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle is shorter than typical. Continue tracking for 2-3 cycles to establish your personal pattern. ');
      } else {
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle is longer than average, which can be normal but worth monitoring. ');
      }
      insights.writeln('With ${entries.length} entries over $trackingDays days, you\'re building valuable data about your body\'s patterns.\n');
    } else {
      insights.writeln('You\'re just starting your cycle tracking journey! Each entry helps build a clearer picture of your hormonal patterns and cycle regularity.\n');
    }

    // Symptom Analysis
    insights.writeln('**SYMPTOM INSIGHTS**');
    if (topSymptoms.isNotEmpty) {
      final mainSymptom = topSymptoms.first;
      insights.writeln('Your most common symptom is ${mainSymptom.key} (${mainSymptom.value} times logged). ');

      // Symptom-specific advice
      switch (mainSymptom.key.toLowerCase()) {
        case 'cramps':
          insights.writeln('For cramp management: try heat therapy, magnesium supplements, gentle yoga, and anti-inflammatory foods like ginger and leafy greens.');
          break;
        case 'mood swings':
          insights.writeln('For mood balance: maintain stable blood sugar with regular meals, prioritize sleep, and consider stress-reduction techniques during your luteal phase.');
          break;
        case 'bloating':
          insights.writeln('For bloating relief: reduce sodium intake 5-7 days before your period, stay hydrated, and include potassium-rich foods like bananas and spinach.');
          break;
        case 'fatigue':
          insights.writeln('For energy support: ensure adequate iron and B-vitamin intake, maintain consistent sleep schedules, and consider lighter exercise during low-energy phases.');
          break;
        case 'headache':
          insights.writeln('For headache prevention: track triggers like dehydration or hormonal drops, maintain consistent sleep, and consider magnesium supplementation.');
          break;
        default:
          insights.writeln('Track when this symptom occurs in your cycle to identify patterns and develop targeted management strategies.');
      }

      if (topSymptoms.length > 1) {
        insights.writeln(' You also frequently experience ${topSymptoms[1].key}, suggesting a pattern worth discussing with your healthcare provider.\n');
      } else {
        insights.writeln('\n');
      }
    } else {
      insights.writeln('No symptoms logged yet. Consider tracking common symptoms like cramps, mood changes, or energy levels to gain deeper insights into your cycle patterns.\n');
    }

    // Personalized Recommendations
    insights.writeln('**PERSONALIZED RECOMMENDATIONS**');
    insights.writeln('• **Continue Consistent Tracking**: Log periods and symptoms for at least 3 cycles to establish reliable patterns and predictions.');

    if (entries.length < 5) {
      insights.writeln('• **Expand Symptom Tracking**: Include mood, energy levels, sleep quality, and appetite changes to understand your body\'s full cycle story.');
    }

    insights.writeln('• **Lifestyle Optimization**: Plan important events around your high-energy phases (follicular/ovulation) and schedule self-care during your luteal phase.');

    if (symptomCounts.isNotEmpty) {
      insights.writeln('• **Symptom Management**: Create a personalized toolkit based on your tracked symptoms - keep remedies ready before symptoms typically appear.');
    }

    if (averageLength < 21 || averageLength > 35) {
      insights.writeln('• **Healthcare Consultation**: Consider discussing your cycle length with a healthcare provider to rule out any underlying conditions.');
    }

    // Future Predictions
    insights.writeln('\n**FUTURE TRACKING GOALS**');
    if (entries.length < 10) {
      insights.writeln('With ${10 - entries.length} more entries, you\'ll have enough data for reliable period predictions and personalized health insights. ');
      insights.writeln('By tracking for 3-6 months, you\'ll identify seasonal patterns, stress impacts, and optimize your lifestyle around your natural rhythms.');
    } else {
      insights.writeln('You have excellent tracking data! Focus on identifying how external factors (stress, diet, exercise) influence your cycle patterns. ');
      insights.writeln('Continue monitoring to detect any changes that might indicate hormonal shifts or health changes worth discussing with your doctor.');
    }

    return insights.toString();
  }

  List<Map<String, dynamic>> _analyzeMenstrualCycles(
      List<Map<String, dynamic>> entries,
      ) {
    final cycles = <Map<String, dynamic>>[];

    // Sort entries by date (oldest first) for proper cycle calculation
    entries.sort((a, b) {
      final dateA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    DateTime? lastPeriodStart;

    for (var entry in entries) {
      final entryDate = DateTime.tryParse(entry['timestamp'] ?? '');
      if (entryDate == null) continue;

      int cycleDay = 1;
      if (entry['value'] == 'Period Start') {
        lastPeriodStart = entryDate;
        cycleDay = 1;
      } else if (lastPeriodStart != null) {
        cycleDay = entryDate.difference(lastPeriodStart).inDays + 1;
      }

      cycles.add({
        'date': entry['timestamp'],
        'cycleDay': cycleDay,
        'phase': _getCyclePhase(cycleDay),
        'symptoms': entry['symptoms'] ?? [],
        'value': entry['value'],
      });
    }

    return cycles;
  }

  String _getCyclePhase(int cycleDay) {
    if (cycleDay >= 1 && cycleDay <= 7) return 'Menstrual';
    if (cycleDay >= 8 && cycleDay <= 13) return 'Follicular';
    if (cycleDay >= 14 && cycleDay <= 16) return 'Ovulation';
    if (cycleDay >= 17 && cycleDay <= 28) return 'Luteal';
    return 'Unknown';
  }

  double _calculateAverageCycleLength(List<Map<String, dynamic>> cycles) {
    if (cycles.length < 2) return 28.0;

    final periodStarts = cycles
        .where((cycle) => cycle['value'] == 'Period Start')
        .map((cycle) => DateTime.tryParse(cycle['date']))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (periodStarts.length < 2) return 28.0;

    final cycleLengths = <int>[];
    for (int i = 1; i < periodStarts.length; i++) {
      final diff = periodStarts[i].difference(periodStarts[i - 1]).inDays;
      if (diff > 15 && diff < 50) {
        cycleLengths.add(diff);
      }
    }

    return cycleLengths.isEmpty
        ? 28.0
        : cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
  }

  DateTime? _predictNextPeriod(List<Map<String, dynamic>> cycles) {
    final periodStarts = cycles
        .where((cycle) => cycle['value'] == 'Period Start')
        .map((cycle) => DateTime.tryParse(cycle['date']))
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    if (periodStarts.isEmpty) return null;

    periodStarts.sort();
    final lastPeriod = periodStarts.last;
    final averageLength = _calculateAverageCycleLength(cycles);
    return lastPeriod.add(Duration(days: averageLength.round()));
  }

  // BMI Calculator Methods
  void setHeightUnit(String unit) {
    _heightUnit = unit;
    notifyListeners();
  }

  void setWeightUnit(String unit) {
    _weightUnit = unit;
    notifyListeners();
  }

  // The comprehensive calculateBMI method, renamed to be distinct
  // from the public getter and to support all units.
  @override
  Future<double?> calculateBMI() async {
    try {
      double heightInMeters;
      double weightInKg;

      if (_heightUnit == 'Centimeters (cm)') {
        final heightCm = double.tryParse(_heightCmController.text);
        if (heightCm == null || heightCm <= 0) return null;
        heightInMeters = heightCm / 100;
      } else {
        final feet = double.tryParse(_heightFeetController.text) ?? 0;
        final inches = double.tryParse(_heightInchesController.text) ?? 0;
        if (feet <= 0 && inches <= 0) return null;
        heightInMeters = (feet * 0.3048) + (inches * 0.0254);
      }

      final weight = double.tryParse(_weightController.text);
      if (weight == null || weight <= 0) return null;

      if (_weightUnit == 'Pounds (lbs)') {
        weightInKg = weight * 0.453592;
      } else {
        weightInKg = weight;
      }

      final bmi = weightInKg / (heightInMeters * heightInMeters);
      _currentBMI = bmi;

      // Update label and color according to BMI category
      if (bmi < 18.5) {
        bmiStatusLabel = "Underweight";
        bmiStatusColor = Colors.blue;
      } else if (bmi < 25) {
        bmiStatusLabel = "Healthy";
        bmiStatusColor = Colors.green;
      } else if (bmi < 30) {
        bmiStatusLabel = "Overweight";
        bmiStatusColor = Colors.orange;
      } else {
        bmiStatusLabel = "Obese";
        bmiStatusColor = Colors.red;
      }

      await _saveBMIToFirebase(bmi);

      notifyListeners();
      return bmi;
    } catch (e) {
      debugPrint('Error calculating BMI: $e');
      return null;
    }
  }

  Future<void> _saveBMIToFirebase(double bmi) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analytics_data')
          .doc('bmi_data')
          .set({
        'currentBMI': bmi,
        'heightUnit': _heightUnit,
        'weightUnit': _weightUnit,
        'heightCm': _heightCmController.text,
        'heightFeet': _heightFeetController.text,
        'heightInches': _heightInchesController.text,
        'weight': _weightController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving BMI to Firebase: $e');
    }
  }

  Future<void> loadBMIData() async {
    if (_currentUserId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analytics_data')
          .doc('bmi_data')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _currentBMI = data['currentBMI']?.toDouble();
        _heightUnit = data['heightUnit'] ?? 'Centimeters (cm)';
        _weightUnit = data['weightUnit'] ?? 'Kilograms (kg)';
        _heightCmController.text = data['heightCm'] ?? '';
        _heightFeetController.text = data['heightFeet'] ?? '';
        _heightInchesController.text = data['heightInches'] ?? '';
        _weightController.text = data['weight'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading BMI data: $e');
    }
  }

  // Additional helper methods for better state management
  Future<Map<String, dynamic>> getNutritionData(String timeframe) async {
    if (_currentUserId == null) return {};

    try {
      final startDate = _getTimeframeStartDate(timeframe);
      final nutritionEntries = await _getTrackerEntries('nutrition', startDate);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      final dailyCalories = <String, double>{};

      for (var entry in nutritionEntries) {
        final calories = double.tryParse(entry['calories']?.toString() ?? '0') ?? 0;
        final protein = double.tryParse(entry['protein']?.toString() ?? '0') ?? 0;
        final carbs = double.tryParse(entry['carbs']?.toString() ?? '0') ?? 0;
        final fat = double.tryParse(entry['fat']?.toString() ?? '0') ?? 0;

        totalCalories += calories;
        totalProtein += protein;
        totalCarbs += carbs;
        totalFat += fat;

        final date = DateTime.tryParse(entry['timestamp'] ?? '')?.toIso8601String().split('T')[0];
        if (date != null) {
          dailyCalories[date] = (dailyCalories[date] ?? 0) + calories;
        }
      }

      final days = nutritionEntries.isNotEmpty ? nutritionEntries.length : 1;

      return {
        'totalCalories': totalCalories,
        'dailyAverage': totalCalories / days,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'dailyCalories': dailyCalories,
        'entries': nutritionEntries.length,
      };
    } catch (e) {
      debugPrint('Error getting nutrition data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getEnhancedProgressData(String tracker) async {
    final progressData = _progressData[tracker];
    if (progressData == null) return {};

    try {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
        final model = GenerativeModel(model: 'gemini-pro', apiKey: geminiApiKey);

        final prompt = '''
Analyze this progress data for $tracker and provide insights:

Timeframe: $_selectedTimeframe
This week entries: ${progressData['thisWeek']?.length ?? 0}
Last week entries: ${progressData['lastWeek']?.length ?? 0}
Total entries: ${progressData['total'] ?? 0}
Average value: ${progressData['average']?.toStringAsFixed(1) ?? '0'}

Provide a brief analysis (2-3 sentences) about the progress trends and a practical recommendation.
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final insights = response.text ?? 'No insights available';

        return {
          ...progressData,
          'insights': insights,
          'trend': _calculateTrend(progressData),
        };
      }
    } catch (e) {
      debugPrint('Error generating progress insights: $e');
    }

    return progressData;
  }

  String _calculateTrend(Map<String, dynamic> progressData) {
    final thisWeek = progressData['thisWeekAvg'] ?? 0;
    final lastWeek = progressData['lastWeekAvg'] ?? 0;

    if (thisWeek > lastWeek * 1.1) return 'improving';
    if (thisWeek < lastWeek * 0.9) return 'declining';
    return 'stable';
  }

  // Method to force refresh all data (useful for debugging)
  Future<void> forceRefreshAllData() async {
    _cachedInsights = null;
    _lastInsightsUpdate = null;
    await loadPeriodData(forceRefresh: true);
    if (_selectedTrackers.isNotEmpty) {
      await loadTrackerData();
    }
  }
  void clearAllData() {
    _selectedTrackers.clear();
    _trackerData.clear();
    _periodData.clear();
    _progressData.clear();
    _correlationResults.clear();
    _cachedInsights = null;
    _lastInsightsUpdate = null;
    _selectedPeriodDate = null;
    _selectedSymptoms.clear();
    _isLoggingPeriod = false;
    _isLoadingPeriodData = false;
    notifyListeners();
  }
}