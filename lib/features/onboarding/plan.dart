import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/settings/service/geminiservice.dart';
import 'package:trackai/features/settings/service/goalservice.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:math' as math;

class PersonalizedPlanPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Map<String, dynamic> onboardingData;

  const PersonalizedPlanPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onboardingData,
  }) : super(key: key);

  @override
  State<PersonalizedPlanPage> createState() => _PersonalizedPlanPageState();
}

class _PersonalizedPlanPageState extends State<PersonalizedPlanPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _goalsData;
  bool _isCalculating = false;
  bool _isCalculated = false;
  String? _error;

  late AnimationController _progressController;
  late Animation<double> _caloriesAnimation;
  late Animation<double> _carbsAnimation;
  late Animation<double> _proteinAnimation;
  late Animation<double> _fatsAnimation;
  late Animation<double> _fiberAnimation; // ADDED: Fiber animation

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _calculateGoals();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  //
  // --- THIS IS THE THIRD FIX ---
  //
  void _initializeAnimations() {
    // All animations now go to 1.0 (100%) to represent the full goal.
    // The number in the middle is what shows the personalized value.
    _caloriesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _carbsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _proteinAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _fatsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _fiberAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );
    _progressController.forward();
  }

  Future<void> _calculateGoals() async {
    setState(() {
      _isCalculating = true;
      _error = null;
    });

    try {
      final calculatedGoals = await GeminiService.calculateNutritionGoals(
        onboardingData: widget.onboardingData,
      );

      if (calculatedGoals == null) {
        throw Exception('Failed to calculate goals. Please try again.');
      }

      // Ensure default values if keys are missing (prevents crash)
      calculatedGoals.putIfAbsent('calories', () => 0);
      calculatedGoals.putIfAbsent('carbs', () => 0);
      calculatedGoals.putIfAbsent('protein', () => 0);
      calculatedGoals.putIfAbsent('fat', () => 0);
      calculatedGoals.putIfAbsent('fiber', () => 0); // ADDED: Ensure fiber key exists

      await GoalsService.saveGoals(calculatedGoals);

      setState(() {
        _goalsData = calculatedGoals;
        _isCalculating = false;
        _isCalculated = true;
      });

      _initializeAnimations();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCalculating = false;
      });
    }
  }

  // FIXED: Show edit dialog for macro values
  Future<void> _showEditDialog(String macroType, dynamic currentValue) async {
    // FIX: Handle potential null value from _goalsData
    final controller =
    TextEditingController(text: (currentValue ?? 0).toString());

    // Map display label to actual Firebase key
    String getFirebaseKey(String label) {
      switch (label.toLowerCase()) {
        case 'calories':
          return 'calories';
        case 'carbs':
          return 'carbs';
        case 'protein':
          return 'protein';
        case 'fats':
          return 'fat';
        case 'fiber': // ADDED: Handle fiber key
          return 'fiber';
        default:
          return label.toLowerCase();
      }
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit $macroType',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your desired $macroType value',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                labelText: macroType,
                labelStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = int.tryParse(controller.text);
              if (newValue != null && newValue >= 0) {
                // Allow 0
                final firebaseKey = getFirebaseKey(macroType);

                setState(() {
                  _goalsData![firebaseKey] = newValue;
                });

                try {
                  await GoalsService.saveGoals(_goalsData!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$macroType updated successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              // Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Personalized\nPlan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Subtitle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Based on your input, here are your daily targets to get started.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Main Content
              Expanded(child: _buildContent()),

              // Navigation Buttons
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: _isCalculated ? Colors.black : Colors.grey[300],
                      ),
                      child: ElevatedButton(
                        onPressed: _isCalculated ? widget.onNext : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Let\'s get started!',
                          style: TextStyle(
                            color: _isCalculated
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isCalculating) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitWave(color: Colors.black, size: 50.0),
          const SizedBox(height: 24),
          Text(
            'Calculating your personalized plan...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 24),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateGoals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (_goalsData != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular progress indicators for macros
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularMacro(
                  'Calories',
                  _goalsData!['calories'] ?? 0, // FIX: Null-safe
                  '',
                  _caloriesAnimation,
                  Colors.orange,
                ),
                _buildCircularMacro(
                  'Carbs',
                  _goalsData!['carbs'] ?? 0, // FIX: Null-safe
                  'g',
                  _carbsAnimation,
                  Colors.brown[400]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularMacro(
                  'Protein',
                  _goalsData!['protein'] ?? 0, // FIX: Null-safe
                  'g',
                  _proteinAnimation,
                  Colors.pink[300]!,
                ),
                _buildCircularMacro(
                  'Fats',
                  _goalsData!['fat'] ?? 0, // FIX: Null-safe
                  'g',
                  _fatsAnimation,
                  Colors.blue[400]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ADDED: Row for Fiber
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularMacro(
                  'Fiber',
                  _goalsData!['fiber'] ?? 0, // ADDED: Fiber value
                  'g',
                  _fiberAnimation, // ADDED: Fiber animation
                  Colors.green[400]!, // ADDED: Fiber color
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Health Score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.pink, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Health score',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 6,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '7/10',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              'How to reach your goals:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildGoalItem(
              Icons.favorite,
              'Use health scores to improve your routine',
              Colors.pink,
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              Icons.restaurant_menu,
              'Track your food',
              Colors.brown[700]!,
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              Icons.access_time,
              'Follow your daily calorie recommendation',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildGoalItem(
              Icons.pie_chart,
              'Balance your carbs, protein, fat',
              Colors.orange,
            ),
            // ADDED: Fiber goal item
            const SizedBox(height: 12),
            _buildGoalItem(
              Icons.eco,
              'Don\'t forget your daily fiber intake',
              Colors.green,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCircularMacro(
      String label,
      dynamic value,
      String unit,
      Animation<double> animation,
      Color color,
      ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom painted circular progress
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: CircularProgressPainter(
                      progress: animation.value,
                      progressColor: color,
                      backgroundColor: Colors.grey[200]!,
                      strokeWidth: 8,
                    ),
                  ),
                  // Value text
                  Text(
                    // FIX: Use the null-safe value
                    '${value ?? 0}$unit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  // Edit icon - NOW CLICKABLE
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: GestureDetector(
                      // FIX: Pass the null-safe value
                      onTap: () => _showEditDialog(label, value ?? 0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalItem(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Circular Progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}