import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/workout_planner_service.dart';

// --- Data Model for a single workout plan ---
class WorkoutPlan {
  final String id;
  final DateTime date;
  final Map<String, dynamic> data;

  WorkoutPlan({required this.id, required this.date, required this.data});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'],
      date: DateTime.parse(json['date']),
      data: Map<String, dynamic>.from(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'date': date.toIso8601String(), 'data': data};
  }
}

// --- Main Entry Point: History Page ---
class AiWorkoutPlannerPage extends StatefulWidget {
  const AiWorkoutPlannerPage({Key? key}) : super(key: key);

  @override
  State<AiWorkoutPlannerPage> createState() => _AiWorkoutPlannerPageState();
}

class _AiWorkoutPlannerPageState extends State<AiWorkoutPlannerPage> {
  List<WorkoutPlan> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('workoutPlanHistory') ?? '[]';
    final List<dynamic> historyJson = jsonDecode(historyString);
    setState(() {
      _history = historyJson.map((json) => WorkoutPlan.fromJson(json)).toList();
      _history.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  void _addPlan(WorkoutPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    _history.insert(0, plan);
    final String historyString = jsonEncode(_history.map((p) => p.toJson()).toList());
    await prefs.setString('workoutPlanHistory', historyString);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('AI Workout Planner', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _history.isEmpty
          ? Center(child: Text('No saved plans yet.', style: TextStyle(color: Colors.grey[500])))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final plan = _history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isDark ? Colors.grey[900] : Colors.grey[50],
            child: ListTile(
              title: Text(plan.data['planTitle'] ?? 'Workout Plan', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              subtitle: Text(DateFormat('MMM d, yyyy').format(plan.date), style: TextStyle(color: Colors.grey[500])),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[500]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutResultsPage(planData: plan.data))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPlan = await Navigator.push<WorkoutPlan>(context, MaterialPageRoute(builder: (_) => NewWorkoutPlanPage()));
          if (newPlan != null) {
            _addPlan(newPlan);
          }
        },
        backgroundColor: isDark ? Colors.white : Colors.black,
        child: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
      ),
    );
  }
}

// --- New Plan Creation Page (Step-by-Step) ---
class NewWorkoutPlanPage extends StatefulWidget {
  @override
  _NewWorkoutPlanPageState createState() => _NewWorkoutPlanPageState();
}

class _NewWorkoutPlanPageState extends State<NewWorkoutPlanPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isGenerating = false;

  // Form State
  String? _fitnessGoal;
  String? _fitnessLevel;
  String? _workoutType;
  int? _durationPerWorkout;
  String? _preferredTime;
  String? _planDuration;

  final List<String> _goals = ['Muscle Gain', 'Weight Loss', 'Strength and Endurance', 'Keep Fit'];
  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _types = ['Any', 'Gym Workout', 'Home Workout'];
  final List<int> _durations = [30, 45, 60, 75, 90];
  final List<String> _times = ['Any', 'Morning', 'Afternoon', 'Evening'];
  final List<String> _planDurations = ['3 Days', '5 Days', '7 Days', '14 Days', '21 Days'];

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please make a selection.'), backgroundColor: Colors.redAccent));
    }
  }

  void _previousPage() => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: return _fitnessGoal != null;
      case 1: return _fitnessLevel != null;
      case 2: return _workoutType != null;
      case 3: return _durationPerWorkout != null;
      case 4: return _preferredTime != null;
      case 5: return _planDuration != null;
      default: return false;
    }
  }

  Future<void> _generatePlan() async {
    if (!_validateCurrentPage()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please make a selection.'), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isGenerating = true);

    try {
      final planData = await WorkoutPlannerService.generateWorkoutPlan(
        fitnessGoals: _fitnessGoal!,
        fitnessLevel: _fitnessLevel!,
        workoutType: _workoutType!,
        planDuration: _planDuration!,
        durationPerWorkout: _durationPerWorkout,
        preferredTime: _preferredTime,
      );

      if (planData != null) {
        final newPlan = WorkoutPlan(id: DateTime.now().toIso8601String(), date: DateTime.now(), data: planData);
        if (mounted) {
          Navigator.pop(context, newPlan);
          Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutResultsPage(planData: planData)));
        }
      } else {
        throw Exception('Failed to generate plan.');
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final pages = [
      _buildSelectionPage(isDark, 'What is your main fitness goal?', _goals, _fitnessGoal, (val) => setState(() => _fitnessGoal = val)),
      _buildSelectionPage(isDark, 'What is your current fitness level?', _levels, _fitnessLevel, (val) => setState(() => _fitnessLevel = val)),
      _buildSelectionPage(isDark, 'What is your preferred workout type?', _types, _workoutType, (val) => setState(() => _workoutType = val)),
      _buildSelectionPage(isDark, 'How long is each workout session?', _durations.map((d) => '$d minutes').toList(), _durationPerWorkout != null ? '$_durationPerWorkout minutes' : null, (val) => setState(() => _durationPerWorkout = int.parse(val!.split(' ').first))),
      _buildSelectionPage(isDark, 'What time of day do you prefer?', _times, _preferredTime, (val) => setState(() => _preferredTime = val)),
      _buildSelectionPage(isDark, 'What is the total duration of the plan?', _planDurations, _planDuration, (val) => setState(() => _planDuration = val)),
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text('Create New Plan', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: LinearProgressIndicator(value: (_currentPage + 1) / pages.length, color: isDark ? Colors.white : Colors.black, backgroundColor: Colors.grey[300]),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: pages,
            ),
          ),
          _buildNavigationButtons(isDark, pages.length),
        ],
      ),
    );
  }

  Widget _buildSelectionPage(bool isDark, String title, List<String> options, String? groupValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                return RadioListTile<String>(
                  title: Text(option, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: isDark ? Colors.white : Colors.black,
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark, int pageCount) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(child: OutlinedButton(onPressed: _previousPage, child: Text('Back'), style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white : Colors.black, side: BorderSide(color: Colors.grey[400]!)))),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == pageCount - 1 ? _generatePlan : _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white : Colors.black, foregroundColor: isDark ? Colors.black : Colors.white),
              child: _isGenerating
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                  : Text(_currentPage == pageCount - 1 ? 'Generate Plan' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Results Display Page ---
class WorkoutResultsPage extends StatelessWidget {
  final Map<String, dynamic> planData;
  const WorkoutResultsPage({Key? key, required this.planData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final schedule = planData['weeklySchedule'] as List?;
    final tips = planData['generalTips'] as List?;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text('Your Workout Plan', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(planData['planTitle'] ?? 'Workout Plan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(planData['introduction'] ?? 'Here is your personalized workout plan.', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 24),

            Text('Weekly Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            if (schedule != null && schedule.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final day = schedule[index];
                  final details = day['details'] as List?;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isDark ? Colors.grey[900] : Colors.grey[50],
                    child: ExpansionTile(
                      title: Text('${day['day']}: ${day['activity']}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      subtitle: Text(day['duration'] ?? '', style: TextStyle(color: Colors.grey[500])),
                      children: details?.map((exercise) {
                        return ListTile(
                          title: Text(exercise['name'] ?? 'Exercise', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                          subtitle: Text(exercise['instruction'] ?? 'No instruction.', style: TextStyle(color: Colors.grey[500])),
                        );
                      }).toList() ?? [],
                    ),
                  );
                },
              )
            else
              Text('No schedule available.'),

            const SizedBox(height: 24),
            Text('General Tips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            if (tips != null && tips.isNotEmpty)
              ...tips.map((tip) => ListTile(
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text(tip, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              ))
            else
              Text('No tips available.'),
          ],
        ),
      ),
    );
  }
}