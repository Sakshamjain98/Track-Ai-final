import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

// Enhanced Menstrual Tracker Screen
class MenstrualTrackerScreen extends StatefulWidget {
  const MenstrualTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MenstrualTrackerScreen> createState() => _MenstrualTrackerScreenState();
}

class _MenstrualTrackerScreenState extends State<MenstrualTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _flowController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  DateTime? _selectedDate;
  String? _selectedFlow;
  List<String> _selectedSymptoms = [];
  String? _selectedMood;

  // Enhanced flow levels with colors and descriptions
  final List<Map<String, dynamic>> _flowLevels = [
    {'name': 'Light', 'description': 'Spotting or light bleeding', 'color': Color(0xFFFFB3BA), 'icon': Icons.water_drop_outlined},
    {'name': 'Normal', 'description': 'Regular flow', 'color': Color(0xFFFF6B6B), 'icon': Icons.water_drop},
    {'name': 'Heavy', 'description': 'Heavy bleeding', 'color': Color(0xFFE53935), 'icon': Icons.opacity},
    {'name': 'Very Heavy', 'description': 'Extremely heavy flow', 'color': Color(0xFFB71C1C), 'icon': Icons.invert_colors},
  ];

  // Enhanced symptoms with icons and colors
  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Cramps', 'icon': Icons.flash_on, 'color': Color(0xFFFF5722)},
    {'name': 'Headache', 'icon': Icons.psychology_alt, 'color': Color(0xFF9C27B0)},
    {'name': 'Bloating', 'icon': Icons.circle, 'color': Color(0xFF2196F3)},
    {'name': 'Fatigue', 'icon': Icons.battery_0_bar, 'color': Color(0xFF607D8B)},
    {'name': 'Mood Swings', 'icon': Icons.mood, 'color': Color(0xFFFF9800)},
    {'name': 'Breast Tenderness', 'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {'name': 'Back Pain', 'icon': Icons.accessibility_new, 'color': Color(0xFF795548)},
    {'name': 'Nausea', 'icon': Icons.sick, 'color': Color(0xFF4CAF50)},
  ];

  // Enhanced moods with colors and emojis
  final List<Map<String, dynamic>> _moods = [
    {'name': 'Happy', 'emoji': '😊', 'color': Color(0xFFFFD700)},
    {'name': 'Sad', 'emoji': '😢', 'color': Color(0xFF2196F3)},
    {'name': 'Anxious', 'emoji': '😰', 'color': Color(0xFFFF9800)},
    {'name': 'Irritable', 'emoji': '😠', 'color': Color(0xFFE53935)},
    {'name': 'Calm', 'emoji': '😌', 'color': Color(0xFF4CAF50)},
    {'name': 'Energetic', 'emoji': '⚡', 'color': Color(0xFFFF6B6B)},
    {'name': 'Tired', 'emoji': '😴', 'color': Color(0xFF9E9E9E)},
    {'name': 'Normal', 'emoji': '🙂', 'color': Color(0xFF607D8B)},
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

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

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

    _waveAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _selectedDate = DateTime.now();
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
    _waveController.dispose();
    _flowController.dispose();
    _notesController.dispose();

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
        'date': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'flow': _selectedFlow ?? '',
        'symptoms': _selectedSymptoms,
        'mood': _selectedMood ?? '',
        'notes': _notesController.text.trim(),
        'customData': customData,
        'trackerType': 'menstrual',
      };

      await TrackerService.saveTrackerEntry('menstrual', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Menstrual entry saved successfully! 🩸'),
              ],
            ),
            backgroundColor: _getCurrentMenstrualColor(),
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

  Color _getCurrentMenstrualColor() {
    if (_selectedFlow != null) {
      final flow = _flowLevels.firstWhere(
            (f) => f['name'] == _selectedFlow,
        orElse: () => _flowLevels[1],
      );
      return flow['color'];
    }
    return const Color(0xFFFF6B6B);
  }

  IconData _getCurrentMenstrualIcon() {
    if (_selectedFlow != null) {
      final flow = _flowLevels.firstWhere(
            (f) => f['name'] == _selectedFlow,
        orElse: () => _flowLevels[1],
      );
      return flow['icon'];
    }
    return Icons.water_drop;
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
                      height: 140,
                      child: _buildEnhancedProgressHeader(isDark),
                    ),

                    // Page View with proper constraints
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(isDark), // Date Selection
                          _buildStep2(isDark), // Flow Level
                          _buildStep3(isDark), // Symptoms
                          _buildStep4(isDark), // Mood
                          _buildStep5(isDark), // Custom Fields & Notes
                          _buildStep6(isDark), // Review & Save
                        ],
                      ),
                    ),

                    // Enhanced Navigation Buttons - Fixed height
                    SizedBox(
                      height: 120,
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
        mainAxisSize: MainAxisSize.min,
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
                            _getCurrentMenstrualColor(),
                            _getCurrentMenstrualColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCurrentMenstrualIcon(),
                          color: Colors.white,
                          size: 18,
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
                            'Period Tracker',
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

              // **🔧 FIXED PROGRESS CIRCLE - PROPERLY CENTERED**
              Container(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center, // ✅ This centers everything
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
                    // Progress Circle - ✅ Properly sized and centered
                    SizedBox(
                      width: 46, // ✅ Slightly smaller than container
                      height: 46,
                      child: CircularProgressIndicator(
                        value: (_currentStep + 1) / _totalSteps,
                        strokeWidth: 3,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCurrentMenstrualColor(),
                        ),
                      ),
                    ),
                    // Center Text - ✅ Perfectly centered
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
                  _getCurrentMenstrualColor(),
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
      case 0: return 'Date';
      case 1: return 'Flow Level';
      case 2: return 'Symptoms';
      case 3: return 'Mood';
      case 4: return 'Notes & Custom';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Date Selection
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📅 Period Date',
          subtitle: 'When did your period start?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Calendar Icon
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _waveAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                              const Color(0xFFFFB3BA).withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFF6B6B),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.calendar_today,
                            size: 50,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
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
                      Text(
                        'Selected Date',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B6B),
                                const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick date options
                _buildQuickDateOptions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateOptions(bool isDark) {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final twoDaysAgo = today.subtract(Duration(days: 2));

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
            'Quick options:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = today;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = yesterday;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Yesterday',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = twoDaysAgo;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '2 Days Ago',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 7)),
      helpText: 'Select period start date',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF6B6B),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      HapticFeedback.selectionClick();
    }
  }

  // Step 2: Flow Level
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🩸 Flow Level',
          subtitle: 'How heavy is your flow today?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Flow Level Cards
                ..._flowLevels.map((flow) {
                  final isSelected = _selectedFlow == flow['name'];

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFlow = flow['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              flow['color'].withValues(alpha: 0.2),
                              flow['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? flow['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? flow['color']
                                    : flow['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                flow['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flow['name'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    flow['description'],
                                    style: TextStyle(
                                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: flow['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 3: Symptoms
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🤕 Symptoms',
          subtitle: 'What symptoms are you experiencing?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Text(
                  'Select all that apply (optional):',
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 16),

                // Symptoms Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = _symptoms[index];
                    final isSelected = _selectedSymptoms.contains(symptom['name']);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSymptoms.remove(symptom['name']);
                          } else {
                            _selectedSymptoms.add(symptom['name']);
                          }
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              symptom['color'].withValues(alpha: 0.2),
                              symptom['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? symptom['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? symptom['color']
                                    : symptom['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                symptom['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              symptom['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: symptom['color'],
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                if (_selectedSymptoms.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected symptoms:',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedSymptoms.join(', '),
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                            fontSize: 11,
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

  // Step 4: Mood
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '😊 Your Mood',
          subtitle: 'How are you feeling today?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Mood Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _moods.length,
                  itemBuilder: (context, index) {
                    final mood = _moods[index];
                    final isSelected = _selectedMood == mood['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMood = mood['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              mood['color'].withValues(alpha: 0.2),
                              mood['color'].withValues(alpha: 0.1),
                            ],
                          )
                              : LinearGradient(
                            colors: [
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? mood['color']
                                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood['emoji'],
                              style: TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

                const SizedBox(height: 20),

                if (_selectedMood != null)
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
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _moods.firstWhere((m) => m['name'] == _selectedMood)['emoji'],
                          style: TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'re feeling $_selectedMood',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mood tracking helps identify patterns in your cycle',
                                style: TextStyle(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
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

  // Step 5: Notes & Custom Fields
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📝 Additional Notes',
          subtitle: 'Any other details you\'d like to track?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Notes Field
                _buildEnhancedTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  hint: 'Add any notes about today...',
                  isDark: isDark,
                  maxLines: 4,
                  prefixIcon: Icons.note_add,
                  helpText: 'Track sleep, exercise, diet, or any other details',
                ),

                const SizedBox(height: 20),

                // Custom Fields Section
                if (_customFields.isEmpty)
                  _buildEmptyCustomFields(isDark)
                else
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
                                  hint: 'e.g., Sleep Hours',
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
                            hint: 'e.g., 8 hours',
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
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
              size: 30,
              color: const Color(0xFF00BCD4),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'No custom fields yet',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Add custom metrics like sleep hours,\nexercise, or medication',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(width: 16),

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
        icon: Icon(Icons.add, color: Colors.white, size: 16),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // Step 6: Review & Save
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Entry',
          subtitle: 'Confirm your period data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Date', _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Not selected', Icons.calendar_today, _getCurrentMenstrualColor(), isDark),

                if (_selectedFlow != null)
                  _buildReviewCard('Flow Level', _selectedFlow!, _getCurrentMenstrualIcon(), _getCurrentMenstrualColor(), isDark),

                if (_selectedSymptoms.isNotEmpty)
                  _buildReviewCard('Symptoms', _selectedSymptoms.join(', '), Icons.healing, Colors.orange, isDark),

                if (_selectedMood != null)
                  _buildReviewCard('Mood', _selectedMood!, Icons.mood, Colors.purple, isDark),

                if (_notesController.text.isNotEmpty)
                  _buildReviewCard('Notes', _notesController.text, Icons.note, Colors.blue, isDark),

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
                        _getCurrentMenstrualColor(),
                        _getCurrentMenstrualColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentMenstrualColor().withValues(alpha: 0.4),
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
                            Icon(
                              _getCurrentMenstrualIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Period Entry',
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

  // Helper methods (same structure as other trackers)
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
                      _getCurrentMenstrualColor(),
                      _getCurrentMenstrualColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentMenstrualColor().withValues(alpha: 0.3),
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
