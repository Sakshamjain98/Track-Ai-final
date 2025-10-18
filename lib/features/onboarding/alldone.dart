import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class AllDonePage extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const AllDonePage({Key? key, required this.onComplete, required this.onBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
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
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.08),

                      // Success icon with confetti colors
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.orange,
                          size: 35,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // "All done!" badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'All done!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Title
                      const Text(
                        'Thank you for\ntrusting us',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Privacy message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'We promise to always keep your personal information private and secure.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.06),

                      // Decorative confetti dots (optional)
                      _buildConfettiDots(),
                    ],
                  ),
                ),
              ),

              // Create plan button (no back button)
              SizedBox(height: screenHeight * 0.02),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.black,
                ),
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Create my plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Optional decorative confetti dots
  Widget _buildConfettiDots() {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 50,
            child: _buildDot(Colors.yellow, 6),
          ),
          Positioned(
            top: 30,
            right: 80,
            child: _buildDot(Colors.green, 5),
          ),
          Positioned(
            top: 50,
            left: 100,
            child: _buildDot(Colors.orange, 4),
          ),
          Positioned(
            top: 20,
            right: 120,
            child: _buildDot(Colors.blue, 5),
          ),
          Positioned(
            top: 60,
            right: 50,
            child: _buildDot(Colors.pink, 6),
          ),
          Positioned(
            top: 70,
            left: 80,
            child: _buildDot(Colors.purple, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
