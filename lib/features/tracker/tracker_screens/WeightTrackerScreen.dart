import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({Key? key}) : super(key: key);

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen>
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
  final int _totalSteps = 5;

  // Controllers
  final _valueController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _feelingController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

  // Weight-specific fields
  String _selectedUnit = 'kg';
  TimeOfDay? _selectedTime;
  String? _selectedFeeling;

  final List<String> _units = ['kg', 'lbs'];

  final List<Map<String, dynamic>> _feelingTypes = [
    {'name': 'Energetic', 'icon': '⚡', 'color': Color(0xFF10B981), 'description': 'Full of energy & vitality'},
    {'name': 'Strong', 'icon': '💪', 'color': Color(0xFF3B82F6), 'description': 'Feeling physically strong'},
    {'name': 'Light', 'icon': '🪶', 'color': Color(0xFF8B5CF6), 'description': 'Feeling light & comfortable'},
    {'name': 'Normal', 'icon': '😌', 'color': Color(0xFF6B7280), 'description': 'Average feeling today'},
    {'name': 'Heavy', 'icon': '🏋️', 'color': Color(0xFFEF4444), 'description': 'Feeling heavy or sluggish'},
    {'name': 'Bloated', 'icon': '😵', 'color': Color(0xFFF59E0B), 'description': 'Bloated or uncomfortable'},
    {'name': 'Motivated', 'icon': '🔥', 'color': Color(0xFFDC2626), 'description': 'Motivated & determined'},
    {'name': 'Other', 'icon': '🤔', 'color': Color(0xFF78716C), 'description': 'Different feeling today'},
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
    _bodyFatController.dispose();
    _feelingController.dispose();

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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
        'unit': _selectedUnit,
        'bodyFat': _bodyFatController.text.trim(),
        'feeling': _selectedFeeling ?? _feelingController.text.trim(),
        'timeOfDay': _selectedTime != null ? _formatTime(_selectedTime!) : '',
        'customData': customData,
        'trackerType': 'weight',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await TrackerService.saveTrackerEntry('weight', entryData);

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
                Text('Weight logged successfully! ⚖️'),
              ],
            ),
            backgroundColor: _getCurrentWeightColor(),
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

  Color _getCurrentWeightColor() {
    if (_selectedFeeling != null) {
      final feeling = _feelingTypes.firstWhere(
            (f) => f['name'] == _selectedFeeling,
        orElse: () => _feelingTypes[3], // Default to Normal
      );
      return feeling['color'];
    }
    return const Color(0xFF6B7280);
  }

  String _getCurrentWeightEmoji() {
    if (_selectedFeeling != null) {
      final feeling = _feelingTypes.firstWhere(
            (f) => f['name'] == _selectedFeeling,
        orElse: () => _feelingTypes[3],
      );
      return feeling['icon'];
    }
    return '⚖️';
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
                          _buildStep1(isDark), // Weight Value & Unit
                          _buildStep2(isDark), // Body Fat & Feeling
                          _buildStep3(isDark), // Time & Additional Info
                          _buildStep4(isDark), // Custom Fields
                          _buildStep5(isDark), // Review & Save
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
                  'Weight Tracker',
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

          // Weight Icon - Fixed Size
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCurrentWeightColor(),
                  _getCurrentWeightColor().withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _getCurrentWeightColor().withValues(alpha: 0.3),
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
                      _getCurrentWeightEmoji(),
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
                          ? _getCurrentWeightColor()
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
                  color: _getCurrentWeightColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                  style: TextStyle(
                    color: _getCurrentWeightColor(),
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
      case 0: return 'Enter your weight';
      case 1: return 'Body metrics & feeling';
      case 2: return 'Time & additional info';
      case 3: return 'Custom metrics';
      case 4: return 'Review & save';
      default: return '';
    }
  }

  // Step 1: Weight Value & Unit - RESPONSIVE VERSION
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
                                    const Color(0xFF6B7280).withValues(alpha: 0.3),
                                    const Color(0xFF6B7280).withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '⚖️',
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
                      'What\'s your current\nweight today?',
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
                      'Enter your weight measurement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Weight Input with Unit Selector
                    _buildWeightInputField(isDark),

                    const SizedBox(height: 24),

                    // Weight Suggestions
                    _buildWeightSuggestions(isDark),

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

  Widget _buildWeightInputField(bool isDark) {
    return Container(
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCurrentWeightColor().withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getCurrentWeightColor().withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Weight Input
          Expanded(
            child: TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter weight',
                hintStyle: TextStyle(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                  fontSize: 18,
                ),
                prefixIcon: Icon(
                  Icons.monitor_weight_outlined,
                  color: _getCurrentWeightColor(),
                  size: 24,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),

          // Unit Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUnit,
                items: _units.map((unit) => DropdownMenuItem(
                  value: unit,
                  child: Text(
                    unit.toUpperCase(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                  HapticFeedback.selectionClick();
                },
                dropdownColor: isDark ? const Color(0xFF162544) : Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSuggestions(bool isDark) {
    // Generate common weights based on selected unit
    final suggestions = _selectedUnit == 'kg'
        ? [50, 55, 60, 65, 70, 75, 80, 85, 90, 95]
        : [110, 120, 130, 140, 150, 160, 170, 180, 190, 200];

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
            'Common weights (${_selectedUnit.toUpperCase()})',
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
            children: suggestions.take(6).map((weight) => GestureDetector(
              onTap: () {
                _valueController.text = weight.toString();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentWeightColor().withValues(alpha: 0.1),
                      _getCurrentWeightColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentWeightColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$weight ${_selectedUnit.toUpperCase()}',
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

  // Step 2: Body Fat & Feeling - RESPONSIVE VERSION
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
                          Icons.favorite_outline,
                          size: 50,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Body Metrics &\nHow You Feel',
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
                    'Additional body measurements and feeling',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Body Fat Percentage
                  _buildModernTextField(
                    controller: _bodyFatController,
                    label: 'Body Fat % (Optional)',
                    hint: 'e.g., 15.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    isDark: isDark,
                    prefixIcon: Icons.insights_outlined,
                  ),

                  const SizedBox(height: 24),

                  // Feeling Selection Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'How are you feeling?',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Feeling Types Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallHeight ? 3 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isSmallHeight ? 1.4 : 1.8,
                    ),
                    itemCount: _feelingTypes.length,
                    itemBuilder: (context, index) {
                      final feeling = _feelingTypes[index];
                      final isSelected = _selectedFeeling == feeling['name'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFeeling = feeling['name'];
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
                                feeling['color'].withValues(alpha: 0.2),
                                feeling['color'].withValues(alpha: 0.1),
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
                                  ? feeling['color']
                                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: feeling['color'].withValues(alpha: 0.3),
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
                                feeling['icon'],
                                style: TextStyle(fontSize: isSmallHeight ? 20 : 24),
                              ),
                              SizedBox(height: isSmallHeight ? 4 : 8),
                              Text(
                                feeling['name'],
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
                                  feeling['description'],
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
            );
          },
        ),
      ),
    );
  }

  // Step 3: Time & Additional Info - RESPONSIVE VERSION
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
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                            const Color(0xFF10B981).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.access_time,
                          size: 50,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Time & Additional\nInformation',
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
                    'When did you weigh yourself?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Time Selection
                  _buildTimeSelector(isDark),

                  const SizedBox(height: 24),

                  // Custom Feeling Input (if "Other" selected)
                  if (_selectedFeeling == 'Other') ...[
                    _buildModernTextField(
                      controller: _feelingController,
                      label: 'Describe your feeling',
                      hint: 'How are you feeling today?',
                      isDark: isDark,
                      prefixIcon: Icons.psychology_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Time Suggestions
                  _buildTimeSuggestions(isDark),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeSelector(bool isDark) {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(20),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getCurrentWeightColor().withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCurrentWeightColor().withValues(alpha: 0.2),
                    _getCurrentWeightColor().withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.access_time,
                color: _getCurrentWeightColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time of Day',
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTime != null
                        ? _formatTime(_selectedTime!)
                        : 'Tap to select time',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSuggestions(bool isDark) {
    final times = [
      {'label': 'Morning', 'time': TimeOfDay(hour: 7, minute: 0)},
      {'label': 'Afternoon', 'time': TimeOfDay(hour: 14, minute: 0)},
      {'label': 'Evening', 'time': TimeOfDay(hour: 18, minute: 0)},
      {'label': 'Night', 'time': TimeOfDay(hour: 21, minute: 0)},
    ];

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
            'Common times',
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
            children: times.map((timeInfo) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = timeInfo['time'] as TimeOfDay;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentWeightColor().withValues(alpha: 0.1),
                      _getCurrentWeightColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getCurrentWeightColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${timeInfo['label']} (${_formatTime(timeInfo['time'] as TimeOfDay)})',
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

  // Step 4: Custom Fields - RESPONSIVE VERSION
  Widget _buildStep4(bool isDark) {
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
          'Add metrics like muscle mass,\nwater weight, or BMI',
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
                          hint: 'e.g., Muscle Mass',
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
                    hint: 'e.g., 45.2 kg',
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

  // Step 5: Review & Save - RESPONSIVE VERSION
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
                    'Review Your Weight Entry',
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
                          if (_valueController.text.isNotEmpty)
                            _buildReviewCard('Weight', '${_valueController.text} ${_selectedUnit.toUpperCase()}', Icons.monitor_weight, _getCurrentWeightColor(), isDark),

                          if (_bodyFatController.text.isNotEmpty)
                            _buildReviewCard('Body Fat %', '${_bodyFatController.text}%', Icons.insights, Colors.blue, isDark),

                          if (_selectedFeeling != null)
                            _buildReviewCard('Feeling', _selectedFeeling!, Icons.favorite, _getCurrentWeightColor(), isDark),

                          if (_selectedTime != null)
                            _buildReviewCard('Time of Day', _formatTime(_selectedTime!), Icons.access_time, Colors.green, isDark),

                          if (_feelingController.text.isNotEmpty && _selectedFeeling == 'Other')
                            _buildReviewCard('Custom Feeling', _feelingController.text, Icons.psychology, Colors.purple, isDark),

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
                                    'Saving Weight...',
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
                                    _getCurrentWeightEmoji(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Weight Entry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getCurrentWeightColor(),
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
                  backgroundColor: _getCurrentWeightColor(),
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
