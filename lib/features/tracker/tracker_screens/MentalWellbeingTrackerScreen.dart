import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class MentalWellbeingTrackerScreen extends StatefulWidget {
  const MentalWellbeingTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MentalWellbeingTrackerScreen> createState() => _MentalWellbeingTrackerScreenState();
}

class _MentalWellbeingTrackerScreenState extends State<MentalWellbeingTrackerScreen>
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
  final _triggersController = TextEditingController();
  final _copingController = TextEditingController();
  final _thoughtsController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

  // Mental wellbeing specific fields
  String? _selectedWellbeing;
  String? _selectedStress;
  String? _selectedMood;
  int _selectedAnxiety = 1;

  final List<Map<String, dynamic>> _wellbeingLevels = [
    {'name': 'Very Poor (1)', 'value': 1, 'color': Color(0xFFDC2626), 'icon': '😞', 'description': 'Feeling very low'},
    {'name': 'Poor (2)', 'value': 2, 'color': Color(0xFFF59E0B), 'icon': '😔', 'description': 'Having difficulties'},
    {'name': 'Fair (3)', 'value': 3, 'color': Color(0xFF6B7280), 'icon': '😐', 'description': 'Getting by okay'},
    {'name': 'Good (4)', 'value': 4, 'color': Color(0xFF059669), 'icon': '😊', 'description': 'Feeling positive'},
    {'name': 'Excellent (5)', 'value': 5, 'color': Color(0xFF10B981), 'icon': '😁', 'description': 'Thriving & happy'},
  ];

  final List<Map<String, dynamic>> _stressLevels = [
    {'name': 'No Stress (1)', 'value': 1, 'color': Color(0xFF10B981), 'icon': '😌', 'description': 'Completely relaxed'},
    {'name': 'Mild (2-3)', 'value': 2, 'color': Color(0xFF8BC34A), 'icon': '🙂', 'description': 'Minor pressure'},
    {'name': 'Moderate (4-5)', 'value': 4, 'color': Color(0xFFF59E0B), 'icon': '😕', 'description': 'Noticeable stress'},
    {'name': 'High (6-7)', 'value': 6, 'color': Color(0xFFFF5722), 'icon': '😰', 'description': 'Significant pressure'},
    {'name': 'Severe (8-9)', 'value': 8, 'color': Color(0xFFDC2626), 'icon': '😫', 'description': 'Overwhelming stress'},
    {'name': 'Extreme (10)', 'value': 10, 'color': Color(0xFF991B1B), 'icon': '😵', 'description': 'Crisis level'},
  ];

  final List<Map<String, dynamic>> _moodTypes = [
    {'name': 'Happy', 'icon': '😊', 'color': Color(0xFF10B981), 'description': 'Feeling joyful & content'},
    {'name': 'Excited', 'icon': '🤩', 'color': Color(0xFFEAB308), 'description': 'Energetic & enthusiastic'},
    {'name': 'Calm', 'icon': '😌', 'color': Color(0xFF3B82F6), 'description': 'Peaceful & relaxed'},
    {'name': 'Neutral', 'icon': '😐', 'color': Color(0xFF6B7280), 'description': 'Balanced & steady'},
    {'name': 'Sad', 'icon': '😢', 'color': Color(0xFF8B5CF6), 'description': 'Feeling down or blue'},
    {'name': 'Anxious', 'icon': '😰', 'color': Color(0xFFFF5722), 'description': 'Worried & restless'},
    {'name': 'Angry', 'icon': '😠', 'color': Color(0xFFDC2626), 'description': 'Frustrated or upset'},
    {'name': 'Other', 'icon': '🤔', 'color': Color(0xFF78716C), 'description': 'Complex feelings'},
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
    _triggersController.dispose();
    _copingController.dispose();
    _thoughtsController.dispose();

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
        'wellbeing': _selectedWellbeing ?? '',
        'stress': _selectedStress ?? '',
        'mood': _selectedMood ?? '',
        'anxiety': _selectedAnxiety,
        'triggers': _triggersController.text.trim(),
        'copingMechanisms': _copingController.text.trim(),
        'thoughts': _thoughtsController.text.trim(),
        'customData': customData,
        'trackerType': 'mental_wellbeing',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await TrackerService.saveTrackerEntry('mental_wellbeing', entryData);

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
                Text('Mental wellbeing logged successfully! 🧠'),
              ],
            ),
            backgroundColor: _getCurrentMentalColor(),
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

  Color _getCurrentMentalColor() {
    if (_selectedMood != null) {
      final mood = _moodTypes.firstWhere(
            (m) => m['name'] == _selectedMood,
        orElse: () => _moodTypes[3], // Default to Neutral
      );
      return mood['color'];
    }
    return const Color(0xFF6B7280);
  }

  String _getCurrentMentalEmoji() {
    if (_selectedMood != null) {
      final mood = _moodTypes.firstWhere(
            (m) => m['name'] == _selectedMood,
        orElse: () => _moodTypes[3],
      );
      return mood['icon'];
    }
    return '🧠';
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
                          _buildStep1(isDark), // Mood Selection
                          _buildStep2(isDark), // Wellbeing Scale
                          _buildStep3(isDark), // Stress & Anxiety
                          _buildStep4(isDark), // Triggers & Coping
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
                  'Mental Wellbeing',
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

          // Mental Icon - Fixed Size
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCurrentMentalColor(),
                  _getCurrentMentalColor().withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _getCurrentMentalColor().withValues(alpha: 0.3),
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
                      _getCurrentMentalEmoji(),
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
                          ? _getCurrentMentalColor()
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
                  color: _getCurrentMentalColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                  style: TextStyle(
                    color: _getCurrentMentalColor(),
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
      case 0: return 'Current mood';
      case 1: return 'Wellbeing level';
      case 2: return 'Stress & anxiety';
      case 3: return 'Triggers & coping';
      case 4: return 'Custom metrics';
      case 5: return 'Review & save';
      default: return '';
    }
  }

  // Step 1: Mood Selection - RESPONSIVE VERSION
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
                                    _getCurrentMentalColor().withValues(alpha: 0.3),
                                    _getCurrentMentalColor().withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '🧠',
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
                      'How are you\nfeeling today?',
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
                      'Select your current mood and emotional state',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Mood Types Grid - Responsive
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallHeight ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSmallHeight ? 1.2 : 1.3,
                      ),
                      itemCount: _moodTypes.length,
                      itemBuilder: (context, index) {
                        final mood = _moodTypes[index];
                        final isSelected = _selectedMood == mood['name'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = mood['name'];
                            });
                            HapticFeedback.mediumImpact();
                            if (isSelected) {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) _nextStep();
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSmallHeight ? 8 : 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                colors: [
                                  mood['color'].withValues(alpha: 0.2),
                                  mood['color'].withValues(alpha: 0.1),
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
                                    ? mood['color']
                                    : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: mood['color'].withValues(alpha: 0.3),
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
                                  mood['icon'],
                                  style: TextStyle(fontSize: isSmallHeight ? 28 : 32),
                                ),
                                SizedBox(height: isSmallHeight ? 4 : 8),
                                Text(
                                  mood['name'],
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
                                    mood['description'],
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                      fontSize: 9,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

  // Step 2: Wellbeing Scale - RESPONSIVE VERSION
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
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                            const Color(0xFF10B981).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.favorite_outline,
                          size: 50,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Overall Wellbeing\nLevel Today',
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
                    'Rate your general well-being on a scale of 1-5',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Wellbeing Levels Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallHeight ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isSmallHeight ? 1.4 : 1.6,
                    ),
                    itemCount: _wellbeingLevels.length,
                    itemBuilder: (context, index) {
                      final level = _wellbeingLevels[index];
                      final isSelected = _selectedWellbeing == level['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWellbeing = level['name'];
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
                                level['color'].withValues(alpha: 0.2),
                                level['color'].withValues(alpha: 0.1),
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
                                  ? level['color']
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: level['color'].withValues(alpha: 0.3),
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
                                level['icon'],
                                style: TextStyle(fontSize: isSmallHeight ? 24 : 28),
                              ),
                              SizedBox(height: isSmallHeight ? 4 : 8),
                              Text(
                                level['name'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: isSmallHeight ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!isSmallHeight) ...[
                                const SizedBox(height: 2),
                                Text(
                                  level['description'],
                                  style: TextStyle(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                    fontSize: 8,
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

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Step 3: Stress & Anxiety - RESPONSIVE VERSION
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
                    'Stress & Anxiety\nLevels Today',
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
                    'How stressed and anxious are you feeling?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stress Level Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Stress Level (1-10)',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stress Levels Grid (reduced to fit better)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallHeight ? 3 : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: isSmallHeight ? 1.6 : 2.0,
                    ),
                    itemCount: _stressLevels.length,
                    itemBuilder: (context, index) {
                      final stress = _stressLevels[index];
                      final isSelected = _selectedStress == stress['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStress = stress['name'];
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSmallHeight ? 6 : 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: [
                                stress['color'].withValues(alpha: 0.2),
                                stress['color'].withValues(alpha: 0.1),
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
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? stress['color']
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stress['icon'],
                                style: TextStyle(fontSize: isSmallHeight ? 16 : 20),
                              ),
                              SizedBox(height: isSmallHeight ? 2 : 4),
                              Text(
                                stress['name'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: isSmallHeight ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Anxiety Slider
                  _buildAnxietySlider(isDark, isSmallHeight),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnxietySlider(bool isDark, bool isSmall) {
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
            'Anxiety Level',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate your anxiety on a scale of 1-10',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          SizedBox(height: isSmall ? 16 : 20),

          // Anxiety Value Display
          Center(
            child: Container(
              width: isSmall ? 60 : 70,
              height: isSmall ? 60 : 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCurrentMentalColor(),
                    _getCurrentMentalColor().withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getCurrentMentalColor().withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_selectedAnxiety',
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
              activeTrackColor: _getCurrentMentalColor(),
              inactiveTrackColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
              thumbColor: _getCurrentMentalColor(),
              overlayColor: _getCurrentMentalColor().withValues(alpha: 0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmall ? 10 : 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: isSmall ? 20 : 24),
            ),
            child: Slider(
              value: _selectedAnxiety.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _selectedAnxiety = value.round();
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
                'No Anxiety',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                'Severe Anxiety',
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

  // Step 4: Triggers & Coping - RESPONSIVE VERSION
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
                            const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.psychology,
                          size: 50,
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Triggers & Coping\nMechanisms',
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
                    'What triggered your feelings and how did you cope?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Fields
                  _buildModernTextField(
                    controller: _triggersController,
                    label: 'Triggers (Optional)',
                    hint: 'What caused stress or anxiety today?',
                    isDark: isDark,
                    maxLines: isSmallHeight ? 3 : 4,
                    prefixIcon: Icons.warning_outlined,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: _copingController,
                    label: 'Coping Mechanisms (Optional)',
                    hint: 'How did you manage or cope with stress?',
                    isDark: isDark,
                    maxLines: isSmallHeight ? 3 : 4,
                    prefixIcon: Icons.self_improvement_outlined,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: _thoughtsController,
                    label: 'Additional Thoughts (Optional)',
                    hint: 'Any other thoughts or reflections...',
                    isDark: isDark,
                    maxLines: isSmallHeight ? 3 : 4,
                    prefixIcon: Icons.lightbulb_outline,
                  ),

                  const SizedBox(height: 16),

                  // Coping Suggestions
                  _buildCopingSuggestions(isDark),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCopingSuggestions(bool isDark) {
    final suggestions = ['Deep breathing', 'Meditation', 'Exercise', 'Music', 'Journaling', 'Talk to someone'];

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
            'Common coping strategies',
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
            children: suggestions.map((suggestion) => GestureDetector(
              onTap: () {
                final currentText = _copingController.text;
                if (currentText.isEmpty) {
                  _copingController.text = suggestion;
                } else if (!currentText.contains(suggestion)) {
                  _copingController.text = '$currentText, $suggestion';
                }
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentMentalColor().withValues(alpha: 0.1),
                      _getCurrentMentalColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentMentalColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  suggestion,
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

  // Step 5: Custom Fields - RESPONSIVE VERSION (Same as weight tracker)
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
                    'Add any custom mental health metrics',
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
          'Add metrics like sleep quality,\nenergy level, or medication',
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
                          hint: 'e.g., Sleep Quality',
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
                    hint: 'e.g., Good',
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
                    'Review Mental Wellbeing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: isSmallHeight ? 20 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check your mental health data before saving',
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
                          if (_selectedMood != null)
                            _buildReviewCard('Current Mood', _selectedMood!, Icons.sentiment_satisfied, _getCurrentMentalColor(), isDark),

                          if (_selectedWellbeing != null)
                            _buildReviewCard('Wellbeing Level', _selectedWellbeing!, Icons.favorite, Colors.green, isDark),

                          if (_selectedStress != null)
                            _buildReviewCard('Stress Level', _selectedStress!, Icons.psychology, Colors.orange, isDark),

                          _buildReviewCard('Anxiety Level', '$_selectedAnxiety/10', Icons.warning, Colors.red, isDark),

                          if (_triggersController.text.isNotEmpty)
                            _buildReviewCard('Triggers', _triggersController.text, Icons.warning_outlined, Colors.amber, isDark),

                          if (_copingController.text.isNotEmpty)
                            _buildReviewCard('Coping Mechanisms', _copingController.text, Icons.self_improvement, Colors.blue, isDark),

                          if (_thoughtsController.text.isNotEmpty)
                            _buildReviewCard('Thoughts', _thoughtsController.text, Icons.lightbulb, Colors.purple, isDark),

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
                                    'Saving Entry...',
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
                                    _getCurrentMentalEmoji(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Mental Health Entry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCurrentMentalColor(),
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
                  backgroundColor: _getCurrentMentalColor(),
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
}
