import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'dart:math' as math;

class CompletionPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const CompletionPage({
    Key? key,
    required this.onComplete,
    required this.onBack,
  }) : super(key: key);

  @override
  State<CompletionPage> createState() => _CompletionPageState();
}


class _CompletionPageState extends State<CompletionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.bounceOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.linear),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.repeat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Confetti background
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(_rotationAnimation.value),
                  child: Container(),
                );
              },
            ),

            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? screenWidth * 0.2 : 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.1),
                      _buildSuccessIcon(),
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildFeaturesList(),
                      const SizedBox(height: 40),
                      _buildGetStartedButton(),
                      const SizedBox(height: 20),
                      _buildBackButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.successColor,
              const Color.fromARGB(255, 110, 239, 155),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.successColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.successColor,
              const Color.fromARGB(255, 110, 239, 155),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Thank you for trusting us!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.start

            ,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your personalized fitness journey starts now.\nWe\'re excited to help you achieve your goals!',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary(true),
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': FontAwesomeIcons.chartLine,
        'title': 'AI-Powered Tracking',
        'subtitle': 'Smart insights from your daily habits',
      },
      {
        'icon': FontAwesomeIcons.utensils,
        'title': 'Personalized Nutrition',
        'subtitle': 'Meal plans tailored to your preferences',
      },
      {
        'icon': FontAwesomeIcons.dumbbell,
        'title': 'Custom Workouts',
        'subtitle': 'Exercise routines that fit your schedule',
      },
      {
        'icon': FontAwesomeIcons.trophy,
        'title': 'Goal Achievement',
        'subtitle': 'Track progress and celebrate milestones',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(true).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s next?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.successColor,
            ),
          ),
          const SizedBox(height: 20),
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 800 + (index * 200)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.successColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              feature['icon'] as IconData,
                              color: AppColors.successColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  feature['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary(true),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ElevatedButton(
        onPressed: widget.onComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Text(
              'Start Your Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: widget.onBack,
      child: const Text(
        'Go Back',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double animation;

  ConfettiPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final colors = [
      AppColors.successColor,
      const Color(0xFFFFD700),
      const Color(0xFFFF69B4),
      const Color(0xFF00CED1),
      const Color(0xFFFF6347),
    ];

    for (int i = 0; i < 50; i++) {
      final x =
          (size.width * (i % 10) / 10) +
          (30 * math.sin((animation * 2 + i) * 2));
      final y = (size.height * animation + (i * 20)) % size.height;

      paint.color = colors[i % colors.length].withOpacity(0.7);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(animation * 4 + i);

      if (i % 3 == 0) {
        // Draw circles
        canvas.drawCircle(Offset.zero, 3, paint);
      } else {
        // Draw rectangles
        canvas.drawRect(const Rect.fromLTWH(-2, -2, 4, 8), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add this import at the top of the file
