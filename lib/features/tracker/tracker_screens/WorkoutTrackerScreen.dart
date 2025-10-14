import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _detailsController = TextEditingController();
  final _durationController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

  // Workout-specific fields
  String? _selectedIntensity;
  int _selectedExertion = 5;
  String? _selectedWorkoutType;

  final List<Map<String, dynamic>> _workoutTypes = [
    {'name': 'Cardio', 'icon': '🏃', 'color': Color(0xFFE91E63), 'description': 'Running, cycling, swimming'},
    {'name': 'Strength', 'icon': '🏋️', 'color': Color(0xFF3F51B5), 'description': 'Weight lifting, resistance'},
    {'name': 'Yoga', 'icon': '🧘', 'color': Color(0xFF9C27B0), 'description': 'Flexibility & mindfulness'},
    {'name': 'HIIT', 'icon': '⚡', 'color': Color(0xFFFF5722), 'description': 'High intensity intervals'},
    {'name': 'Sports', 'icon': '⚽', 'color': Color(0xFF4CAF50), 'description': 'Team & individual sports'},
    {'name': 'Dance', 'icon': '💃', 'color': Color(0xFFFF9800), 'description': 'Dance fitness & movement'},
    {'name': 'Walking', 'icon': '🚶', 'color': Color(0xFF607D8B), 'description': 'Light cardio & recovery'},
    {'name': 'Other', 'icon': '🤸', 'color': Color(0xFF795548), 'description': 'Custom workout types'},
  ];

  final List<String> _intensityLevels = [
    'Very Light (1-2)',
    'Light (3-4)',
    'Moderate (5-6)',
    'Hard (7-8)',
    'Very Hard (9-10)'
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _detailsController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _notesController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _slideController.forward();
    _scaleController.forward();
  }

  void _addCustomField() {
    HapticFeedback.selectionClick();
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customData = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }

      final entryData = {
        'details': _detailsController.text.trim(),
        'duration': int.tryParse(_durationController.text) ?? 0,
        'exertion': _selectedExertion,
        'intensity': _selectedIntensity ?? '',
        'workoutType': _selectedWorkoutType ?? '',
        'location': _locationController.text.trim(),
        'notes': _notesController.text.trim(),
        'customData': customData,
        'trackerType': 'workout',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await TrackerService.saveTrackerEntry('workout', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text('Workout saved successfully! 💪'),
              ],
            ),
            backgroundColor: _getCurrentWorkoutColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getCurrentWorkoutColor() {
    if (_selectedWorkoutType != null) {
      final type = _workoutTypes.firstWhere(
            (t) => t['name'] == _selectedWorkoutType,
        orElse: () => _workoutTypes[0],
      );
      return type['color'];
    }
    return const Color(0xFFFF5722);
  }

  String _getCurrentWorkoutEmoji() {
    if (_selectedWorkoutType != null) {
      final type = _workoutTypes.firstWhere(
            (t) => t['name'] == _selectedWorkoutType,
        orElse: () => _workoutTypes[0],
      );
      return type['icon'];
    }
    return '💪';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1426) : const Color(0xFFF8FAFC),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                  const Color(0xFF0B1426),
                  const Color(0xFF162544),
                  const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                ]
                    : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE2E8F0),
                  const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Modern Header - Fixed Height
                    SizedBox(
                      height: isSmallScreen ? 80 : 100,
                      child: _buildModernHeader(isDark),
                    ),

                    // Progress Indicator - Fixed Height
                    SizedBox(
                      height: isSmallScreen ? 60 : 80,
                      child: _buildProgressIndicator(isDark),
                    ),

                    // Page View - Flexible with proper constraints
                    Flexible(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Workout Type
                          _buildStep2(isDark), // Duration & Details
                          _buildStep3(isDark), // Intensity & Exertion
                          _buildStep4(isDark), // Location & Notes
                          _buildStep5(isDark), // Custom Fields
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Modern Navigation - Fixed Height
                    SizedBox(
                      height: isSmallScreen ? 80 : 100,
                      child: _buildModernNavigation(isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title - Flexible
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Workout Tracker',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getStepTitle(_currentStep),
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Workout Icon - Fixed Size
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCurrentWorkoutColor(),
                  _getCurrentWorkoutColor().withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _getCurrentWorkoutColor().withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Text(
                      _getCurrentWorkoutEmoji(),
                      style: TextStyle(fontSize: 24),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? _getCurrentWorkoutColor()
                          : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCurrentWorkoutColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                  style: TextStyle(
                    color: _getCurrentWorkoutColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Choose workout type';
      case 1: return 'Duration & details';
      case 2: return 'Intensity level';
      case 3: return 'Location & notes';
      case 4: return 'Custom metrics';
      case 5: return 'Review & save';
      default: return '';
    }
  }

  // Step 1: Workout Type Selection - FIXED VERSION
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero Section - Responsive
                    if (!isSmallHeight) ...[
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_pulseAnimation.value - 0.8) * 0.3,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    _getCurrentWorkoutColor().withValues(alpha: 0.3),
                                    _getCurrentWorkoutColor().withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '💪',
                                  style: TextStyle(fontSize: 60),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'What type of workout\nwill you do today?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: isSmallHeight ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your preferred workout activity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Workout Types Grid - Responsive
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSmallHeight ? 1.4 : 1.2,
                      ),
                      itemCount: _workoutTypes.length,
                      itemBuilder: (context, index) {
                        final type = _workoutTypes[index];
                        final isSelected = _selectedWorkoutType == type['name'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWorkoutType = type['name'];
                            });
                            HapticFeedback.mediumImpact();
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) _nextStep();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSmallHeight ? 12 : 16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                colors: [
                                  type['color'].withValues(alpha: 0.2),
                                  type['color'].withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : LinearGradient(
                                colors: [
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.9),
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.white.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? type['color']
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: type['color'].withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  type['icon'],
                                  style: TextStyle(fontSize: isSmallHeight ? 32 : 36),
                                ),
                                SizedBox(height: isSmallHeight ? 6 : 10),
                                Text(
                                  type['name'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: isSmallHeight ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallHeight ? 2 : 4),
                                Text(
                                  type['description'],
                                  style: TextStyle(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Step 2: Duration & Details - FIXED VERSION
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Hero Section - Conditional based on height
                  if (!isSmallHeight) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            const Color(0xFF3B82F6).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.schedule,
                          size: 50,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Workout Duration\n& Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How long was your ${_selectedWorkoutType?.toLowerCase() ?? 'workout'}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Fields
                  _buildModernTextField(
                    controller: _durationController,
                    label: 'Duration (minutes)',
                    hint: '30, 45, 60...',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    prefixIcon: Icons.timer_outlined,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: _detailsController,
                    label: 'Workout Details',
                    hint: 'Describe what you did...',
                    isDark: isDark,
                    maxLines: isSmallHeight ? 3 : 4,
                    prefixIcon: Icons.fitness_center,
                  ),

                  const SizedBox(height: 16),

                  // Duration Suggestions
                  _buildDurationSuggestions(isDark),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationSuggestions(bool isDark) {
    final durations = [15, 30, 45, 60, 90, 120];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common durations (minutes)',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((duration) => GestureDetector(
              onTap: () {
                _durationController.text = duration.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentWorkoutColor().withValues(alpha: 0.1),
                      _getCurrentWorkoutColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentWorkoutColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${duration}min',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 3: Intensity & Exertion - FIXED VERSION
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Hero Section - Conditional
                  if (!isSmallHeight) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFEF4444).withValues(alpha: 0.3),
                            const Color(0xFFEF4444).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_fire_department,
                          size: 50,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'How Intense Was\nYour Workout?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rate your intensity and exertion level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Intensity Dropdown
                  _buildModernDropdown(
                    label: 'Intensity Level',
                    value: _selectedIntensity,
                    items: _intensityLevels,
                    hint: 'Select intensity level',
                    onChanged: (value) {
                      setState(() {
                        _selectedIntensity = value;
                      });
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // Exertion Slider
                  _buildExertionSlider(isDark, isSmallHeight),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExertionSlider(bool isDark, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exertion Level',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How hard did you work? (1-10)',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          SizedBox(height: isSmall ? 16 : 20),

          // Exertion Value Display
          Center(
            child: Container(
              width: isSmall ? 60 : 70,
              height: isSmall ? 60 : 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCurrentWorkoutColor(),
                    _getCurrentWorkoutColor().withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getCurrentWorkoutColor().withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_selectedExertion',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 24 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmall ? 16 : 20),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getCurrentWorkoutColor(),
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              thumbColor: _getCurrentWorkoutColor(),
              overlayColor: _getCurrentWorkoutColor().withValues(alpha: 0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmall ? 10 : 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: isSmall ? 20 : 24),
            ),
            child: Slider(
              value: _selectedExertion.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _selectedExertion = value.round();
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),

          const SizedBox(height: 8),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Light',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Maximum',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 4: Location & Notes - FIXED VERSION
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Hero Section - Conditional
                  if (!isSmallHeight) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                            const Color(0xFF10B981).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 50,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Location & Notes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where did you workout and any additional notes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Fields
                  _buildModernTextField(
                    controller: _locationController,
                    label: 'Location (Optional)',
                    hint: 'Gym, Home, Park...',
                    isDark: isDark,
                    prefixIcon: Icons.place_outlined,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: _notesController,
                    label: 'Additional Notes (Optional)',
                    hint: 'Any observations or thoughts...',
                    isDark: isDark,
                    maxLines: isSmallHeight ? 3 : 4,
                    prefixIcon: Icons.note_alt_outlined,
                  ),

                  const SizedBox(height: 16),

                  // Location Suggestions
                  _buildLocationSuggestions(isDark),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationSuggestions(bool isDark) {
    final locations = ['Gym', 'Home', 'Park', 'Beach', 'Studio', 'Track'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular locations',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations.map((location) => GestureDetector(
              onTap: () {
                _locationController.text = location;
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.1),
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 5: Custom Fields - FIXED VERSION
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  if (!isSmallHeight) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune,
                        size: 40,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'Custom Metrics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add any custom data you want to track',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Custom Fields Content - Flexible
                  Flexible(
                    child: _customFields.isEmpty
                        ? _buildEmptyCustomFields(isDark)
                        : _buildCustomFieldsList(isDark),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_circle_outline,
            size: 30,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No custom fields yet',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add metrics like weight lifted,\nreps, sets, or heart rate',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildAddFieldButton(isDark),
      ],
    );
  }

  Widget _buildCustomFieldsList(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Custom Fields
          ..._customFields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                )
                    : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: field['key']!,
                          label: 'Field Name',
                          hint: 'e.g., Weight Lifted',
                          isDark: isDark,
                          prefixIcon: Icons.label_outline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeCustomField(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModernTextField(
                    controller: field['value']!,
                    label: 'Field Value',
                    hint: 'e.g., 80kg',
                    isDark: isDark,
                    prefixIcon: Icons.edit_outlined,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildAddFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddFieldButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          'Add Custom Field',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // Step 6: Review & Save - FIXED VERSION
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallHeight = constraints.maxHeight < 500;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  if (!isSmallHeight) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF059669).withValues(alpha: 0.3),
                            const Color(0xFF059669).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    'Review Your Workout',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your details before saving',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Review Content - Flexible
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Review Cards
                          if (_selectedWorkoutType != null)
                            _buildReviewCard('Workout Type', _selectedWorkoutType!, Icons.fitness_center, _getCurrentWorkoutColor(), isDark),

                          if (_durationController.text.isNotEmpty)
                            _buildReviewCard('Duration', '${_durationController.text} minutes', Icons.schedule, Colors.blue, isDark),

                          if (_detailsController.text.isNotEmpty)
                            _buildReviewCard('Details', _detailsController.text, Icons.notes, Colors.green, isDark),

                          if (_selectedIntensity != null)
                            _buildReviewCard('Intensity', _selectedIntensity!, Icons.local_fire_department, Colors.orange, isDark),

                          _buildReviewCard('Exertion Level', '$_selectedExertion/10', Icons.trending_up, Colors.red, isDark),

                          if (_locationController.text.isNotEmpty)
                            _buildReviewCard('Location', _locationController.text, Icons.place, Colors.purple, isDark),

                          if (_notesController.text.isNotEmpty)
                            _buildReviewCard('Notes', _notesController.text, Icons.note_alt, Colors.teal, isDark),

                          // Custom Fields Review
                          if (_customFields.isNotEmpty) ...[
                            ..._customFields.map((field) {
                              final key = field['key']?.text ?? '';
                              final value = field['value']?.text ?? '';
                              if (key.isNotEmpty && value.isNotEmpty) {
                                return _buildReviewCard(key, value, Icons.settings, Colors.grey, isDark);
                              }
                              return const SizedBox.shrink();
                            }),
                          ],

                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveEntry,
                              child: _isLoading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Saving Workout...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getCurrentWorkoutEmoji(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Workout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCurrentWorkoutColor(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavigation(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? Colors.white : Colors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next Button
          if (_currentStep < _totalSteps - 1)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCurrentWorkoutColor(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper Widgets - RESPONSIVE VERSIONS
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                prefixIcon,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                size: 20,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    String? value,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                Colors.white.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint ?? 'Select $label',
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            dropdownColor: isDark ? const Color(0xFF162544) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.expand_more,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
