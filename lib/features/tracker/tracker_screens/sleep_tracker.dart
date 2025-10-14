import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentStep = 0;
  final int _totalSteps = 6;

  // Controllers for each field
  final _valueController = TextEditingController();
  final _qualityController = TextEditingController();
  final _dreamNotesController = TextEditingController();
  final _interruptionsController = TextEditingController();

  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

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
    _valueController.dispose();
    _qualityController.dispose();
    _dreamNotesController.dispose();
    _interruptionsController.dispose();

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
        'quality': int.tryParse(_qualityController.text) ?? 5,
        'dreamNotes': _dreamNotesController.text.trim(),
        'interruptions': _interruptionsController.text.trim(),
        'customData': customData,
        'trackerType': 'sleep',
      };

      await TrackerService.saveTrackerEntry('sleep', entryData);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Sleep entry saved successfully! 🌙'),
              ],
            ),
            backgroundColor: Colors.green,
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
                          _buildStep1(isDark), // Sleep Duration
                          _buildStep2(isDark), // Sleep Quality
                          _buildStep3(isDark), // Dream Notes
                          _buildStep4(isDark), // Interruptions
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
                            const Color(0xFF667EEA),
                            const Color(0xFF667EEA).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.bedtime,
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
                            'Sleep Tracker',
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
                          const Color(0xFF667EEA),
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
                  const Color(0xFF667EEA),
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
      case 0: return 'Duration';
      case 1: return 'Quality';
      case 2: return 'Dreams';
      case 3: return 'Interruptions';
      case 4: return 'Custom Data';
      case 5: return 'Review';
      default: return '';
    }
  }

  // Step 1: Sleep Duration
  Widget _buildStep1(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '🛌 Sleep Duration',
          subtitle: 'How many hours did you sleep last night?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Animated Sleep Icon
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withValues(alpha: 0.2),
                              const Color(0xFF764BA2).withValues(alpha: 0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bedtime_outlined,
                          size: 60,
                          color: const Color(0xFF667EEA),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                _buildEnhancedTextField(
                  controller: _valueController,
                  label: 'Hours of Sleep',
                  hint: 'e.g., 7.5',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.schedule,
                  helpText: 'Adults typically need 7-9 hours of sleep per night',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 2: Sleep Quality
  Widget _buildStep2(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '⭐ Sleep Quality',
          subtitle: 'How would you rate your sleep quality?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Quality Rating Visual
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.2),
                        const Color(0xFFFFA500).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_outline,
                    size: 60,
                    color: const Color(0xFFFFD700),
                  ),
                ),

                const SizedBox(height: 40),

                _buildEnhancedTextField(
                  controller: _qualityController,
                  label: 'Quality Rating (1-10)',
                  hint: 'Rate your sleep from 1-10',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  autofocus: true,
                  prefixIcon: Icons.star_border,
                  helpText: '1 = Very Poor, 5 = Average, 10 = Excellent',
                ),

                const SizedBox(height: 20),

                // Quality Scale Visual
                _buildQualityScale(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualityScale(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildScaleItem('😴', '1-2\nPoor', isDark),
          _buildScaleItem('😐', '3-4\nFair', isDark),
          _buildScaleItem('🙂', '5-6\nGood', isDark),
          _buildScaleItem('😊', '7-8\nGreat', isDark),
          _buildScaleItem('😍', '9-10\nPerfect', isDark),
        ],
      ),
    );
  }

  Widget _buildScaleItem(String emoji, String label, bool isDark) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Step 3: Dream Notes
  Widget _buildStep3(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '💭 Dream Notes',
          subtitle: 'Tell us about your dreams (optional)',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9C27B0).withValues(alpha: 0.2),
                        const Color(0xFF673AB7).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_outlined,
                    size: 60,
                    color: const Color(0xFF9C27B0),
                  ),
                ),

                const SizedBox(height: 40),

                _buildEnhancedTextField(
                  controller: _dreamNotesController,
                  label: 'Dream Description',
                  hint: 'Describe your dreams, themes, or emotions...',
                  isDark: isDark,
                  maxLines: 4,
                  autofocus: true,
                  prefixIcon: Icons.psychology,
                  helpText: 'Dreams can provide insights into your subconscious mind',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 4: Interruptions
  Widget _buildStep4(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStepContainer(
          isDark: isDark,
          title: '⚠️ Sleep Interruptions',
          subtitle: 'Any disruptions to your sleep?',
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF5722).withValues(alpha: 0.2),
                        const Color(0xFFFF9800).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_outlined,
                    size: 60,
                    color: const Color(0xFFFF5722),
                  ),
                ),

                const SizedBox(height: 40),

                _buildEnhancedTextField(
                  controller: _interruptionsController,
                  label: 'Interruptions',
                  hint: 'e.g., noise, bathroom visits, partner movement...',
                  isDark: isDark,
                  maxLines: 3,
                  autofocus: true,
                  prefixIcon: Icons.notifications_off,
                  helpText: 'Tracking interruptions helps identify sleep patterns',
                ),
              ],
            ),
          ),
        ),
      ),
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
          subtitle: 'Add personalized sleep metrics',
          child: _customFields.isEmpty ? _buildEmptyCustomFields(isDark) : _buildCustomFieldsList(isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyCustomFields(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
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
            size: 60,
            color: const Color(0xFF00BCD4),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'No custom fields yet',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Add custom metrics like sleep position,\nroom temperature, or caffeine intake',
          style: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        _buildAddCustomFieldButton(isDark),
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
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedTextField(
                          controller: field['key']!,
                          label: 'Field Name',
                          hint: 'e.g., Sleep Position',
                          isDark: isDark,
                          prefixIcon: Icons.label_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => _removeCustomField(index),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEnhancedTextField(
                    controller: field['value']!,
                    label: 'Field Value',
                    hint: 'e.g., Side sleeper',
                    isDark: isDark,
                    prefixIcon: Icons.edit_outlined,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
          _buildAddCustomFieldButton(isDark),
        ],
      ),
    );
  }

  Widget _buildAddCustomFieldButton(bool isDark) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addCustomField,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Custom Field',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
          subtitle: 'Confirm your sleep data before saving',
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Review Cards
                _buildReviewCard('Sleep Duration', '${_valueController.text} hours', Icons.schedule, Colors.blue, isDark),
                _buildReviewCard('Sleep Quality', '${_qualityController.text}/10', Icons.star, Colors.amber, isDark),

                if (_dreamNotesController.text.isNotEmpty)
                  _buildReviewCard('Dreams', _dreamNotesController.text, Icons.psychology, Colors.purple, isDark),

                if (_interruptionsController.text.isNotEmpty)
                  _buildReviewCard('Interruptions', _interruptionsController.text, Icons.warning_amber, Colors.orange, isDark),

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

                const SizedBox(height: 40),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667EEA),
                        const Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveEntry,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Saving your sleep data...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Save Sleep Entry 🌙',
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
                  ),
                ),
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
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFF8FAFF).withValues(alpha: 0.7),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
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
            borderRadius: BorderRadius.circular(16),
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
              fontSize: 16,
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
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 8),
          Text(
            helpText,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
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
                      const Color(0xFF667EEA),
                      const Color(0xFF667EEA).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.3),
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
