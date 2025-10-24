import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'package:trackai/features/home/ai-options/service/workout_planner_service.dart';

class Smartgymkit extends StatefulWidget {
  const Smartgymkit({Key? key}) : super(key: key);

  @override
  State<Smartgymkit> createState() => _SmartgymkitState();
}

class _SmartgymkitState extends State<Smartgymkit> {
  final PageController _pageController = PageController();

  // State variables
  int _currentPage = 0;
  bool _isGenerating = false;
  Map<String, dynamic>? _results;

  // Form Variables
  final TextEditingController _fitnessGoalsController = TextEditingController();
  String _selectedFitnessLevel = '';
  String _selectedWorkoutType = '';
  String _selectedWorkoutDuration = '';
  String _selectedPreferredTime = '';
  String _selectedPlanDuration = '';

  // Options
  final List<String> _fitnessLevels = ['Beginner (0-6 months)', 'Intermediate (6 months - 2 years)', 'Advanced (2-5 years)', 'Expert (5+ years)'];
  final List<String> _workoutTypes = ['Any', 'Home Workout', 'Gym Workout', 'Calisthenics', 'Strength Training', 'Cardio Focus', 'Hybrid Training'];
  final List<String> _workoutDurations = ['30 minutes', '45 minutes', '60 minutes', '75 minutes', '90 minutes'];
  final List<String> _preferredTimes = ['Anytime', 'Morning', 'Afternoon', 'Evening'];
  final List<String> _planDurations = ['3 Days', '5 Days', '7 Days', '14 Days', '21 Days', '30 Days'];
  final List<Map<String, String>> _fitnessGoals = [{'title': 'Lose weight and improve cardiovascular health', 'icon': '🏃‍♀️'}, {'title': 'Build muscle and increase overall strength', 'icon': '💪'}, {'title': 'Improve general fitness and endurance', 'icon': '🏃‍♂️'}, {'title': 'Increase flexibility and mobility', 'icon': '🤸‍♀️'}, {'title': 'Tone up and improve body composition', 'icon': '✨'}, {'title': 'Prepare for a specific sport or event', 'icon': '🏆'}, {'title': 'Reduce stress and improve mental well-being', 'icon': '🧘‍♀️'}, {'title': 'Gain functional strength for daily activities', 'icon': '🏠'}, {'title': 'Improve posture and core stability', 'icon': '🧍‍♀️'}, {'title': 'Increase energy levels throughout the day', 'icon': '⚡'}];

  @override
  void dispose() {
    _pageController.dispose();
    _fitnessGoalsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else {
        _showValidationSnackBar();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: return _fitnessGoalsController.text.trim().isNotEmpty;
      case 1: return _selectedFitnessLevel.isNotEmpty;
      case 2: return _selectedWorkoutType.isNotEmpty;
      case 3: return _selectedWorkoutDuration.isNotEmpty;
      case 4: return _selectedPreferredTime.isNotEmpty;
      case 5: return _selectedPlanDuration.isNotEmpty;
      default: return true;
    }
  }

  Future<void> _generatePlan() async {
    if (!_validateCurrentPage()) {
      _showValidationSnackBar();
      return;
    }
    setState(() => _isGenerating = true);
    _nextPage();

    try {
      final duration = int.tryParse(_selectedWorkoutDuration.split(' ').first);

      final workoutPlan = await WorkoutPlannerService.generateWorkoutPlan(
        fitnessGoals: _fitnessGoalsController.text,
        fitnessLevel: _selectedFitnessLevel,
        workoutType: _selectedWorkoutType,
        durationPerWorkout: duration,
        preferredTime: _selectedPreferredTime,
        planDuration: _selectedPlanDuration,
      );

      if (workoutPlan != null) {
        setState(() => _results = workoutPlan);
        _showSuccessSnackBar('Workout plan generated successfully!');
      } else {
        throw Exception('Failed to generate plan.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      _previousPage();
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void _resetFlow() {
    setState(() {
      _currentPage = 0;
      _results = null;
      _fitnessGoalsController.clear();
      _selectedFitnessLevel = '';
      _selectedWorkoutType = '';
      _selectedWorkoutDuration = '';
      _selectedPreferredTime = '';
      _selectedPlanDuration = '';
    });
    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    // Get screen width for responsive padding
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.1 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark))),
        title: Text('AI Workout Planner', style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              _buildProgressIndicator(isDark),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildFitnessGoalsPage(isDark),
                    _buildFitnessLevelPage(isDark),
                    _buildWorkoutTypePage(isDark),
                    _buildWorkoutDurationPage(isDark),
                    _buildPreferredTimePage(isDark),
                    _buildPlanDurationPage(isDark),
                    _buildWorkoutResultsPage(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _currentPage < 6
          ? _buildNavigationButtons(isDark)
          : null,
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    const totalSteps = 7;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentPage ? AppColors.black : AppColors.cardBackground(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text('Step ${_currentPage + 1} of $totalSteps', style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // NOTE: _buildDetailedMetrics is not used in the current PageView flow but kept for completeness.
  Widget _buildDetailedMetrics(bool isDark) {
    final List<Map<String, dynamic>> detailedMetrics = [
      {'label': 'Body Weight', 'key': 'bodyWeight', 'unit': 'kg', 'icon': lucide.LucideIcons.user},
      {'label': 'BMI', 'key': 'bmi', 'unit': '', 'icon': lucide.LucideIcons.activity},
      {'label': 'Body Fat Percentage', 'key': 'bodyFatPercentage', 'unit': '%', 'icon': lucide.LucideIcons.heart},
      {'label': 'Skeletal Muscle Mass', 'key': 'skeletalMuscleMass', 'unit': 'kg', 'icon': lucide.LucideIcons.dumbbell},
      {'label': 'Visceral Fat Level', 'key': 'visceralFatLevel', 'unit': '', 'icon': lucide.LucideIcons.shield},
      {'label': 'Body Fat Mass', 'key': 'bodyFatMass', 'unit': 'kg', 'icon': lucide.LucideIcons.heart},
      {'label': 'Lean Mass', 'key': 'leanMass', 'unit': 'kg', 'icon': lucide.LucideIcons.user},
      {'label': 'Muscle Mass', 'key': 'muscleMass', 'unit': 'kg', 'icon': lucide.LucideIcons.dumbbell},
      {'label': 'Bone Mass', 'key': 'boneMass', 'unit': 'kg', 'icon': lucide.LucideIcons.bone},
      {'label': 'Water Mass', 'key': 'waterMass', 'unit': 'kg', 'icon': lucide.LucideIcons.droplet},
      {'label': 'Protein Mass', 'key': 'proteinMass', 'unit': 'kg', 'icon': lucide.LucideIcons.atom},
      {'label': 'Basal Metabolic Rate', 'key': 'bmr', 'unit': 'kcal/day', 'icon': lucide.LucideIcons.flame},
      {'label': 'Metabolic Age', 'key': 'metabolicAge', 'unit': 'years', 'icon': lucide.LucideIcons.clock},
      {'label': 'Subcutaneous Fat', 'key': 'subcutaneousFat', 'unit': '%', 'icon': lucide.LucideIcons.heart},
      {'label': 'Body Water Percentage', 'key': 'bodyWaterPercentage', 'unit': '%', 'icon': lucide.LucideIcons.droplet},
      {'label': 'Overall Score', 'key': 'bodyCompositionScore', 'unit': '', 'icon': lucide.LucideIcons.star},
      {'label': 'Health Indicator', 'key': 'healthIndicator', 'unit': '', 'icon': lucide.LucideIcons.activity},
    ];

    if (_results == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detailedMetrics.map((metric) {
        var value = _results![metric['key']];
        if (value == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(metric['icon'], size: 20, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${metric['label']}:',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                metric['key'] == 'healthIndicator'
                    ? value.toString()
                    : '${value.toString()} ${metric['unit']}',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutDurationPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(lucide.LucideIcons.timer, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text('Workout Duration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text('How long do you want each workout session to be?', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)),
          const SizedBox(height: 32),
          _buildDropdownField(label: 'Duration per Workout (mins) *', value: _selectedWorkoutDuration.isEmpty ? null : _selectedWorkoutDuration, items: _workoutDurations, onChanged: (value) => setState(() => _selectedWorkoutDuration = value ?? ''), isDark: isDark, isRequired: true),
        ],
      ),
    );
  }

  Widget _buildPreferredTimePage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(lucide.LucideIcons.sunMoon, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text('Preferred Time', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text('When do you prefer to work out?', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)),
          const SizedBox(height: 32),
          _buildDropdownField(label: 'Preferred Time *', value: _selectedPreferredTime.isEmpty ? null : _selectedPreferredTime, items: _preferredTimes, onChanged: (value) => setState(() => _selectedPreferredTime = value ?? ''), isDark: isDark, isRequired: true),
        ],
      ),
    );
  }

  Widget _buildPlanDurationPage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text('Plan Duration', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text('Select how long you want the workout plan to be.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)),
          const SizedBox(height: 32),
          _buildDropdownField(label: 'Plan Duration *', value: _selectedPlanDuration.isEmpty ? null : _selectedPlanDuration, items: _planDurations, onChanged: (value) => setState(() => _selectedPlanDuration = value ?? ''), isDark: isDark, isRequired: true),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    bool isLastInputStep = _currentPage == 5;

    return Container(
      color: AppColors.background(isDark), // Added to match scaffold background
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0) Expanded(child: OutlinedButton(onPressed: _previousPage, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: AppColors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: AppColors.white), child: Text('Previous', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600, fontSize: 16)))),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: isLastInputStep ? (_isGenerating ? null : _generatePlan) : _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.black, foregroundColor: AppColors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isGenerating && isLastInputStep
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))), const SizedBox(width: 12), const Text('Generating...')])
                  : Text(isLastInputStep ? 'Generate Plan' : 'Next', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutResultsPage(bool isDark) {
    if (_isGenerating || _results == null) {
      return Center(child: SpinKitFadingCube(color: AppColors.black, size: 50.0));
    }
    final schedule = _results!['weeklySchedule'] as List?;
    final tips = _results!['generalTips'] as List?;

    return SingleChildScrollView(
      // Padding is already handled by the main body padding, so this padding is relative to the screen size
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(lucide.LucideIcons.award, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text(_results!['planTitle'] ?? 'Your Workout Plan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark), )),
          const SizedBox(height: 8),
          Text(_results!['introduction'] ?? 'Your personalized plan is ready!', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5,)),
          const SizedBox(height: 32),
          _buildSummaryCard(isDark),
          const SizedBox(height: 32),
          // Adaptive Button Layout
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              SizedBox(
                width: 150,
                child: OutlinedButton.icon(
                  onPressed: () => _shareWorkoutPlan(_results!),
                  icon: const Icon(lucide.LucideIcons.share2),
                  label: const Text('Share Plan'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.borderColor(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppColors.textPrimary(isDark)
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  onPressed: _resetFlow,
                  icon: const Icon(lucide.LucideIcons.refreshCw),
                  label: const Text('New Plan'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Workout Schedule', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 16),
          if (schedule != null && schedule.isNotEmpty)
          // *** CHANGE: Use ListView.builder to call the new collapsible tile function ***
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final dayData = schedule[index];
                  // CALL THE NEW COLLAPSIBLE WIDGET
                  return _buildCollapsibleDayTile(dayData, isDark);
                })
          else
            Text('No schedule provided.', style: TextStyle(color: AppColors.textSecondary(isDark))),
          const SizedBox(height: 32),
          Text('Helpful Tips', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 16),
          if (tips != null && tips.isNotEmpty)
            ...tips.map((tip) => ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.green), title: Text(tip.toString(), style: TextStyle(color: AppColors.textSecondary(isDark)))))
          else
            Text('No tips provided.', style: TextStyle(color: AppColors.textSecondary(isDark)))
        ],
      ),
    );
  }

  // *** REMOVED _buildDayCard to implement _buildCollapsibleDayTile instead. ***

  // *** NEW WIDGET: Day-wise plan in Collapsible (ExpansionTile) form ***
  Widget _buildCollapsibleDayTile(Map<String, dynamic> dayData, bool isDark) {
    final bool isRestDay = (dayData['activity'] ?? '').toLowerCase().contains('rest');
    final exercises = dayData['details'] as List?;

    Color iconColor = isRestDay ? Colors.green : AppColors.black;
    Color tileColor = isDark ? AppColors.cardBackground(isDark) : AppColors.white;
    Color titleColor = AppColors.textPrimary(isDark);
    Color subtitleColor = AppColors.textSecondary(isDark);

    // Determines the appropriate icon and secondary text
    IconData leadingIcon = isRestDay ? lucide.LucideIcons.bed : lucide.LucideIcons.dumbbell;
    String subtitleText = isRestDay ? 'Recovery Day' : (dayData['activity'] ?? 'Full Workout');

    // Set the overall text for rest days to be in the subtitle
    if(isRestDay && exercises != null && exercises.isNotEmpty){
      subtitleText = exercises.first['instruction'] ?? 'Active recovery advised.';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor(isDark), width: 1.0),
      ),
      color: tileColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Primary title: Day Name
        title: Text(
          dayData['day'] ?? 'Unknown Day',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        // Secondary title: Activity Type (Workout/Rest)
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: subtitleColor,
            fontStyle: isRestDay ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        leading: Icon(leadingIcon, color: iconColor),
        // The content that expands
        children: <Widget>[
          Divider(height: 1, color: AppColors.borderColor(isDark)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isRestDay
                ? // Rest Day Content
            Text(
              'Ensure you focus on mobility, stretching, or light cardio to aid muscle recovery. Listen to your body!',
              style: TextStyle(fontSize: 16, color: subtitleColor, height: 1.5),
            )
                : // Workout Day Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Exercise Details:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      decoration: TextDecoration.underline
                  ),
                ),
                const SizedBox(height: 12),
                if (exercises != null && exercises.isNotEmpty)
                  ...exercises.map<Widget>((exercise) {
                    final instruction = exercise['instruction'] ?? 'No specific instructions provided.';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(
                              text: '${exercise['name'] ?? "Exercise"}: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                  fontSize: 16
                              ),
                            ),
                            TextSpan(
                              text: instruction,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                else
                  Text('No detailed exercises available for this session.', style: TextStyle(color: subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Plan Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 16),
          _buildSummaryRow(lucide.LucideIcons.calendar, 'Plan Duration', _selectedPlanDuration, isDark),
          _buildSummaryRow(lucide.LucideIcons.timer, 'Workout Duration', _selectedWorkoutDuration, isDark),
          _buildSummaryRow(lucide.LucideIcons.sunMoon, 'Preferred Time', _selectedPreferredTime, isDark),
          _buildSummaryRow(lucide.LucideIcons.chartArea, 'Fitness Level', _selectedFitnessLevel, isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push start and end apart
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: AppColors.textSecondary(isDark)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8), // Small gap between label and value
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)),
              maxLines: 2,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text, bool isDark) {
    // --- FIX: ---
    // Added 'mainAxisSize: MainAxisSize.min' to the Row.
    // This prevents the Row from trying to expand, which is crucial inside a Wrap.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary(isDark)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: AppColors.textSecondary(isDark))),
      ],
    );
  }



  Widget _buildWorkoutTypePage(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 48, color: AppColors.black),
          const SizedBox(height: 16),
          Text('Workout Type', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text('Choose your preferred workout type.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)),
          const SizedBox(height: 32),
          _buildDropdownField(label: 'Workout Type *', value: _selectedWorkoutType.isEmpty ? null : _selectedWorkoutType, items: _workoutTypes, onChanged: (value) => setState(() => _selectedWorkoutType = value ?? ''), isDark: isDark, isRequired: true),
        ],
      ),
    );
  }
  Widget _buildFitnessGoalsPage(bool isDark) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Icon(Icons.flag_outlined, size: 48, color: AppColors.black), const SizedBox(height: 16), Text('Your Fitness Goals', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))), const SizedBox(height: 8), Text('Describe your specific fitness goals and what you want to achieve.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)), const SizedBox(height: 32), _buildTextField(label: 'Fitness Goals *', controller: _fitnessGoalsController, hint: 'Describe your specific fitness goals...', maxLines: 4, isDark: isDark, isRequired: true), const SizedBox(height: 24), Text('Popular Goals (tap to select)', style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 16), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: _fitnessGoals.length, itemBuilder: (context, index) { final goal = _fitnessGoals[index]; return GestureDetector(onTap: () => setState(() => _fitnessGoalsController.text = goal['title']!), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _fitnessGoalsController.text == goal['title'] ? AppColors.black.withOpacity(0.1) : AppColors.cardBackground(isDark), borderRadius: BorderRadius.circular(8), border: Border.all(color: _fitnessGoalsController.text == goal['title'] ? AppColors.black : AppColors.borderColor(isDark))), child: Row(children: [Text(goal['icon']!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6), Expanded(child: Text(goal['title']!, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 11, fontWeight: _fitnessGoalsController.text == goal['title'] ? FontWeight.w600 : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis))]))); })]));
  }
  Widget _buildFitnessLevelPage(bool isDark) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Icon(Icons.trending_up, size: 48, color: AppColors.black), const SizedBox(height: 16), Text('Fitness Level', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))), const SizedBox(height: 8), Text('Select your current fitness experience level.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary(isDark), height: 1.5)), const SizedBox(height: 32), _buildDropdownField(label: 'Current Fitness Level *', value: _selectedFitnessLevel.isEmpty ? null : _selectedFitnessLevel, items: _fitnessLevels, onChanged: (value) => setState(() => _selectedFitnessLevel = value ?? ''), isDark: isDark, isExpanded: true, isRequired: true)]));
  }
  Widget _buildTextField({required String label, required TextEditingController controller, required String hint, required bool isDark, int maxLines = 1, bool isRequired = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), TextFormField(controller: controller, maxLines: maxLines, style: TextStyle(color: AppColors.textPrimary(isDark)), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.textSecondary(isDark)), filled: true, fillColor: AppColors.cardBackground(isDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isRequired && controller.text.isEmpty ? Colors.red.withOpacity(0.5) : AppColors.borderColor(isDark))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isRequired && controller.text.isEmpty ? Colors.red.withOpacity(0.5) : AppColors.borderColor(isDark))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.black, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)))]);
  }
  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required void Function(String?) onChanged, required bool isDark, bool isExpanded = false, bool isRequired = false}) {
    // Making Dropdown fully expanded for better responsiveness
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: value, items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, style: TextStyle(color: AppColors.textPrimary(isDark)), overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis))).toList(), onChanged: onChanged, isExpanded: true, decoration: InputDecoration(filled: true, fillColor: AppColors.cardBackground(isDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isRequired && (value == null || value.isEmpty) ? Colors.red.withOpacity(0.5) : AppColors.borderColor(isDark))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isRequired && (value == null || value.isEmpty) ? Colors.red.withOpacity(0.5) : AppColors.borderColor(isDark))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.black, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)), dropdownColor: AppColors.cardBackground(isDark))]);
  }
  Future<void> _shareWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    try {
      final planText = WorkoutPlannerService.generateWorkoutPlanText(workoutPlan);
      final planTitle = workoutPlan['planTitle'] ?? 'Workout Plan';
      await FileDownloadService.shareWorkoutPlan(planText, planTitle);
      _showSuccessSnackBar('Workout plan shared successfully!');
    } catch (e) {
      _showErrorSnackBar('Error sharing plan: ${e.toString()}');
    }
  }
  void _showValidationSnackBar() { String message = ''; switch (_currentPage) { case 0: message = 'Please describe your fitness goals'; break; case 1: message = 'Please select your fitness level'; break; case 2: message = 'Please select a workout type'; break; case 3: message = 'Please select a workout duration'; break; case 4: message = 'Please select a preferred time'; break; case 5: message = 'Please select a plan duration'; break; default: message = 'Please complete the form'; } ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }
  void _showSuccessSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.check_circle_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }
  void _showErrorSnackBar(String message) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text(message))]), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }
}