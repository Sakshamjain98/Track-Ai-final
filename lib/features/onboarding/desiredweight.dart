import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';

class DesiredWeightPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(double) onDataUpdate;
  final bool isMetric;

  const DesiredWeightPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
    required this.isMetric,
  }) : super(key: key);

  @override
  State<DesiredWeightPage> createState() => _DesiredWeightPageState();
}

class _DesiredWeightPageState extends State<DesiredWeightPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double desiredWeight = 110;
  double desiredWeightKg = 50;
  bool _isMetric = false; // Local state for metric preference

  @override
  void initState() {
    super.initState();

    // Initialize local metric preference
    _isMetric = widget.isMetric;

    // Initialize based on metric/imperial preference
    if (_isMetric) {
      desiredWeightKg = 50;
      desiredWeight = desiredWeightKg / 0.453592;
    } else {
      desiredWeight = 110;
      desiredWeightKg = desiredWeight * 0.453592;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateWeight(double value) {
    setState(() {
      if (_isMetric) {
        desiredWeightKg = value;
        desiredWeight = desiredWeightKg / 0.453592;
      } else {
        desiredWeight = value;
        desiredWeightKg = desiredWeight * 0.453592;
      }
    });
    widget.onDataUpdate(_isMetric ? desiredWeightKg : desiredWeight);
  }

  void _continue() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    children: [
                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: screenHeight * 0.75,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: screenHeight * 0.05),
                                _buildIcon(),
                                SizedBox(height: screenHeight * 0.05),
                                _buildTitle(),
                                SizedBox(height: screenHeight * 0.03),
                                _buildSubtitle(),
                                SizedBox(height: screenHeight * 0.05),
                                _buildWeightSlider(screenWidth, screenHeight),
                                SizedBox(height: screenHeight * 0.03),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom buttons row
                      Row(
                        children: [
                          _buildBackButton(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildNextButton()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: widget.onBack,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.cardBackground(true).withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.darkGrey, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary(true).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary(true), width: 0.5),
      ),
      child: Icon(
        Icons.monitor_weight,
        color: AppColors.primary(true),
        size: 28,
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          'What\'s your target weight?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildSystemToggle(),
      ],
    );
  }

  Widget _buildSystemToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(true).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.darkGrey, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Imperial', 'lbs', !_isMetric), // ✅ changed
          _buildToggleOption('Metric', 'kg', _isMetric), // ✅ changed
        ],
      ),
    );
  }

  Widget _buildToggleOption(String system, String unit, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (system == 'Metric' && !_isMetric) {
            _isMetric = true;
            desiredWeightKg = desiredWeight * 0.453592;
          } else if (system == 'Imperial' && _isMetric) {
            _isMetric = false;
            desiredWeight = desiredWeightKg / 0.453592;
          }
        });
        widget.onDataUpdate(_isMetric ? desiredWeightKg : desiredWeight);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : AppColors.darkGrey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              system,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(true),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($unit)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary(true).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary(true).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary(true), size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Set your desired weight to help us create\na personalized plan.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary(true),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(double screenWidth, double screenHeight) {
    double circleSize = screenWidth * 0.45;
    if (circleSize > 200) circleSize = 200;
    if (circleSize < 150) circleSize = 150;

    return Center(
      child: Column(
        children: [
          // ✅ Black Circle with White Text
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isMetric
                        ? '${desiredWeightKg.round()}'
                        : '${desiredWeight.round()}',
                    style: TextStyle(
                      fontSize: circleSize * 0.24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isMetric ? 'kg' : 'lbs',
                    style: TextStyle(
                      fontSize: circleSize * 0.09,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.04),

          // ✅ Slider Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Column(
              children: [
                const Text(
                  'Adjust your target weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 16,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                    valueIndicatorShape:
                        const PaddleSliderValueIndicatorShape(),
                    valueIndicatorColor: Colors.black,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: _isMetric ? desiredWeightKg : desiredWeight,
                    min: _isMetric ? 30 : 66,
                    max: _isMetric ? 200 : 440,
                    divisions: _isMetric ? 170 : 374,
                    label: _isMetric
                        ? '${desiredWeightKg.round()} kg'
                        : '${desiredWeight.round()} lbs',
                    onChanged: _updateWeight,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isMetric ? '30 kg' : '66 lbs',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _isMetric ? '200 kg' : '440 lbs',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✅ Tip Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Aim for a healthy and realistic target weight for the best results',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.black,
      ),
      child: ElevatedButton(
        onPressed: _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
