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
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                const SizedBox(height: 16),

                const Text(
                  'TrackAI creates\nlong-term results',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.start,
                ),

                const SizedBox(height: 38),

                // Graph Card - EXACT Cal AI replica
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Y-axis label
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Your weight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Graph
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          painter: PerfectCalAIGraphPainter(),
                          child: Container(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // X-axis labels
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Month 1',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF999999),
                              ),
                            ),
                            Text(
                              'Month 6',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Legend - Exact Cal AI style
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 6),
                                Text(
                                  'TrackAI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildLegendItem('Weight', Colors.black),
                          _buildLegendItem('Traditional diet', const Color(0xFFE85D75)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Statistics text
                const Text(
                  '80% of TrackAI users maintain their\nweight loss even 6 months later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

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
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: Colors.black,
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
                              color: Colors.white,
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

class PerfectCalAIGraphPainter extends CustomPainter {
  @override
  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal dashed grid lines
    final dashedLinePaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Top dashed line
    _drawDashedLine(
      canvas,
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      dashedLinePaint,
    );

    // Bottom dashed line
    _drawDashedLine(
      canvas,
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      dashedLinePaint,
    );

    // Paint setup
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // DRAW GRADIENT FILLS FIRST (behind the lines)

    // Black gradient fill
    final blackGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.08),
          Colors.black.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final blackFillPath = Path();
    blackFillPath.moveTo(0, size.height);
    blackFillPath.lineTo(0, size.height * 0.25);
    blackFillPath.cubicTo(
      size.width * 0.2,
      size.height * 0.28,
      size.width * 0.3,
      size.height * 0.38,
      size.width * 0.45,
      size.height * 0.5,
    );
    blackFillPath.cubicTo(
      size.width * 0.6,
      size.height * 0.62,
      size.width * 0.8,
      size.height * 0.7,
      size.width,
      size.height * 0.75,
    );
    blackFillPath.lineTo(size.width, size.height);
    blackFillPath.close();
    canvas.drawPath(blackFillPath, blackGradient);

    // Pink gradient fill
    final pinkGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE85D75).withOpacity(0.15),
          const Color(0xFFE85D75).withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pinkFillPath = Path();
    pinkFillPath.moveTo(0, size.height);
    pinkFillPath.lineTo(0, size.height * 0.25);
    pinkFillPath.cubicTo(
      size.width * 0.15,
      size.height * 0.27,
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.35,
      size.height * 0.48,
    );
    pinkFillPath.cubicTo(
      size.width * 0.45,
      size.height * 0.6,
      size.width * 0.52,
      size.height * 0.58,
      size.width * 0.6,
      size.height * 0.45,
    );
    pinkFillPath.cubicTo(
      size.width * 0.7,
      size.height * 0.32,
      size.width * 0.85,
      size.height * 0.18,
      size.width,
      size.height * 0.12,
    );
    pinkFillPath.lineTo(size.width, size.height);
    pinkFillPath.close();
    canvas.drawPath(pinkFillPath, pinkGradient);

    // NOW DRAW THE LINES ON TOP

    // BLACK LINE (Weight) - GOES DOWN (weight loss maintained)
    paint.color = Colors.black;
    final blackPath = Path();
    blackPath.moveTo(0, size.height * 0.25);
    blackPath.cubicTo(
      size.width * 0.2,
      size.height * 0.28,
      size.width * 0.3,
      size.height * 0.38,
      size.width * 0.45,
      size.height * 0.5,
    );
    blackPath.cubicTo(
      size.width * 0.6,
      size.height * 0.62,
      size.width * 0.8,
      size.height * 0.7,
      size.width,
      size.height * 0.75,
    );
    canvas.drawPath(blackPath, paint);

    // Add dots for black line
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.25), 6, paint);
    canvas.drawCircle(Offset(size.width, size.height * 0.75), 6, paint);

    // PINK LINE (Traditional diet) - GOES UP (weight regain)
    paint.color = const Color(0xFFE85D75);
    paint.style = PaintingStyle.stroke;
    final pinkPath = Path();
    pinkPath.moveTo(0, size.height * 0.25);
    pinkPath.cubicTo(
      size.width * 0.15,
      size.height * 0.27,
      size.width * 0.25,
      size.height * 0.35,
      size.width * 0.35,
      size.height * 0.48,
    );
    pinkPath.cubicTo(
      size.width * 0.45,
      size.height * 0.6,
      size.width * 0.52,
      size.height * 0.58,
      size.width * 0.6,
      size.height * 0.45,
    );
    pinkPath.cubicTo(
      size.width * 0.7,
      size.height * 0.32,
      size.width * 0.85,
      size.height * 0.18,
      size.width,
      size.height * 0.12,
    );
    canvas.drawPath(pinkPath, paint);

    // Add dots for pink line
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, size.height * 0.25), 6, paint);
    canvas.drawCircle(Offset(size.width, size.height * 0.12), 6, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    double currentX = start.dx;
    bool drawing = true;

    while (currentX < end.dx) {
      final nextX = currentX + (drawing ? dashWidth : dashSpace);
      if (drawing) {
        canvas.drawLine(
          Offset(currentX, start.dy),
          Offset(nextX.clamp(start.dx, end.dx), start.dy),
          paint,
        );
      }
      currentX = nextX;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
