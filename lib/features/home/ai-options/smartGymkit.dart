import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/bulkingmacroservice.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'package:trackai/features/home/ai-options/service/workoutPlannerService.dart';
import 'package:trackai/features/onboarding/service/observices.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Smartgymkit extends StatefulWidget {
  const Smartgymkit({Key? key}) : super(key: key);

  @override
  State<Smartgymkit> createState() => _SmartgymkitState();
}

class _SmartgymkitState extends State<Smartgymkit>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Workout Planner Variables
  final TextEditingController _fitnessGoalsController = TextEditingController();
  String _selectedFitnessLevel = 'Select your fitness level';
  String _selectedWorkoutType = 'Any';
  String _selectedPlanDuration = '7 Days';
  String _selectedGoal = '';
  bool _showGoalOptions = false;
  bool _isGeneratingPlan = false;
  Map<String, dynamic>? _savedWorkoutPlan;
  bool _isLoadingSavedPlan = false;

  // Bulking Macros Variables
  String _selectedGender = 'Select gender';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  String _selectedActivityLevel = 'Select activity level';
  final TextEditingController _targetGainController = TextEditingController();
  String _selectedTargetUnit = 'kg';
  final TextEditingController _timeframeController = TextEditingController();
  Map<String, dynamic>? _bulkingResults;
  Map<String, dynamic>? _onboardingData;
  bool _isCalculatingMacros = false;

  final List<String> _fitnessLevels = [
    'Select your fitness level',
    'Beginner (0-6 months)',
    'Intermediate (6 months - 2 years)',
    'Advanced (2-5 years)',
    'Expert (5+ years)',
  ];

  final List<String> _workoutTypes = [
    'Any',
    'Home Workout',
    'Gym Workout',
    'Calisthenics',
    'Strength Training',
    'Cardio Focus',
    'Hybrid Training',
  ];

  final List<String> _planDurations = [
    '3 Days',
    '5 Days',
    '7 Days',
    '14 Days',
    '21 Days',
    '30 Days',
  ];

  final List<Map<String, String>> _fitnessGoals = [
    {'title': 'Lose weight and improve cardiovascular health', 'icon': '🏃‍♀️'},
    {'title': 'Build muscle and increase overall strength', 'icon': '💪'},
    {'title': 'Improve general fitness and endurance', 'icon': '🏃‍♂️'},
    {'title': 'Increase flexibility and mobility', 'icon': '🤸‍♀️'},
    {'title': 'Tone up and improve body composition', 'icon': '✨'},
    {'title': 'Prepare for a specific sport or event', 'icon': '🏆'},
    {'title': 'Reduce stress and improve mental well-being', 'icon': '🧘‍♀️'},
    {'title': 'Gain functional strength for daily activities', 'icon': '🏠'},
    {'title': 'Improve posture and core stability', 'icon': '🧍‍♀️'},
    {'title': 'Increase energy levels throughout the day', 'icon': '⚡'},
  ];

  final List<String> _genders = ['Select gender', 'Male', 'Female', 'Other'];

  final List<String> _activityLevels = [
    'Select activity level',
    'Sedentary (desk job, no exercise)',
    'Lightly Active (light exercise 1-3 days/week)',
    'Moderately Active (moderate exercise 3-5 days/week)',
    'Very Active (hard exercise 6-7 days/week)',
    'Super Active (very hard exercise, physical job)',
  ];

  final List<String> _weightUnits = ['kg', 'lbs'];
  final List<String> _heightUnits = ['cm', 'ft'];
  final List<String> _targetUnits = ['kg', 'lbs'];

  double _convertToCm(double value, String unit) {
    if (unit == 'ft') {
      // Split feet and inches
      double feet = double.tryParse(_feetController.text) ?? 0;
      double inches = double.tryParse(_inchesController.text) ?? 0;
      return (feet * 30.48) + (inches * 2.54);
    }
    return value; // Already in cm
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadSavedWorkoutPlan();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await OnboardingService.getOnboardingData();
      if (data != null) {
        setState(() {
          _onboardingData = data;
          // Pre-fill data if available
          if (data['gender'] != null) {
            _selectedGender = data['gender'];
          }
          if (data['weightKg'] != null) {
            _weightController.text = data['weightKg'].toString();
          }
          if (data['heightCm'] != null) {
            _heightController.text = data['heightCm'].toString();
          }
          if (data['dateOfBirth'] != null) {
            final age = OnboardingService.calculateAge(data['dateOfBirth']);
            _ageController.text = age.toString();
          }
          if (data['activityLevel'] != null) {
            _selectedActivityLevel = data['activityLevel'];
          }
        });
      }

      // Load saved bulking results
      await _loadSavedBulkingResults();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadSavedBulkingResults() async {
    setState(() {
      _isLoadingSavedPlan = true; // Reuse the loading state
    });

    try {
      final savedResults = await BulkingMacrosService.getSavedBulkingPlan();

      if (savedResults != null) {
        setState(() {
          _bulkingResults = savedResults;

          // Pre-fill form with saved data if available
          final userInput = savedResults['userInput'] as Map<String, dynamic>?;
          if (userInput != null) {
            _selectedGender = userInput['gender'] ?? _selectedGender;
            _weightController.text =
                userInput['weight']?.toString() ?? _weightController.text;
            _heightController.text =
                userInput['height']?.toString() ?? _heightController.text;
            _ageController.text =
                userInput['age']?.toString() ?? _ageController.text;
            _selectedActivityLevel =
                userInput['activityLevel'] ?? _selectedActivityLevel;
            _targetGainController.text =
                userInput['targetGain']?.toString() ??
                _targetGainController.text;
            _timeframeController.text =
                userInput['timeframe']?.toString() ?? _timeframeController.text;

            // Set units based on saved data or defaults
            _selectedWeightUnit = 'kg'; // Assuming saved data is in kg
            _selectedHeightUnit = 'cm'; // Assuming saved data is in cm
            _selectedTargetUnit = 'kg';
          }
        });
      }
    } catch (e) {
      print('Error loading saved bulking results: $e');
    } finally {
      setState(() {
        _isLoadingSavedPlan = false;
      });
    }
  }

  Future<void> _loadSavedWorkoutPlan() async {
    setState(() {
      _isLoadingSavedPlan = true;
    });

    try {
      final savedPlan = await WorkoutPlannerService.getSavedWorkoutPlan();

      if (savedPlan != null) {
        setState(() {
          _savedWorkoutPlan = savedPlan;
        });
      }
    } catch (e) {
      print('Error loading saved workout plan: $e');
    } finally {
      setState(() {
        _isLoadingSavedPlan = false;
      });
    }
  }

  Future<void> _generateWorkoutPlan() async {
    if (_selectedFitnessLevel == 'Select your fitness level' ||
        _fitnessGoalsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPlan = true;
    });

    try {
      final workoutPlan = await WorkoutPlannerService.generateWorkoutPlan(
        fitnessGoals: _fitnessGoalsController.text,
        fitnessLevel: _selectedFitnessLevel,
        workoutType: _selectedWorkoutType,
        planDuration: _selectedPlanDuration,
        onboardingData: _onboardingData,
      );

      if (workoutPlan != null) {
        await WorkoutPlannerService.saveWorkoutPlan(workoutPlan);
        setState(() {
          _savedWorkoutPlan = workoutPlan;
        });
        _showWorkoutPlanDialog(workoutPlan);
      } else {
        throw Exception('Failed to generate workout plan. Please try again.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPlan = false;
      });
    }
  }

  Future<void> _calculateBulkingMacros() async {
    if (_selectedGender == 'Select gender' ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _selectedActivityLevel == 'Select activity level' ||
        _targetGainController.text.isEmpty ||
        _timeframeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Validate numeric inputs
    double? weight = double.tryParse(_weightController.text);
    double? height = double.tryParse(_heightController.text);
    int? age = int.tryParse(_ageController.text);
    double? targetGain = double.tryParse(_targetGainController.text);
    int? timeframe = int.tryParse(_timeframeController.text);

    if (weight == null ||
        height == null ||
        age == null ||
        targetGain == null ||
        timeframe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid numbers for all fields'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    // Validate ranges
    if (weight <= 0 || weight > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid weight (1-500 ${_selectedWeightUnit})',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (height <= 0 || height > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid height (1-300 ${_selectedHeightUnit})',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (age < 13 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid age (13-100 years)'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (targetGain <= 0 || targetGain > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a realistic target gain (0.1-50 ${_selectedTargetUnit})',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (timeframe < 1 || timeframe > 104) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid timeframe (1-104 weeks)'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isCalculatingMacros = true;
    });

    try {
      // Convert units to metric if needed
      double weightInKg = weight;
      if (_selectedWeightUnit == 'lbs') {
        weightInKg = weight * 0.453592;
      }

      double heightInCm = height;
      if (_selectedHeightUnit == 'ft') {
        heightInCm = height * 30.48;
      }

      double targetGainInKg = targetGain;
      if (_selectedTargetUnit == 'lbs') {
        targetGainInKg = targetGain * 0.453592;
      }

      // Check weekly gain rate and warn user if too aggressive
      double weeklyGainRate = targetGainInKg / timeframe;
      if (weeklyGainRate > 1.0) {
        bool proceed = await _showAggressiveGainWarning(weeklyGainRate);
        if (!proceed) {
          setState(() {
            _isCalculatingMacros = false;
          });
          return;
        }
      }

      final macroResults = await BulkingMacrosService.calculateBulkingMacros(
        gender: _selectedGender,
        weight: weightInKg,
        height: heightInCm,
        age: age,
        activityLevel: _selectedActivityLevel,
        targetGain: targetGainInKg,
        timeframe: timeframe,
        userProfile: _onboardingData,
      );

      if (macroResults != null) {
        setState(() {
          _bulkingResults = macroResults;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulking macros calculated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () => _showBulkingResultsDialog(macroResults),
            ),
          ),
        );
      } else {
        throw Exception('Failed to calculate macros. Please try again.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isCalculatingMacros = false;
      });
    }
  }

  void _showWorkoutPlanDialog(Map<String, dynamic> workoutPlan) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkTheme = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WorkoutPlanDialog(
          workoutPlan: workoutPlan,
          onDownload: () => _downloadWorkoutPlan(workoutPlan),
          onShare: () => _shareWorkoutPlan(workoutPlan),
          isDarkTheme: isDarkTheme,
        );
      },
    );
  }

  void _showBulkingResultsDialog(Map<String, dynamic> results) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkTheme = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BulkingResultsDialog(
          results: results,
          onDownload: () => _downloadBulkingPlan(results),
          onShare: () => _shareBulkingPlan(results),
          isDarkTheme: isDarkTheme,
        );
      },
    );
  }

  Future<bool> _showAggressiveGainWarning(double weeklyGainRate) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Aggressive Gain Rate'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your target gain rate is ${weeklyGainRate.toStringAsFixed(2)} kg/week.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This is quite aggressive and may result in significant fat gain alongside muscle. Most experts recommend 0.25-0.5 kg/week for lean bulking.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  Text('Do you want to proceed with this target?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Modify Goal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    'Proceed Anyway',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _downloadWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    try {
      final planText = WorkoutPlannerService.generateWorkoutPlanText(
        workoutPlan,
      );
      final planTitle = workoutPlan['title'] ?? 'Workout Plan';

      // Use the downloadMealPlan method from your service
      final result = await FileDownloadService.downloadMealPlan(
        planText,
        planTitle,
      );

      if (result['success']) {
        await FileDownloadService.showDownloadResult(context, result);
      } else {
        // If download fails, offer share as alternative
        await _showDownloadFailedDialog(result['error'], planText, planTitle);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          action: SnackBarAction(
            label: 'Share Instead',
            textColor: Colors.white,
            onPressed: () => _shareWorkoutPlan(workoutPlan),
          ),
        ),
      );
    }
  }

  Future<void> _shareWorkoutPlan(Map<String, dynamic> workoutPlan) async {
    try {
      final planText = WorkoutPlannerService.generateWorkoutPlanText(
        workoutPlan,
      );
      final planTitle = workoutPlan['title'] ?? 'Workout Plan';
      await FileDownloadService.shareWorkoutPlan(planText, planTitle);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _downloadBulkingPlan(Map<String, dynamic> results) async {
    try {
      final planText = BulkingMacrosService.generateBulkingPlanText(results);

      // Use the downloadMealPlan method from your service
      final result = await FileDownloadService.downloadMealPlan(
        planText,
        'Bulking_Macros_Plan',
      );

      if (result['success']) {
        await FileDownloadService.showDownloadResult(context, result);
      } else {
        // If download fails, offer share as alternative
        await _showDownloadFailedDialog(
          result['error'],
          planText,
          'Bulking_Macros_Plan',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          action: SnackBarAction(
            label: 'Share Instead',
            textColor: Colors.white,
            onPressed: () => _shareBulkingPlan(results),
          ),
        ),
      );
    }
  }

  Future<void> _showDownloadFailedDialog(
    String error,
    String content,
    String title,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Download Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Download failed: $error'),
              SizedBox(height: 12),
              Text(
                'Would you like to share the file instead or try save and share?',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FileDownloadService.shareWorkoutPlan(content, title);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sharing: ${e.toString()}'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
              child: Text('Share Only'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final result = await FileDownloadService.saveAndShareMealPlan(
                    content,
                    title,
                  );
                  if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('File created and share dialog opened'),
                        backgroundColor: AppColors.darkPrimary,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimary,
              ),
              child: Text(
                'Save & Share',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareBulkingPlan(Map<String, dynamic> results) async {
    try {
      final planText = BulkingMacrosService.generateBulkingPlanText(results);
      await FileDownloadService.shareWorkoutPlan(
        planText,
        'Bulking_Macros_Plan',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(40, 50, 49, 1.0),
            Color.fromARGB(255, 30, 30, 30),
            Color.fromRGBO(33, 43, 42, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fitnessGoalsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _targetGainController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context);
  final isDarkTheme = themeProvider.isDarkMode;
  final screenHeight = MediaQuery.of(context).size.height;

  return Scaffold(
    backgroundColor: isDarkTheme ? Color(0xFF121212) : Color(0xFFF5F5F5),
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary(isDarkTheme),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(
            lucide.LucideIcons.activity, // Icon from Homescreen
            color: Color(0xFF26A69A), // Same color as in Homescreen
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            'Smart Gym Kit',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: isDarkTheme ? Colors.white : Colors.black, // Changed to black
        unselectedLabelColor: isDarkTheme
            ? Colors.white.withOpacity(0.5)
            : Colors.black.withOpacity(0.5), // Adjusted for theme
        indicatorColor: Colors.black, // Changed to black
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.fitness_center), text: 'Workout Planner'),
          Tab(
            icon: Icon(Icons.local_fire_department),
            text: 'Bulking Macros',
          ),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildWorkoutPlannerTab(isDarkTheme, screenHeight),
        _buildBulkingMacrosTab(isDarkTheme, screenHeight),
      ],
    ),
  );
}

  Widget _buildWorkoutPlannerTab(bool isDarkTheme, double screenHeight) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_gymnastics,
                    color: const Color(0xFF26A69A), // Changed from 0xFF4CAF50
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Workout Planner',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Get a personalized workout plan tailored to your fitness goals, level, and preferred workout type using advanced AI.',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              // Permission check button
              FutureBuilder<bool>(
                future: FileDownloadService.requestStoragePermission(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && !snapshot.data!) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Storage permission needed for downloads',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final granted =
                                  await FileDownloadService.requestStoragePermission();
                              if (!granted) {
                                await FileDownloadService.showPermissionDialog(
                                  context,
                                );
                              }
                              setState(() {}); // Refresh the UI
                            },
                            child: Text(
                              'Grant',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Loading State for Saved Plan
        if (_isLoadingSavedPlan)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Row(
              children: [
                SpinKitThreeBounce(color: AppColors.darkPrimary, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Loading saved plan...',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Recent Generated Plan Card
        if (_savedWorkoutPlan != null && !_isLoadingSavedPlan)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: AppColors.darkPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Generated Plan',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _savedWorkoutPlan!['title'] ?? 'AI Generated Workout Plan',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${_savedWorkoutPlan!['duration'] ?? _savedWorkoutPlan!['planDuration']} • Type: ${_savedWorkoutPlan!['workoutType']}',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black45,
                    fontSize: 12,
                  ),
                ),
                if (_savedWorkoutPlan!['generatedAt'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Generated: ${_formatDate(_savedWorkoutPlan!['generatedAt'])}',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white60 : Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showWorkoutPlanDialog(_savedWorkoutPlan!),
                        icon: Icon(
                          Icons.visibility,
                          size: 16,
                          color: AppColors.darkPrimary,
                        ),
                        label: Text(
                          'View Plan',
                          style: TextStyle(
                            color: AppColors.darkPrimary,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.darkPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _downloadWorkoutPlan(_savedWorkoutPlan!),
                        icon: Icon(
                          Icons.download,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Download',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Fitness Goals Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Fitness Goals *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fitnessGoalsController,
                maxLines: 3,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Describe your specific fitness goals, target areas, and what you want to achieve',
                  hintStyle: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black45,
                  ),
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showGoalOptions = !_showGoalOptions;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.textPrimary(isDarkTheme),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: AppColors.darkPrimary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tune,
                        color: AppColors.darkPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showGoalOptions
                            ? 'Hide Goal Options'
                            : 'Choose from Popular Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Goal Selection Popup
        if (_showGoalOptions) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Fitness Goals',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showGoalOptions = false;
                        });
                      },
                      icon: Icon(
                        Icons.close,
                        color: isDarkTheme ? Colors.white70 : Colors.black54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(_fitnessGoals.length, (index) {
                  final goal = _fitnessGoals[index];
                  final isSelected = _selectedGoal == goal['title'];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedGoal = goal['title']!;
                          _fitnessGoalsController.text = goal['title']!;
                          _showGoalOptions = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.darkPrimary.withOpacity(0.2)
                              : (isDarkTheme
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.02)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.darkPrimary
                                : (isDarkTheme
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              goal['icon']!,
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal['title']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.darkPrimary
                                      : (isDarkTheme
                                          ? Colors.white70
                                          : Colors.black54),
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Current Fitness Level Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Fitness Level *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedFitnessLevel,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: isDarkTheme
                    ? const Color(0xFF2D2D2D)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
                items: _fitnessLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFitnessLevel = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preferred Workout Type Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferred Workout Type',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedWorkoutType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: isDarkTheme
                    ? const Color(0xFF2D2D2D)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
                items: _workoutTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWorkoutType = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Plan Duration Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Duration',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPlanDuration,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: isDarkTheme
                    ? const Color(0xFF2D2D2D)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
                items: _planDurations.map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text(duration),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlanDuration = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Get Workout Plan Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isGeneratingPlan ? null : _generateWorkoutPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isGeneratingPlan
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating AI Plan...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Generate AI Workout Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

Widget _buildBulkingMacrosTab(bool isDarkTheme, double screenHeight) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: const Color(0xFF26A69A), // Changed from 0xFF4CAF50
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Bulking Macro Calculator',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Get personalized nutrition targets for gaining weight and muscle mass with AI-powered recommendations.',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Previous Data Display (Enhanced Design like the image)
        if (_bulkingResults != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _getCardDecoration(isDarkTheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: AppColors.darkPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Daily Bulking Targets',
                            style: TextStyle(
                              color: isDarkTheme
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'These are your saved daily nutritional goals for weight gain.',
                            style: TextStyle(
                              color: isDarkTheme
                                  ? Colors.white60
                                  : Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Large Calories Display
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: AppColors.darkPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Calories',
                            style: TextStyle(
                              color: isDarkTheme
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_bulkingResults!['calories']}',
                        style: TextStyle(
                          color: AppColors.darkPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: TextStyle(
                          color: isDarkTheme
                              ? Colors.white60
                              : Colors.black45,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Macro Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedMacroCard(
                        'Protein',
                        _bulkingResults!['protein'],
                        'g',
                        Icons.fitness_center,
                        Colors.orange,
                        isDarkTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEnhancedMacroCard(
                        'Carbs',
                        _bulkingResults!['carbs'],
                        'g',
                        Icons.grass,
                        AppColors.darkPrimary,
                        isDarkTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEnhancedMacroCard(
                        'Fat',
                        _bulkingResults!['fat'],
                        'g',
                        Icons.water_drop,
                        Colors.blue,
                        isDarkTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEnhancedMacroCard(
                        'Fiber',
                        _bulkingResults!['fiber'] ?? 25,
                        'g',
                        Icons.eco,
                        Colors.green,
                        isDarkTheme,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Plan Age and Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkTheme
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Explanation',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How your bulking macro plan was calculated.',
                        style: TextStyle(
                          color: isDarkTheme
                              ? Colors.white60
                              : Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Collapsible Explanation
                      ExpansionTile(
                        title: Text(
                          'Your Daily Energy Needs:',
                          style: TextStyle(
                            color: isDarkTheme
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'BMR: ${_bulkingResults!['bmr']} kcal • TDEE: ${_bulkingResults!['tdee']} kcal',
                          style: TextStyle(
                            color: isDarkTheme
                                ? Colors.white60
                                : Colors.black45,
                            fontSize: 12,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExplanationPoint(
                                  'Your Basal Metabolic Rate (BMR) is the energy your body needs to function at rest. Your BMR is ${_bulkingResults!['bmr']} kcal.',
                                  isDarkTheme,
                                ),
                                const SizedBox(height: 12),
                                _buildExplanationPoint(
                                  'Factoring in your activity level, your Total Daily Energy Expenditure (TDEE) is the total daily calorie need to maintain your current weight. Your TDEE is ${_bulkingResults!['tdee']} kcal.',
                                  isDarkTheme,
                                ),
                                const SizedBox(height: 12),
                                _buildExplanationPoint(
                                  'Your Caloric Goal: To gain ${_bulkingResults!['weeklyGainRate']}kg per week, you need a daily surplus of ${_bulkingResults!['surplus']} calories above your TDEE.',
                                  isDarkTheme,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showBulkingResultsDialog(_bulkingResults!),
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkPrimary,
                          side: BorderSide(color: AppColors.darkPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _downloadBulkingPlan(_bulkingResults!),
                        icon: Icon(Icons.download, size: 16),
                        label: Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gender *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: isDarkTheme
                    ? const Color(0xFF2D2D2D)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Body Measurements Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Body Measurements *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Weight Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        labelStyle: TextStyle(
                          color: isDarkTheme
                              ? Colors.white60
                              : Colors.black45,
                        ),
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedWeightUnit,
                      isExpanded: true, // fix overflow
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: isDarkTheme
                          ? const Color(0xFF2D2D2D)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDarkTheme ? Colors.white70 : Colors.black54,
                      ),
                      items: _weightUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            unit,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWeightUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Height Row (matches Weight layout)
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Height',
                        labelStyle: TextStyle(
                          color: isDarkTheme
                              ? Colors.white60
                              : Colors.black45,
                        ),
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedHeightUnit,
                      isExpanded: true, // fix overflow
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: isDarkTheme
                          ? const Color(0xFF2D2D2D)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDarkTheme ? Colors.white70 : Colors.black54,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cm', child: Text('cm')),
                        DropdownMenuItem(value: 'ft', child: Text('ft/in')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedHeightUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Activity Level Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity Level *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivityLevel,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    dropdownColor: isDarkTheme
                        ? const Color(0xFF2D2D2D)
                        : Colors.white,
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                    ),
                    items: _activityLevels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(
                          level,
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedActivityLevel = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bulking Goals Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _getCardDecoration(isDarkTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulking Goals *',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _targetGainController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Target Weight Gain',
                        labelStyle: TextStyle(
                          color: isDarkTheme
                              ? Colors.white60
                              : Colors.black45,
                        ),
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedTargetUnit,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: isDarkTheme
                          ? const Color(0xFF2D2D2D)
                          : Colors.white,
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDarkTheme ? Colors.white70 : Colors.black54,
                      ),
                      items: _targetUnits.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTargetUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeframeController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Timeframe (weeks)',
                  labelStyle: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black45,
                  ),
                  hintText: 'How many weeks to reach your goal?',
                  hintStyle: TextStyle(
                    color: isDarkTheme ? Colors.white60 : Colors.black45,
                  ),
                  filled: true,
                  fillColor: isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Calculate/Recalculate Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCalculatingMacros ? null : _calculateBulkingMacros,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isCalculatingMacros
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Calculating with AI...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _bulkingResults != null
                            ? 'Recalculate AI Bulking Macros'
                            : 'Calculate AI Bulking Macros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

  // Add these helper methods to your class:

  Widget _buildEnhancedMacroCard(
    String title,
    dynamic value,
    String unit,
    IconData icon,
    Color color,
    bool isDarkTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${value?.toString() ?? '0'}',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: isDarkTheme ? Colors.white38 : Colors.black38,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationPoint(String text, bool isDarkTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.darkPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDarkTheme ? Colors.white70 : Colors.black54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    String title,
    dynamic value,
    String unit,
    bool isDarkTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkTheme
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDarkTheme ? Colors.white60 : Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value?.toString() ?? '0'}$unit',
            style: TextStyle(
              color: AppColors.darkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is Timestamp) {
      dateTime = date.toDate();
    } else {
      return 'Recently';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Enhanced Workout Plan Dialog
// Enhanced Workout Plan Dialog
class WorkoutPlanDialog extends StatelessWidget {
  final Map<String, dynamic> workoutPlan;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool isDarkTheme; // Add theme parameter

  const WorkoutPlanDialog({
    Key? key,
    required this.workoutPlan,
    required this.onDownload,
    required this.onShare,
    required this.isDarkTheme, // Make it required
  }) : super(key: key);

  BoxDecoration _getDialogDecoration() {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(40, 50, 49, 1.0),
            Color.fromARGB(255, 30, 30, 30),
            Color.fromRGBO(33, 43, 42, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.8),
          width: 0.5,
        ),
      );
    } else {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Color get _primaryTextColor => isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      isDarkTheme ? Colors.white70 : Colors.black54;
  Color get _tertiaryTextColor => isDarkTheme ? Colors.white60 : Colors.black45;
  Color get _iconColor => isDarkTheme ? Colors.white70 : Colors.black54;
  Color get _cardBackgroundColor => isDarkTheme
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.05);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: _getDialogDecoration(),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: AppColors.darkPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workoutPlan['title'] ?? 'AI Workout Plan',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: _iconColor),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Details
                    _buildDetailRow(
                      'Duration',
                      workoutPlan['duration'] ?? workoutPlan['planDuration'],
                    ),
                    _buildDetailRow('Type', workoutPlan['workoutType']),
                    _buildDetailRow('Level', workoutPlan['fitnessLevel']),
                    _buildDetailRow('Goals', workoutPlan['fitnessGoals']),

                    SizedBox(height: 20),

                    // Overview
                    if (workoutPlan['overview'] != null) ...[
                      Text(
                        'Overview',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        workoutPlan['overview'],
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Schedule Preview with Detailed Exercises
                    if (workoutPlan['schedule'] != null &&
                        workoutPlan['schedule'] is List) ...[
                      Text(
                        'Workout Schedule',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...((workoutPlan['schedule'] as List).take(5).map((day) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.darkPrimary.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Title and Duration
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      day['title'] ?? 'Day ${day['day']}',
                                      style: TextStyle(
                                        color: AppColors.darkPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (day['duration'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkPrimary
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        day['duration'],
                                        style: TextStyle(
                                          color: AppColors.darkPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),

                              // Focus/Type
                              if (day['focus'] != null)
                                Text(
                                  'Focus: ${day['focus']}',
                                  style: TextStyle(
                                    color: _tertiaryTextColor,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),

                              // Rest Day
                              if (day['type'] == 'rest') ...[
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.self_improvement,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Rest Day - Recovery and light stretching',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                              // Workout Day with Exercises
                              else if (day['exercises'] != null &&
                                  day['exercises'] is List) ...[
                                SizedBox(height: 12),
                                Text(
                                  'Exercises:',
                                  style: TextStyle(
                                    color: _primaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...((day['exercises'] as List).map((exercise) {
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDarkTheme
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkTheme
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Exercise Name
                                        Text(
                                          exercise['name'] ??
                                              exercise['exercise'] ??
                                              'Exercise',
                                          style: TextStyle(
                                            color: _primaryTextColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Sets, Reps, Duration
                                        Row(
                                          children: [
                                            if (exercise['sets'] != null) ...[
                                              Icon(
                                                Icons.repeat,
                                                color: AppColors.darkPrimary,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${exercise['sets']} sets',
                                                style: TextStyle(
                                                  color: _secondaryTextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (exercise['reps'] != null ||
                                                  exercise['duration'] != null)
                                                Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    color: _secondaryTextColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                            if (exercise['reps'] != null) ...[
                                              Text(
                                                '${exercise['reps']} reps',
                                                style: TextStyle(
                                                  color: _secondaryTextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ] else if (exercise['duration'] !=
                                                null) ...[
                                              Icon(
                                                Icons.timer,
                                                color: AppColors.darkPrimary,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${exercise['duration']}',
                                                style: TextStyle(
                                                  color: _secondaryTextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        // Rest Period
                                        if (exercise['rest'] != null) ...[
                                          SizedBox(height: 2),
                                          Text(
                                            'Rest: ${exercise['rest']}',
                                            style: TextStyle(
                                              color: _tertiaryTextColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                        // Notes/Instructions
                                        if (exercise['notes'] != null ||
                                            exercise['instructions'] !=
                                                null) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            exercise['notes'] ??
                                                exercise['instructions'],
                                            style: TextStyle(
                                              color: _tertiaryTextColor,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList()),
                              ]
                              // Fallback for exercises without detailed structure
                              else if (day['exercises'] != null) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Exercises included in this day',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList()),
                      if ((workoutPlan['schedule'] as List).length > 5)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '... and ${(workoutPlan['schedule'] as List).length - 5} more days in the complete plan',
                            style: TextStyle(
                              color: _tertiaryTextColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                    ],

                    // AI Tips
                    if (workoutPlan['tips'] != null &&
                        workoutPlan['tips'] is List) ...[
                      Text(
                        'AI Recommendations',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...((workoutPlan['tips'] as List).map((tip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.darkPrimary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tip.toString(),
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onShare();
                      },
                      icon: Icon(Icons.share, size: 18),
                      label: Text('Share Plan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkPrimary,
                        side: BorderSide(color: AppColors.darkPrimary),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDownload();
                      },
                      icon: Icon(Icons.download, size: 18),
                      label: Text('Download Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(color: _primaryTextColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// New Bulking Results Dialog
class BulkingResultsDialog extends StatelessWidget {
  final Map<String, dynamic> results;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool isDarkTheme; // Add theme parameter

  const BulkingResultsDialog({
    Key? key,
    required this.results,
    required this.onDownload,
    required this.onShare,
    required this.isDarkTheme, // Make it required
  }) : super(key: key);

  BoxDecoration _getDialogDecoration() {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(40, 50, 49, 1.0),
            Color.fromARGB(255, 30, 30, 30),
            Color.fromRGBO(33, 43, 42, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.8),
          width: 0.5,
        ),
      );
    } else {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Color get _primaryTextColor => isDarkTheme ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      isDarkTheme ? Colors.white70 : Colors.black54;
  Color get _tertiaryTextColor => isDarkTheme ? Colors.white60 : Colors.black45;
  Color get _iconColor => isDarkTheme ? Colors.white70 : Colors.black54;
  Color get _cardBackgroundColor => isDarkTheme
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.05);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: _getDialogDecoration(),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.darkPrimary,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Bulking Macro Plan',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: _iconColor),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Macros
                    Text(
                      'Daily Macro Targets',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMacroCard(
                                  'Calories',
                                  results['calories'],
                                  'cal',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildMacroCard(
                                  'Protein',
                                  results['protein'],
                                  'g',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMacroCard(
                                  'Carbs',
                                  results['carbs'],
                                  'g',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildMacroCard(
                                  'Fat',
                                  results['fat'],
                                  'g',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Metabolic Information
                    Text(
                      'Metabolic Information',
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'BMR (Basal Metabolic Rate)',
                            '${results['bmr']} calories/day',
                          ),
                          _buildInfoRow(
                            'TDEE (Total Daily Energy)',
                            '${results['tdee']} calories/day',
                          ),
                          _buildInfoRow(
                            'Caloric Surplus',
                            '${results['surplus']} calories/day',
                          ),
                          if (results['weeklyGainRate'] != null)
                            _buildInfoRow(
                              'Expected Weekly Gain',
                              '${results['weeklyGainRate']} kg/week',
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // AI Recommendations
                    if (results['recommendations'] != null &&
                        results['recommendations'] is List) ...[
                      Text(
                        'AI Nutrition Recommendations',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...((results['recommendations'] as List).map((rec) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: AppColors.darkPrimary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec.toString(),
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    ],

                    // Meal Timing
                    if (results['mealTiming'] != null &&
                        results['mealTiming'] is List) ...[
                      SizedBox(height: 20),
                      Text(
                        'Suggested Meal Timing',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...((results['mealTiming'] as List).map((meal) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkTheme
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                meal['time'] ?? '',
                                style: TextStyle(
                                  color: AppColors.darkPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  meal['description'] ?? '',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onShare();
                      },
                      icon: Icon(Icons.share, size: 18),
                      label: Text('Share Plan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkPrimary,
                        side: BorderSide(color: AppColors.darkPrimary),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDownload();
                      },
                      icon: Icon(Icons.download, size: 18),
                      label: Text('Download Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildMacroCard(String title, dynamic value, String unit) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${value?.toString() ?? '0'}',
            style: TextStyle(
              color: AppColors.darkPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(unit, style: TextStyle(color: _tertiaryTextColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: _secondaryTextColor, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: _primaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
