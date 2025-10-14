import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
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

  // Controllers for each field
  final _emotionsController = TextEditingController();
  final _contextController = TextEditingController();
  final _peakTimeController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  int _selectedMood = 5;

  // Mood data with emojis and descriptions
  final List<Map<String, dynamic>> _moodData = [
    {'value': 1, 'emoji': '😭', 'label': 'Terrible', 'color': Color(0xFFE57373)},
    {'value': 2, 'emoji': '😢', 'label': 'Very Bad', 'color': Color(0xFFEF5350)},
    {'value': 3, 'emoji': '😔', 'label': 'Bad', 'color': Color(0xFFFF7043)},
    {'value': 4, 'emoji': '😕', 'label': 'Poor', 'color': Color(0xFFFFB74D)},
    {'value': 5, 'emoji': '😐', 'label': 'Okay', 'color': Color(0xFFFD9035)},
    {'value': 6, 'emoji': '🙂', 'label': 'Fair', 'color': Color(0xFFAED581)},
    {'value': 7, 'emoji': '😊', 'label': 'Good', 'color': Color(0xFF81C784)},
    {'value': 8, 'emoji': '😄', 'label': 'Great', 'color': Color(0xFF66BB6A)},
    {'value': 9, 'emoji': '😍', 'label': 'Amazing', 'color': Color(0xFF4CAF50)},
    {'value': 10, 'emoji': '🤩', 'label': 'Fantastic', 'color': Color(0xFF2E7D32)},
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
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
    _emotionsController.dispose();
    _contextController.dispose();
    _peakTimeController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
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
        duration: const Duration(milliseconds: 400),
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
        'value': _selectedMood,
        'emotions': _emotionsController.text.trim(),
        'context': _contextController.text.trim(),
        'peakMoodTime': _peakTimeController.text.trim(),
        'customData': customData,
        'trackerType': 'mood',
      };

      await TrackerService.saveTrackerEntry('mood', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Mood entry saved successfully! 😊'),
              ],
            ),
            backgroundColor: _getCurrentMoodColor(),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error saving entry: $e')),
              ],
            ),
            backgroundColor: Colors.red,
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

  Color _getCurrentMoodColor() {
    return _moodData.firstWhere((mood) => mood['value'] == _selectedMood)['color'];
  }

  String _getCurrentMoodEmoji() {
    return _moodData.firstWhere((mood) => mood['value'] == _selectedMood)['emoji'];
  }

  String _getCurrentMoodLabel() {
    return _moodData.firstWhere((mood) => mood['value'] == _selectedMood)['label'];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: _getGradientBackground(isDark),
          body: Container(
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(isDark),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced Progress Header - Fixed height
                    SizedBox(
                      height: 140, // Fixed height to prevent overflow
                      child: _buildEnhancedProgressHeader(isDark),
                    ),

                    // Page View with proper constraints
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Mood Scale
                          _buildStep2(isDark), // Emotions
                          _buildStep3(isDark), // Context
                          _buildStep4(isDark), // Peak Time
                          _buildStep5(isDark), // Custom Fields
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Enhanced Navigation Buttons - Fixed height
                    SizedBox(
                      height: 120, // Fixed height for navigation
                      child: _buildEnhancedNavigationButtons(isDark),
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

  Color _getGradientBackground(bool isDark) {
    return isDark
        ? const Color(0xFF0A0A0F)
        : const Color(0xFFF8FAFF);
  }

  Gradient _getBackgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
        const Color(0xFF0A0A0F),
        const Color(0xFF1A1A2E),
        const Color(0xFF16213E),
      ]
          : [
        const Color(0xFFF8FAFF),
        const Color(0xFFE8F4FD),
        const Color(0xFFDDF4FF),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildEnhancedProgressHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          // Header Row
          Row(
            children: [
              // Back Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : Colors.black,
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title Section
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCurrentMoodColor(),
                            _getCurrentMoodColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _getCurrentMoodEmoji(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mood Tracker',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_getStepTitle(_currentStep)}',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed Progress Circle - Properly Centered
              Container(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center, // This centers everything
                  children: [
                    // Background Circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    // Progress Circle - Properly sized and centered
                    SizedBox(
                      width: 46, // Slightly smaller than container
                      height: 46,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCurrentMoodColor(),
                        ),
                      ),
                    ),
                    // Center Text - Perfectly centered
                    Container(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: Text(
                          '${_currentStep + 1}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enhanced Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCurrentMoodColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Mood Scale';
      case 1: return 'Emotions';
      case 2: return 'Context';
      case 3: return 'Peak Time';
      case 4: return 'Custom Data';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Mood Scale
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '😊 How are you feeling?',
          subtitle: 'Select your current mood on a scale of 1-10',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Current Mood Display - Reduced size
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _getCurrentMoodColor().withValues(alpha: 0.3),
                              _getCurrentMoodColor().withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: _getCurrentMoodColor(),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getCurrentMoodEmoji(),
                                style: TextStyle(fontSize: 40),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getCurrentMoodLabel(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Mood Scale Slider
                Text(
                  'Slide to select your mood',
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                        const Color(0xFF16213E).withValues(alpha: 0.4),
                      ],
                    )
                        : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        const Color(0xFFF8FAFF).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Slider(
                        value: _selectedMood.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: _getCurrentMoodColor(),
                        inactiveColor: _getCurrentMoodColor().withValues(alpha: 0.3),
                        onChanged: (value) {
                          setState(() {
                            _selectedMood = value.round();
                          });
                          HapticFeedback.selectionClick();
                        },
                      ),

                      const SizedBox(height: 10),

                      // Mood Scale Visual - Reduced size
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _moodData.length,
                          itemBuilder: (context, index) {
                            final mood = _moodData[index];
                            final isSelected = mood['value'] == _selectedMood;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMood = mood['value'];
                                });
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                width: 35,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? mood['color']
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? mood['color']
                                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mood['emoji'],
                                          style: TextStyle(fontSize: isSelected ? 16 : 14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${mood['value']}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? (isDark ? Colors.white : Colors.black)
                                            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 2: Emotions - Fixed
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💭 Describe Your Emotions',
          subtitle: 'What specific emotions are you experiencing?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentMoodColor().withValues(alpha: 0.3),
                        _getCurrentMoodColor().withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 40,
                    color: _getCurrentMoodColor(),
                  ),
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _emotionsController,
                  label: 'Emotions',
                  hint: 'e.g., happy, anxious, excited...',
                  isDark: isDark,
                  maxLines: 2,
                  autofocus: true,
                  prefixIcon: Icons.favorite,
                  helpText: 'Be specific about what you\'re feeling',
                ),

                const SizedBox(height: 15),

                // Emotion Suggestions - Compact
                _buildEmotionSuggestions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionSuggestions(bool isDark) {
    final suggestions = [
      'Happy', 'Sad', 'Anxious', 'Excited', 'Calm', 'Stressed',
      'Confident', 'Overwhelmed', 'Grateful', 'Frustrated'
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick suggestions:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggestions.map((emotion) => GestureDetector(
              onTap: () {
                final current = _emotionsController.text;
                if (current.isEmpty) {
                  _emotionsController.text = emotion;
                } else {
                  _emotionsController.text = '$current, $emotion';
                }
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCurrentMoodColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getCurrentMoodColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  emotion,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 3: Context - Fixed
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🌍 What\'s the Context?',
          subtitle: 'What was happening when you felt this way?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF42A5F5).withValues(alpha: 0.2),
                        const Color(0xFF1E88E5).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 40,
                    color: const Color(0xFF42A5F5),
                  ),
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _contextController,
                  label: 'Context',
                  hint: 'e.g., at work during meeting...',
                  isDark: isDark,
                  maxLines: 3,
                  autofocus: true,
                  prefixIcon: Icons.place,
                  helpText: 'Describe the situation or place',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 4: Peak Time - Fixed
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '⏰ Peak Mood Time',
          subtitle: 'When did you feel your best today?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF7043).withValues(alpha: 0.2),
                        const Color(0xFFFF5722).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    size: 40,
                    color: const Color(0xFFFF7043),
                  ),
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _peakTimeController,
                  label: 'Peak Mood Time',
                  hint: 'e.g., morning coffee, evening walk...',
                  isDark: isDark,
                  maxLines: 2,
                  autofocus: true,
                  prefixIcon: Icons.access_time,
                  helpText: 'When did you feel most positive?',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 5: Custom Fields - Fixed layout
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🔧 Custom Data',
          subtitle: 'Add personalized mood metrics',
          child: _customFields.isEmpty
              ? _buildEmptyCustomFields(isDark)
              : SingleChildScrollView(
            child: Column(
              children: [
                // Custom Fields List
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
                          const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                          const Color(0xFF16213E).withValues(alpha: 0.4),
                        ],
                      )
                          : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          const Color(0xFFF8FAFF).withValues(alpha: 0.6),
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
                              child: _buildCompactTextField(
                                controller: field['key']!,
                                label: 'Field Name',
                                hint: 'e.g., Trigger',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _removeCustomField(index),
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCompactTextField(
                          controller: field['value']!,
                          label: 'Field Value',
                          hint: 'e.g., Traffic jam',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildAddCustomFieldButton(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  const Color(0xFF009688).withValues(alpha: 0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 40,
              color: const Color(0xFF00BCD4),
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
            'Add custom metrics like triggers or\nactivity level',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _buildAddCustomFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  // Step 6: Review & Save - Fixed with proper scrolling
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Mood',
          subtitle: 'Confirm your mood data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Mood Scale', '$_selectedMood/10 (${_getCurrentMoodLabel()})', Icons.sentiment_satisfied, _getCurrentMoodColor(), isDark),

                if (_emotionsController.text.isNotEmpty)
                  _buildReviewCard('Emotions', _emotionsController.text, Icons.favorite, Colors.pink, isDark),

                if (_contextController.text.isNotEmpty)
                  _buildReviewCard('Context', _contextController.text, Icons.location_on, Colors.blue, isDark),

                if (_peakTimeController.text.isNotEmpty)
                  _buildReviewCard('Peak Time', _peakTimeController.text, Icons.schedule, Colors.orange, isDark),

                // Custom Fields Review
                if (_customFields.isNotEmpty) ...[
                  ..._customFields.map((field) {
                    final key = field['key']?.text ?? '';
                    final value = field['value']?.text ?? '';
                    if (key.isNotEmpty && value.isNotEmpty) {
                      return _buildReviewCard(key, value, Icons.settings, Colors.teal, isDark);
                    }
                    return const SizedBox.shrink();
                  }),
                ],

                const SizedBox(height: 24),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getCurrentMoodColor(),
                        _getCurrentMoodColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentMoodColor().withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveEntry,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
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
                            const SizedBox(width: 8),
                            Text(
                              'Saving...',
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
                              _getCurrentMoodEmoji(),
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Mood Entry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
            const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            const Color(0xFF16213E).withValues(alpha: 0.4),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF8FAFF).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
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

  Widget _buildStepContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Content - Use Expanded to prevent overflow
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    IconData? prefixIcon,
    String? helpText,
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
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
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
            autofocus: autofocus,
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
                size: 18,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 6),
          Text(
            helpText,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                const Color(0xFF16213E).withValues(alpha: 0.4),
              ],
            )
                : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFF8FAFF).withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                fontSize: 12,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.9),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF8FAFF).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _previousStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : Colors.black,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
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
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Next Button
          if (_currentStep < _totalSteps - 1)
            Expanded(
              flex: 2,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentMoodColor(),
                      _getCurrentMoodColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentMoodColor().withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _nextStep,
                    borderRadius: BorderRadius.circular(10),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next Step',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
