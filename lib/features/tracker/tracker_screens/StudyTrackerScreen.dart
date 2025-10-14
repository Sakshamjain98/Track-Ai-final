import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class StudyTrackerScreen extends StatefulWidget {
  const StudyTrackerScreen({Key? key}) : super(key: key);

  @override
  State<StudyTrackerScreen> createState() => _StudyTrackerScreenState();
}

class _StudyTrackerScreenState extends State<StudyTrackerScreen>
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
  final _valueController = TextEditingController();
  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

  // Study-specific fields
  String? _selectedSubject;
  String? _selectedLocation;
  String? _selectedStudyType;
  int _selectedFocus = 5;
  int _selectedProductivity = 5;

  final List<Map<String, dynamic>> _subjectTypes = [
    {'name': 'Mathematics', 'icon': '🔢', 'color': Color(0xFF3B82F6), 'description': 'Numbers & calculations'},
    {'name': 'Science', 'icon': '🧪', 'color': Color(0xFF10B981), 'description': 'Physics, chemistry, biology'},
    {'name': 'Literature', 'icon': '📚', 'color': Color(0xFF8B5CF6), 'description': 'Reading & writing'},
    {'name': 'History', 'icon': '🏛️', 'color': Color(0xFFF59E0B), 'description': 'Past events & cultures'},
    {'name': 'Language', 'icon': '🗣️', 'color': Color(0xFFEF4444), 'description': 'Foreign languages'},
    {'name': 'Art', 'icon': '🎨', 'color': Color(0xFFEC4899), 'description': 'Creative & visual arts'},
    {'name': 'Technology', 'icon': '💻', 'color': Color(0xFF06B6D4), 'description': 'Programming & tech'},
    {'name': 'Other', 'icon': '📖', 'color': Color(0xFF6B7280), 'description': 'Different subject'},
  ];

  final List<Map<String, dynamic>> _studyTypes = [
    {'name': 'Reading', 'icon': '📖', 'color': Color(0xFF3B82F6), 'description': 'Reading textbooks/materials'},
    {'name': 'Practice', 'icon': '✍️', 'color': Color(0xFF10B981), 'description': 'Solving problems'},
    {'name': 'Research', 'icon': '🔍', 'color': Color(0xFF8B5CF6), 'description': 'Finding information'},
    {'name': 'Review', 'icon': '🔄', 'color': Color(0xFFF59E0B), 'description': 'Reviewing notes'},
    {'name': 'Project', 'icon': '🛠️', 'color': Color(0xFFEF4444), 'description': 'Working on assignments'},
    {'name': 'Group Study', 'icon': '👥', 'color': Color(0xFFEC4899), 'description': 'Studying with others'},
  ];

  final List<String> _locations = [
    'Home', 'Library', 'Coffee Shop', 'School', 'Office', 'Park', 'Online', 'Other'
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
    _valueController.dispose();
    _subjectController.dispose();
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
        'value': double.tryParse(_valueController.text) ?? 0.0,
        'subjectTopic': _selectedSubject ?? _subjectController.text.trim(),
        'studyType': _selectedStudyType ?? '',
        'focusLevel': _selectedFocus,
        'productivity': _selectedProductivity,
        'location': _selectedLocation ?? _locationController.text.trim(),
        'notes': _notesController.text.trim(),
        'customData': customData,
        'trackerType': 'study',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await TrackerService.saveTrackerEntry('study', entryData);

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
                Text('Study session logged successfully! 📚'),
              ],
            ),
            backgroundColor: _getCurrentStudyColor(),
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

  Color _getCurrentStudyColor() {
    if (_selectedSubject != null) {
      final subject = _subjectTypes.firstWhere(
            (s) => s['name'] == _selectedSubject,
        orElse: () => _subjectTypes[0],
      );
      return subject['color'];
    }
    return const Color(0xFF00BCD4);
  }

  String _getCurrentStudyEmoji() {
    if (_selectedSubject != null) {
      final subject = _subjectTypes.firstWhere(
            (s) => s['name'] == _selectedSubject,
        orElse: () => _subjectTypes[0],
      );
      return subject['icon'];
    }
    return '📚';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
                          _buildStep1(isDark), // Subject Selection
                          _buildStep2(isDark), // Study Type & Duration
                          _buildStep3(isDark), // Focus & Productivity
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
                  'Study Tracker',
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

          // Study Icon - Fixed Size
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCurrentStudyColor(),
                  _getCurrentStudyColor().withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _getCurrentStudyColor().withValues(alpha: 0.3),
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
                      _getCurrentStudyEmoji(),
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
                          ? _getCurrentStudyColor()
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
                  color: _getCurrentStudyColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                  style: TextStyle(
                    color: _getCurrentStudyColor(),
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
      case 0: return 'Choose subject';
      case 1: return 'Study details';
      case 2: return 'Focus & productivity';
      case 3: return 'Location & notes';
      case 4: return 'Custom metrics';
      case 5: return 'Review & save';
      default: return '';
    }
  }

  // Step 1: Subject Selection - RESPONSIVE VERSION
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
                                    _getCurrentStudyColor().withValues(alpha: 0.3),
                                    _getCurrentStudyColor().withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '📚',
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
                      'What subject are\nyou studying today?',
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
                      'Select the subject you\'ll be focusing on',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Subject Types Grid - Responsive
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSmallHeight ? 1.4 : 1.2,
                      ),
                      itemCount: _subjectTypes.length,
                      itemBuilder: (context, index) {
                        final subject = _subjectTypes[index];
                        final isSelected = _selectedSubject == subject['name'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubject = subject['name'];
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
                                  subject['color'].withValues(alpha: 0.2),
                                  subject['color'].withValues(alpha: 0.1),
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
                                    ? subject['color']
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: subject['color'].withValues(alpha: 0.3),
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
                                  subject['icon'],
                                  style: TextStyle(fontSize: isSmallHeight ? 32 : 36),
                                ),
                                SizedBox(height: isSmallHeight ? 6 : 10),
                                Text(
                                  subject['name'],
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: isSmallHeight ? 13 : 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallHeight ? 2 : 4),
                                Text(
                                  subject['description'],
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

  // Step 2: Study Type & Duration - RESPONSIVE VERSION
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
                    'Study Type &\nDuration',
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
                    'What type of studying and for how long?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Study Duration
                  _buildModernTextField(
                    controller: _valueController,
                    label: 'Study Duration (hours)',
                    hint: '1.5, 2.0, 3.0...',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                    prefixIcon: Icons.timer_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter study duration';
                      if (double.tryParse(value) == null) return 'Please enter a valid number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Study Type Selection Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Type of Study',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Study Types Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallHeight ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isSmallHeight ? 1.6 : 1.8,
                    ),
                    itemCount: _studyTypes.length,
                    itemBuilder: (context, index) {
                      final type = _studyTypes[index];
                      final isSelected = _selectedStudyType == type['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStudyType = type['name'];
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSmallHeight ? 8 : 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                type['color'].withValues(alpha: 0.2),
                                type['color'].withValues(alpha: 0.1),
                              ],
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
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                type['icon'],
                                style: TextStyle(fontSize: isSmallHeight ? 20 : 24),
                              ),
                              SizedBox(height: isSmallHeight ? 4 : 8),
                              Text(
                                type['name'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: isSmallHeight ? 11 : 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!isSmallHeight) ...[
                                const SizedBox(height: 2),
                                Text(
                                  type['description'],
                                  style: TextStyle(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
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
    final durations = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0];

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
            'Common durations (hours)',
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
                _valueController.text = duration.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentStudyColor().withValues(alpha: 0.1),
                      _getCurrentStudyColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentStudyColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${duration}h',
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

  // Step 3: Focus & Productivity - RESPONSIVE VERSION
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
                          Icons.psychology_outlined,
                          size: 50,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Focus & Productivity\nLevels',
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
                    'Rate your focus and productivity during study',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Focus Level Slider
                  _buildFocusSlider(isDark, isSmallHeight),

                  const SizedBox(height: 24),

                  // Productivity Level Slider
                  _buildProductivitySlider(isDark, isSmallHeight),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFocusSlider(bool isDark, bool isSmall) {
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
            'Focus Level',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How focused were you during study? (1-10)',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          SizedBox(height: isSmall ? 16 : 20),

          // Focus Value Display
          Center(
            child: Container(
              width: isSmall ? 60 : 70,
              height: isSmall ? 60 : 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCurrentStudyColor(),
                    _getCurrentStudyColor().withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getCurrentStudyColor().withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_selectedFocus',
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
              activeTrackColor: _getCurrentStudyColor(),
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              thumbColor: _getCurrentStudyColor(),
              overlayColor: _getCurrentStudyColor().withValues(alpha: 0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmall ? 10 : 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: isSmall ? 20 : 24),
            ),
            child: Slider(
              value: _selectedFocus.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _selectedFocus = value.round();
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
                'Distracted',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Very Focused',
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

  Widget _buildProductivitySlider(bool isDark, bool isSmall) {
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
            'Productivity Level',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How productive was your study session? (1-10)',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          SizedBox(height: isSmall ? 16 : 20),

          // Productivity Value Display
          Center(
            child: Container(
              width: isSmall ? 60 : 70,
              height: isSmall ? 60 : 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981),
                    const Color(0xFF10B981).withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_selectedProductivity',
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
              activeTrackColor: const Color(0xFF10B981),
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF10B981),
              overlayColor: const Color(0xFF10B981).withValues(alpha: 0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmall ? 10 : 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: isSmall ? 20 : 24),
            ),
            child: Slider(
              value: _selectedProductivity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _selectedProductivity = value.round();
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
                'Not Productive',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Very Productive',
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

  // Step 4: Location & Notes - RESPONSIVE VERSION
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
                          Icons.place_outlined,
                          size: 50,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Study Location\n& Notes',
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
                    'Where did you study and any additional notes?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Location Dropdown
                  _buildModernDropdown(
                    label: 'Study Location',
                    value: _selectedLocation,
                    items: _locations,
                    hint: 'Where did you study?',
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // Custom Subject Input (if "Other" selected)
                  if (_selectedSubject == 'Other') ...[
                    _buildModernTextField(
                      controller: _subjectController,
                      label: 'Custom Subject',
                      hint: 'What subject did you study?',
                      isDark: isDark,
                      prefixIcon: Icons.subject_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Custom Location Input (if "Other" selected)
                  if (_selectedLocation == 'Other') ...[
                    _buildModernTextField(
                      controller: _locationController,
                      label: 'Custom Location',
                      hint: 'Where did you study?',
                      isDark: isDark,
                      prefixIcon: Icons.place_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Notes
                  _buildModernTextField(
                    controller: _notesController,
                    label: 'Study Notes (Optional)',
                    hint: 'Any observations, difficulties, or achievements...',
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
    final suggestions = _locations.take(6).toList();

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
            'Popular study locations',
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
            children: suggestions.map((location) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentStudyColor().withValues(alpha: 0.1),
                      _getCurrentStudyColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentStudyColor().withValues(alpha: 0.3),
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

  // Step 5: Custom Fields - RESPONSIVE VERSION
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
                    'Add any custom study metrics you want to track',
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
          'Add metrics like resources used,\ndifficulty level, or progress made',
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
                          hint: 'e.g., Resources Used',
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
                    hint: 'e.g., Textbook, Online course',
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

  // Step 6: Review & Save - RESPONSIVE VERSION
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
                    'Review Study Session',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your study details before saving',
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
                          if (_selectedSubject != null)
                            _buildReviewCard('Subject', _selectedSubject!, Icons.subject, _getCurrentStudyColor(), isDark),

                          if (_valueController.text.isNotEmpty)
                            _buildReviewCard('Duration', '${_valueController.text} hours', Icons.schedule, Colors.blue, isDark),

                          if (_selectedStudyType != null)
                            _buildReviewCard('Study Type', _selectedStudyType!, Icons.book, Colors.green, isDark),

                          _buildReviewCard('Focus Level', '$_selectedFocus/10', Icons.psychology, Colors.orange, isDark),

                          _buildReviewCard('Productivity', '$_selectedProductivity/10', Icons.trending_up, Colors.purple, isDark),

                          if (_selectedLocation != null)
                            _buildReviewCard('Location', _selectedLocation!, Icons.place, Colors.teal, isDark),

                          if (_subjectController.text.isNotEmpty && _selectedSubject == 'Other')
                            _buildReviewCard('Custom Subject', _subjectController.text, Icons.subject, Colors.indigo, isDark),

                          if (_locationController.text.isNotEmpty && _selectedLocation == 'Other')
                            _buildReviewCard('Custom Location', _locationController.text, Icons.place, Colors.cyan, isDark),

                          if (_notesController.text.isNotEmpty)
                            _buildReviewCard('Notes', _notesController.text, Icons.note_alt, Colors.amber, isDark),

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
                                    'Saving Session...',
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
                                    _getCurrentStudyEmoji(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Study Session',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCurrentStudyColor(),
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
                  backgroundColor: _getCurrentStudyColor(),
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
    String? Function(String?)? validator,
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
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
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
