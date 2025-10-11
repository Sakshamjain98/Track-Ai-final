import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';

class LongTermResultsPage extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LongTermResultsPage({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'TrackAI creates long-term results',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E2E),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 350,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkPrimary.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.darkPrimary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem(
                            'Traditional Diet',
                            Colors.red[400]!,
                          ),
                          const SizedBox(width: 32),
                          _buildLegendItem('TrackAI', AppColors.darkPrimary),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Expanded(child: _buildGraph()),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAxisLabel('Month 2'),
                          _buildAxisLabel('Month 4'),
                          _buildAxisLabel('Month 6'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Statistics text
                Text(
                  '80% of TrackAI users maintain their weight loss\neven 6 months later.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 80),

                // Navigation buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: Colors.black, // ✅ always black background
                        ),
                        child: ElevatedButton(
                          onPressed: onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors
                                  .white, // ✅ white text on black background
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
      ),
    );
  }

  Widget _buildGraph() {
    return CustomPaint(painter: GraphPainter(), child: Container());
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildAxisLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 1; i < 4; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Traditional Diet line (red, showing weight regain)
    paint.color = Colors.red[400]!;
    final traditionalPath = Path();
    traditionalPath.moveTo(
      0,
      size.height * 0.65,
    ); // Start lower (initial weight loss)
    traditionalPath.cubicTo(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.4,
      size.height * 0.45,
      size.width * 0.5,
      size.height * 0.35,
    );
    traditionalPath.cubicTo(
      size.width * 0.6,
      size.height * 0.25,
      size.width * 0.8,
      size.height * 0.15,
      size.width,
      size.height * 0.1, // End higher (weight regained)
    );
    canvas.drawPath(traditionalPath, paint);

    // Add dots for traditional diet
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.65), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), 6, paint);
    canvas.drawCircle(Offset(size.width, size.height * 0.1), 6, paint);

    // TrackAI line (teal, showing maintained weight loss)
    paint.color = AppColors.darkPrimary;
    paint.style = PaintingStyle.stroke;
    final trackaiPath = Path();
    trackaiPath.moveTo(0, size.height * 0.65); // Start at same point
    trackaiPath.cubicTo(
      size.width * 0.2,
      size.height * 0.62,
      size.width * 0.4,
      size.height * 0.68,
      size.width * 0.5,
      size.height * 0.7,
    );
    trackaiPath.cubicTo(
      size.width * 0.6,
      size.height * 0.72,
      size.width * 0.8,
      size.height * 0.75,
      size.width,
      size.height * 0.73, // End lower (weight maintained)
    );
    canvas.drawPath(trackaiPath, paint);

    // Add dots for TrackAI
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.65), 6, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 6, paint);
    canvas.drawCircle(Offset(size.width, size.height * 0.73), 6, paint);

    // Add gradient fill areas for better visual appeal
    final traditionalGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.red[100]!.withOpacity(0.3),
          Colors.red[50]!.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final traditionalFillPath = Path();
    traditionalFillPath.moveTo(0, size.height);
    traditionalFillPath.lineTo(0, size.height * 0.65);
    traditionalFillPath.cubicTo(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.4,
      size.height * 0.45,
      size.width * 0.5,
      size.height * 0.35,
    );
    traditionalFillPath.cubicTo(
      size.width * 0.6,
      size.height * 0.25,
      size.width * 0.8,
      size.height * 0.15,
      size.width,
      size.height * 0.1,
    );
    traditionalFillPath.lineTo(size.width, size.height);
    traditionalFillPath.close();
    canvas.drawPath(traditionalFillPath, traditionalGradient);

    final trackaiGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.darkPrimary.withOpacity(0.2),
          AppColors.darkPrimary.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final trackaiFillPath = Path();
    trackaiFillPath.moveTo(0, size.height);
    trackaiFillPath.lineTo(0, size.height * 0.65);
    trackaiFillPath.cubicTo(
      size.width * 0.2,
      size.height * 0.62,
      size.width * 0.4,
      size.height * 0.68,
      size.width * 0.5,
      size.height * 0.7,
    );
    trackaiFillPath.cubicTo(
      size.width * 0.6,
      size.height * 0.72,
      size.width * 0.8,
      size.height * 0.75,
      size.width,
      size.height * 0.73,
    );
    trackaiFillPath.lineTo(size.width, size.height);
    trackaiFillPath.close();
    canvas.drawPath(trackaiFillPath, trackaiGradient);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
