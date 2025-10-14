import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

// Enhanced Alcohol Tracker Screen with Premium Multi-Step UI
class AlcoholTrackerScreen extends StatefulWidget {
  const AlcoholTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AlcoholTrackerScreen> createState() => _AlcoholTrackerScreenState();
}

class _AlcoholTrackerScreenState extends State<AlcoholTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers
  final _valueController = TextEditingController();
  final _occasionController = TextEditingController();
  final _locationController = TextEditingController();
  final _reasonController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  int _selectedCraving = 3;
  String? _selectedDrinkType;
  String? _selectedSituation;

  // Enhanced drink types with icons and colors
  final List<Map<String, dynamic>> _drinkTypes = [
    {'name': 'Beer', 'icon': Icons.sports_bar, 'color': Color(0xFFFFB74D), 'description': 'Light & refreshing'},
    {'name': 'Wine', 'icon': Icons.wine_bar, 'color': Color(0xFF8E24AA), 'description': 'Elegant & sophisticated'},
    {'name': 'Whiskey', 'icon': Icons.local_bar, 'color': Color(0xFF6D4C41), 'description': 'Strong & smooth'},
    {'name': 'Vodka', 'icon': Icons.liquor, 'color': Color(0xFF42A5F5), 'description': 'Clean & crisp'},
    {'name': 'Rum', 'icon': Icons.emoji_food_beverage, 'color': Color(0xFFD4AF37), 'description': 'Sweet & tropical'},
    {'name': 'Cocktail', 'icon': Icons.local_drink, 'color': Color(0xFFEC407A), 'description': 'Mixed & fruity'},
    {'name': 'Champagne', 'icon': Icons.celebration, 'color': Color(0xFFFFD700), 'description': 'Celebration drink'},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF78909C), 'description': 'Other beverages'},
  ];

  // Enhanced situations with icons and colors
  final List<Map<String, dynamic>> _situations = [
    {'name': 'Social Gathering', 'icon': Icons.group, 'color': Color(0xFF4CAF50), 'description': 'With friends & family'},
    {'name': 'Dinner', 'icon': Icons.restaurant, 'color': Color(0xFFFF9800), 'description': 'During meals'},
    {'name': 'Celebration', 'icon': Icons.celebration, 'color': Color(0xFFE91E63), 'description': 'Special occasions'},
    {'name': 'Relaxation', 'icon': Icons.self_improvement, 'color': Color(0xFF9C27B0), 'description': 'To unwind'},
    {'name': 'Work Event', 'icon': Icons.work, 'color': Color(0xFF3F51B5), 'description': 'Business occasions'},
    {'name': 'Date', 'icon': Icons.favorite, 'color': Color(0xFFF44336), 'description': 'Romantic setting'},
    {'name': 'Alone', 'icon': Icons.person, 'color': Color(0xFF607D8B), 'description': 'Solo drinking'},
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

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
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
    _rotateController.dispose();
    _valueController.dispose();
    _occasionController.dispose();
    _locationController.dispose();
    _reasonController.dispose();

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
        'value': double.tryParse(_valueController.text) ?? 0.0,
        'drinkType': _selectedDrinkType ?? '',
        'situation': _selectedSituation ?? '',
        'location': _locationController.text.trim(),
        'reason': _reasonController.text.trim(),
        'occasion': _occasionController.text.trim(),
        'craving': _selectedCraving,
        'customData': customData,
        'trackerType': 'alcohol',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await TrackerService.saveTrackerEntry('alcohol', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Alcohol entry saved successfully! 🍻'),
              ],
            ),
            backgroundColor: _getCurrentAlcoholColor(),
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

  Color _getCurrentAlcoholColor() {
    if (_selectedDrinkType != null) {
      final type = _drinkTypes.firstWhere(
            (t) => t['name'] == _selectedDrinkType,
        orElse: () => _drinkTypes[0],
      );
      return type['color'];
    }
    return const Color(0xFFFFB74D);
  }

  IconData _getCurrentAlcoholIcon() {
    if (_selectedDrinkType != null) {
      final type = _drinkTypes.firstWhere(
            (t) => t['name'] == _selectedDrinkType,
        orElse: () => _drinkTypes[0],
      );
      return type['icon'];
    }
    return Icons.local_bar;
  }

  Color _getCurrentSituationColor() {
    if (_selectedSituation != null) {
      final situation = _situations.firstWhere(
            (s) => s['name'] == _selectedSituation,
        orElse: () => _situations[0],
      );
      return situation['color'];
    }
    return const Color(0xFF4CAF50);
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
                          _buildStep1(isDark), // Amount
                          _buildStep2(isDark), // Drink Type
                          _buildStep3(isDark), // Situation
                          _buildStep4(isDark), // Location & Reason
                          _buildStep5(isDark), // Custom Fields
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
                            _getCurrentAlcoholColor(),
                            _getCurrentAlcoholColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getCurrentAlcoholIcon(),
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
                            'Alcohol Tracker',
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
                          _getCurrentAlcoholColor(),
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
                  _getCurrentAlcoholColor(),
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
      case 0: return 'Amount';
      case 1: return 'Drink Type';
      case 2: return 'Situation';
      case 3: return 'Details';
      case 4: return 'Custom Fields';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Amount
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🍻 Alcohol Amount',
          subtitle: 'How many drinks did you have?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Animated Alcohol Icon
                AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value * 0.1,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFB74D).withValues(alpha: 0.3),
                              const Color(0xFFFFE082).withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_bar,
                            size: 50,
                            color: const Color(0xFFFFB74D),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _valueController,
                  label: 'Number of Drinks',
                  hint: '1, 2, 3...',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.local_bar,
                  helpText: 'Enter the total number of drinks consumed',
                ),

                const SizedBox(height: 20),

                // Drink Count Suggestions
                _buildDrinkSuggestions(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrinkSuggestions(bool isDark) {
    final suggestions = [1, 2, 3, 4, 5, 6];

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
            'Quick counts:',
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((count) => GestureDetector(
              onTap: () {
                _valueController.text = count.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Step 2: Type
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🥃 Alcohol Type',
          subtitle: 'What type of alcohol did you drink?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Alcohol Types Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _drinkTypes.length,
                  itemBuilder: (context, index) {
                    final type = _drinkTypes[index];
                    final isSelected = _selectedDrinkType == type['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDrinkType = type['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? type['color']
                                    : type['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                type['icon'],
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'],
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 3: Situation
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '👥 Drinking Situation',
          subtitle: 'What was the occasion or setting?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Situations List
                ...(_situations.map((situation) {
                  final isSelected = _selectedSituation == situation['name'];

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSituation = situation['name'];
                        });
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            colors: [
                              situation['color'].withValues(alpha: 0.2),
                              situation['color'].withValues(alpha: 0.1),
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
                                ? situation['color']
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
                                    ? situation['color']
                                    : situation['color'].withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                situation['icon'],
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
                                    situation['name'],
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    situation['description'],
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
                                  color: situation['color'],
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
                })),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 4: Location & Reason
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '📍 Additional Details',
          subtitle: 'Where and why did you drink?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildEnhancedTextField(
                  controller: _locationController,
                  label: 'Location (Optional)',
                  hint: 'Where did you drink? e.g., Home, Restaurant, Bar...',
                  isDark: isDark,
                  prefixIcon: Icons.location_on,
                  helpText: 'The place where you consumed alcohol',
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _reasonController,
                  label: 'Reason (Optional)',
                  hint: 'Why did you drink? e.g., Celebrating, Relaxing...',
                  isDark: isDark,
                  maxLines: 3,
                  prefixIcon: Icons.psychology,
                  helpText: 'Your motivation or reason for drinking',
                ),

                const SizedBox(height: 20),

                _buildEnhancedTextField(
                  controller: _occasionController,
                  label: 'Occasion (Optional)',
                  hint: 'What was the occasion? e.g., Birthday, Dinner...',
                  isDark: isDark,
                  maxLines: 2,
                  prefixIcon: Icons.event,
                  helpText: 'Special occasion or event details',
                ),

                const SizedBox(height: 20),

                _buildCravingScale(isDark),

                const SizedBox(height: 20),

                // Quick location suggestions
                _buildLocationSuggestions(isDark),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSuggestions(bool isDark) {
    final locations = ['Home', 'Restaurant', 'Bar', 'Club', 'Friend\'s House', 'Outdoor Event'];

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
            'Common locations:',
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
            children: locations.map((location) => GestureDetector(
              onTap: () {
                _locationController.text = location;
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  location,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCravingScale(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Craving Level (1-5)',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your alcohol craving',
                style: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final number = index + 1;
                  final isSelected = number == _selectedCraving;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCraving = number;
                      });
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? _getCurrentAlcoholColor() : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _getCurrentAlcoholColor() : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Low',
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'High',
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 5: Custom Fields
  Widget _buildStep5(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🔧 Custom Data',
          subtitle: 'Add personalized alcohol tracking',
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
                                hint: 'e.g., Brand Name',
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
                          hint: 'e.g., Heineken',
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
            'Add custom metrics like brand name,\nalcohol percentage, or price',
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

  // Step 6: Review & Save
  Widget _buildStep6(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '✅ Review Your Entry',
          subtitle: 'Confirm your alcohol tracking data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Drinks Count', '${_valueController.text} drinks', Icons.local_bar, _getCurrentAlcoholColor(), isDark),

                if (_selectedDrinkType != null)
                  _buildReviewCard('Alcohol Type', _selectedDrinkType!, _getCurrentAlcoholIcon(), _getCurrentAlcoholColor(), isDark),

                if (_selectedSituation != null)
                  _buildReviewCard('Situation', _selectedSituation!, Icons.group, _getCurrentSituationColor(), isDark),

                if (_locationController.text.isNotEmpty)
                  _buildReviewCard('Location', _locationController.text, Icons.location_on, Colors.blue, isDark),

                if (_reasonController.text.isNotEmpty)
                  _buildReviewCard('Reason', _reasonController.text, Icons.psychology, Colors.purple, isDark),

                if (_occasionController.text.isNotEmpty)
                  _buildReviewCard('Occasion', _occasionController.text, Icons.event, Colors.orange, isDark),

                _buildReviewCard('Craving Level', '$_selectedCraving/5', Icons.favorite, Colors.red, isDark),

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
                        _getCurrentAlcoholColor(),
                        _getCurrentAlcoholColor().withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getCurrentAlcoholColor().withValues(alpha: 0.4),
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
                              _getCurrentAlcoholIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save Alcohol Entry',
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

  // Helper methods
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
                      _getCurrentAlcoholColor(),
                      _getCurrentAlcoholColor().withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentAlcoholColor().withValues(alpha: 0.3),
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
