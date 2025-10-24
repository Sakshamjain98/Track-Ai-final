import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class HeightWeightPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const HeightWeightPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  }) : super(key: key);

  @override
  State<HeightWeightPage> createState() => _HeightWeightPageState();
}

class _HeightWeightPageState extends State<HeightWeightPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool isMetric = false;
  double heightFeet = 5;
  double heightInches = 6;
  double heightCm = 168;
  double weightLbs = 119;
  double weightKg = 54;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    isMetric = widget.initialData['isMetric'] ?? false;
    heightFeet = (widget.initialData['heightFeet'] ?? 5).toDouble();
    heightInches = (widget.initialData['heightInches'] ?? 6).toDouble();
    weightLbs = (widget.initialData['weightLbs'] ?? 119).toDouble();

    // Convert to metric if needed
    _updateMetricValues();

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

  void _updateMetricValues() {
    if (isMetric) {
      heightCm = (heightFeet * 12 + heightInches) * 2.54;
      weightKg = weightLbs * 0.453592;
    } else {
      double totalInches = heightCm / 2.54;
      heightFeet = (totalInches / 12).floorToDouble();
      heightInches = totalInches % 12;
      weightLbs = weightKg / 0.453592;
    }
  }

  void _toggleUnit() {
    setState(() {
      isMetric = !isMetric;
      _updateMetricValues();
    });
    _updateData();
  }

  void _updateData() {
    Map<String, dynamic> data = {
      'isMetric': isMetric,
      'heightFeet': heightFeet.round(),
      'heightInches': heightInches.round(),
      'heightCm': heightCm.round(),
      'weightLbs': weightLbs,
      'weightKg': weightKg,
    };
    widget.onDataUpdate(data);
  }

  void _continue() {
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [

                              _buildTitle(),
                              const SizedBox(height: 24),
                              _buildSubtitle(),
                              const SizedBox(height: 32),
                              _buildUnitToggle(),
                              const SizedBox(height: 40),
                              _buildSliders(),
                              const SizedBox(height: 40),
                            ],
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
          color: Colors.white, // ✅ white background
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black, // ✅ black arrow
          size: 20,
        ),
      ),
    );
  }


  Widget _buildTitle() {
    return const Text(
      'Your measurements',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black, // ✅ black text
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Help us personalize your fitness journey with accurate measurements.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary(true),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }


  Widget _buildUnitToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ white background
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isMetric) _toggleUnit();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isMetric
                      ? Colors.black
                      : Colors.transparent, // ✅ black when selected
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Imperial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: !isMetric
                          ? Colors
                                .white // ✅ white text when selected
                          : Colors.black, // ✅ black text when not selected
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isMetric) _toggleUnit();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isMetric
                      ? Colors.black
                      : Colors.transparent, // ✅ black when selected
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'Metric',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isMetric ? Colors.white : Colors.black,
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

  Widget _buildSliders() {
    return Row(
      children: [
        Expanded(child: _buildHeightSlider()),
        const SizedBox(width: 32),
        Expanded(child: _buildWeightSlider()),
      ],
    );
  }

  Widget _buildHeightSlider() {
    return Column(
      children: [
        Text(
          'Height',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black, // ✅ black text
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: isMetric
              ? _buildMetricHeightSlider()
              : _buildImperialHeightSliders(),
        ),
        const SizedBox(height: 12),
        Text(
          isMetric
              ? '${heightCm.round()} cm'
              : '${heightFeet.round()}\' ${heightInches.round()}"',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black, // ✅ black text
          ),
        ),
      ],
    );
  }

  Widget _buildImperialHeightSliders() {
    return Row(
      children: [
        // Feet slider
        Expanded(
          child: Column(
            children: [
              Text(
                'ft',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      activeTrackColor: Colors.black, // ✅ black active track
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.black, // ✅ black thumb
                      overlayColor: Colors.black.withOpacity(
                        0.3,
                      ), // ✅ black overlay
                    ),
                    child: Slider(
                      value: heightFeet,
                      min: 3,
                      max: 8,
                      divisions: 50,
                      onChanged: (value) {
                        setState(() {
                          heightFeet = value;
                          heightCm = (heightFeet * 12 + heightInches) * 2.54;
                        });
                        _updateData();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Inches slider
        Expanded(
          child: Column(
            children: [
              Text(
                'in',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      activeTrackColor: Colors.black, // ✅ black active track
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.black, // ✅ black thumb
                      overlayColor: Colors.black.withOpacity(
                        0.3,
                      ), // ✅ black overlay
                    ),
                    child: Slider(
                      value: heightInches,
                      min: 0,
                      max: 11,
                      divisions: 110,
                      onChanged: (value) {
                        setState(() {
                          heightInches = value;
                          heightCm = (heightFeet * 12 + heightInches) * 2.54;
                        });
                        _updateData();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricHeightSlider() {
    return Column(
      children: [
        Text(
          'cm',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: Colors.black, // ✅ black active track
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.black, // ✅ black thumb
                overlayColor: Colors.black.withOpacity(0.3), // ✅ black overlay
              ),
              child: Slider(
                value: heightCm,
                min: 120,
                max: 220,
                divisions: 100,
                onChanged: (value) {
                  setState(() {
                    heightCm = value;
                    double totalInches = heightCm / 2.54;
                    heightFeet = (totalInches / 12).floorToDouble();
                    heightInches = totalInches % 12;
                  });
                  _updateData();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSlider() {
    return Column(
      children: [
        Text(
          'Weight',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black, // ✅ black text
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            children: [
              Text(
                isMetric ? 'kg' : 'lbs',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20,
                      ),
                      activeTrackColor: Colors.black, // ✅ black active track
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.black, // ✅ black thumb
                      overlayColor: Colors.black.withOpacity(
                        0.3,
                      ), // ✅ black overlay
                    ),
                    child: Slider(
                      value: isMetric ? weightKg : weightLbs,
                      min: isMetric ? 30 : 66,
                      max: isMetric ? 200 : 440,
                      divisions: isMetric ? 170 : 374,
                      onChanged: (value) {
                        setState(() {
                          if (isMetric) {
                            weightKg = value;
                            weightLbs = weightKg / 0.453592;
                          } else {
                            weightLbs = value;
                            weightKg = weightLbs * 0.453592;
                          }
                        });
                        _updateData();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isMetric ? '${weightKg.round()} kg' : '${weightLbs.round()} lbs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black, // ✅ black text
          ),
        ),
      ],
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
