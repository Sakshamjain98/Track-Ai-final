import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/workout_planner_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

// --- Data Model for a single workout plan (Retained) ---
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

// NOTE: Placeholder for AppColors, assumed to be defined globally.
class AppColors {
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static Color background(bool isDark) => isDark ? Colors.black : Colors.white;
  static Color cardBackground(bool isDark) => isDark ? Colors.grey[900]! : Colors.grey[50]!;
  static Color borderColor(bool isDark) => isDark ? Colors.grey[800]! : Colors.grey[300]!;
}


// --- Main Results Display Page (Redesigned) ---
class WorkoutResultsPage extends StatelessWidget {
  final Map<String, dynamic> planData;
  const WorkoutResultsPage({Key? key, required this.planData}) : super(key: key);

  // --- NEW: Daily Schedule Card Builder (Black/White Style with Lock/Start) ---
  Widget _buildScheduleCard(BuildContext context, Map<String, dynamic> day, bool isDark, int dayIndex, bool isUnlocked) {
    final title = day['day'] ?? 'Day ${dayIndex + 1}';
    final subtitle = day['activity'] ?? 'Workout Session';
    final duration = day['duration'] ?? '';
    final isRestDay = subtitle.toLowerCase().contains('rest');

    final Color cardColor = isDark ? AppColors.cardBackground(isDark) : AppColors.white;
    final Color primaryColor = isDark ? AppColors.white : AppColors.black;
    final Color secondaryColor = Colors.grey[500]!;
    final Color actionColor = isUnlocked ? Colors.green.shade600 : primaryColor;

    Widget trailingWidget;
    if (isUnlocked) {
      trailingWidget = isRestDay
          ? Icon(lucide.LucideIcons.circleCheck, color: actionColor)
          : ElevatedButton(
        onPressed: () {
          // Action: Start Workout/Navigate to Details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting ${day['day']}...')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: actionColor,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      trailingWidget = Icon(lucide.LucideIcons.lock, color: secondaryColor);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnlocked && !isRestDay ? Colors.grey[100] : cardColor, // Highlight current/unlocked day slightly
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor(isDark), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
        subtitle: Text('$subtitle${duration.isNotEmpty ? ' | $duration' : ''}', style: TextStyle(color: secondaryColor, fontSize: 13)),
        trailing: trailingWidget,
        onTap: () {
          if (!isUnlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Complete previous day to unlock.')),
            );
          } else {
            // Optional: Navigate to a details screen even if it's a rest day.
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final schedule = planData['weeklySchedule'] as List?;
    final tips = planData['generalTips'] as List?;
    final planTitle = planData['planTitle'] ?? 'Your Workout Plan';
    final introduction = planData['introduction'] ?? 'Here is your personalized workout plan.';

    final Color primaryTextColor = isDark ? AppColors.white : AppColors.black;
    final Color secondaryTextColor = Colors.grey[500]!;

    // Mock progress to unlock days sequentially (Only Day 1 is unlocked initially)
    const int daysCompleted = 0; // Assume 0 days completed initially

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        title: Text('AI Workout Planner', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: primaryTextColor, size: 20), onPressed: () => Navigator.pop(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Black Banner Header (UI Fix)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: AppColors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(lucide.LucideIcons.armchair, size: 48, color: AppColors.white),
                  const SizedBox(height: 16),
                  Text(planTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white)),
                  const SizedBox(height: 12),
                  Text(introduction, style: TextStyle(fontSize: 16, color: Colors.grey[300])),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // 2. Action Buttons (Save/New Plan - Placeholder for functionality)
                  Row(
                    children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(lucide.LucideIcons.save), label: const Text('Save Plan'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: primaryTextColor, side: BorderSide(color: AppColors.borderColor(isDark))))),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(lucide.LucideIcons.refreshCw), label: const Text('New Plan'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 3. Weekly Schedule
                  Text('Workout Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  const SizedBox(height: 16),
                  if (schedule != null && schedule.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: schedule.length,
                      itemBuilder: (context, index) {
                        final day = schedule[index];
                        final isUnlocked = index <= daysCompleted; // Only Day 1 (index 0) is unlocked

                        return _buildScheduleCard(context, day, isDark, index, isUnlocked);
                      },
                    )
                  else
                    Text('No schedule available.', style: TextStyle(color: secondaryTextColor)),

                  const SizedBox(height: 32),

                  // 4. General Tips
                  Text('General Tips', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor)),
                  const SizedBox(height: 16),
                  if (tips != null && tips.isNotEmpty)
                    ...tips.map((tip) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(lucide.LucideIcons.check, color: Colors.green.shade600),
                      title: Text(tip, style: TextStyle(color: secondaryTextColor)),
                    ))
                  else
                    Text('No tips available.', style: TextStyle(color: secondaryTextColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Entry Point: History Page (Retained) ---
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
          // NOTE: Changed to push to a dummy NewWorkoutPlanPage for flow demonstration
          final newPlan = await Navigator.push<WorkoutPlan>(context, MaterialPageRoute(builder: (_) => DummyNewWorkoutPlanPage()));
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

// --- Dummy Page for New Plan Creation (Required for flow) ---
class DummyNewWorkoutPlanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creating New Plan...')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Simulate generating and popping a new plan
            final dummyPlan = WorkoutPlan(
                id: DateTime.now().toIso8601String(),
                date: DateTime.now(),
                data: {
                  'planTitle': 'Ignite Your Potential: 21-Day Full Body Transformation',
                  'introduction': 'Welcome to your 21-day full body transformation plan! This program is designed to help you achieve your weight loss goals while building strength and endurance. Remember to warm up before each workout with 5 minutes of light cardio and dynamic stretching, and cool down afterwards with 5 minutes of static stretching. Focus on proper form to prevent injuries and listen to your body – rest when you need to!',
                  'weeklySchedule': [
                    {'day': 'Day 1', 'activity': 'Full Body Strength', 'duration': '45 minutes'},
                    {'day': 'Day 2', 'activity': 'Upper body', 'duration': '45 minutes'},
                    {'day': 'Day 3', 'activity': 'Rest Day', 'duration': 'N/A'},
                    {'day': 'Day 4', 'activity': 'Lower Body Focus', 'duration': '60 minutes'},
                    {'day': 'Day 5', 'activity': 'Full Body Endurance', 'duration': '45 minutes'},
                    {'day': 'Day 6', 'activity': 'Rest Day', 'duration': 'N/A'},
                    {'day': 'Day 7', 'activity': 'Active Recovery', 'duration': '30 minutes'},
                  ],
                  'generalTips': ['Tip 1', 'Tip 2']
                }
            );
            Navigator.pop(context, dummyPlan);
            Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutResultsPage(planData: dummyPlan.data)));
          },
          child: const Text('Simulate Generate New Plan (21 Days)'),
        ),
      ),
    );
  }
}