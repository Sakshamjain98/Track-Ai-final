import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/routes/routes.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/services/streak_service.dart';
import 'package:trackai/features/settings/service/goalservice.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  DateTime _currentDate = DateTime.now();

  // Firebase data
  Map<String, dynamic>? _goalsData;
  bool _isLoadingGoals = true;
  String? _goalsError;

  // Streak data
  Map<String, bool> _streakData = {};
  bool _isLoadingStreaks = true;
  int _currentStreakCount = 0;
  DateTime? _accountCreationDate;

  @override
  void initState() {
    super.initState();
    _loadGoalsData();
    _loadStreakData();
    _recordDailyLogin();
    _loadAccountCreationDate();
  }

  Future<void> _loadGoalsData() async {
    try {
      setState(() {
        _isLoadingGoals = true;
        _goalsError = null;
      });

      final goalsData = await GoalsService.getGoals();

      setState(() {
        _goalsData = goalsData;
        _isLoadingGoals = false;
      });
    } catch (e) {
      setState(() {
        _goalsError = e.toString();
        _isLoadingGoals = false;
      });
    }
  }

  Future<void> _loadAccountCreationDate() async {
    try {
      _accountCreationDate = await StreakService.getAccountCreationDate();
      setState(() {});
    } catch (e) {
      _accountCreationDate = DateTime.now();
    }
  }

  Future<void> _loadStreakData() async {
    try {
      setState(() => _isLoadingStreaks = true);
      final streakData = await StreakService.getMonthStreakData(_currentDate);
      final currentStreak = await StreakService.getCurrentStreakCount();
      setState(() {
        _streakData = streakData;
        _currentStreakCount = currentStreak;
        _isLoadingStreaks = false;
      });
    } catch (e) {
      setState(() => _isLoadingStreaks = false);
    }
  }

  Future<void> _recordDailyLogin() async {
    try {
      await StreakService.recordDailyLogin();
      _loadStreakData();
    } catch (_) {}
  }

  void _navigateToWeek(int direction) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: 7 * direction));
    });
    _loadStreakData();
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.08),
          blurRadius: 10,
          spreadRadius: 0,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  void _handleAILabAction(String action) {
    switch (action) {
      case 'body-analyzer':
        Navigator.pushNamed(context, AppRoutes.bodyAnalyzer);
        break;
      case 'smart-gymkit':
        Navigator.pushNamed(context, AppRoutes.smartGymkit);
        break;
      case 'calorie_calc':
        Navigator.pushNamed(context, AppRoutes.calorieCalculator);
        break;
      case 'meal_planner':
        Navigator.pushNamed(context, AppRoutes.mealPlanner);
        break;
      case 'recipe_generator':
        Navigator.pushNamed(context, AppRoutes.recipeGenerator);
        break;
      default:
        _showSnackBar('Feature coming soon!');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final weekDates = _getWeekDates(_currentDate);

    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Week Calendar with dashed circles
              _buildWeekCalendar(screenWidth, screenHeight, weekDates),
              SizedBox(height: screenHeight * 0.03),

              // Main Content
              _buildMainContentPage(),

              SizedBox(height: screenHeight * 0.03),

              // AI Lab with equal height cards
              _buildFullAILabSection(),
              SizedBox(height: screenHeight * 0.03),

              // Wellness Tips
              _buildWellnessTipsSection(),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Week Calendar with ALL dashed circles and today highlighted
  Widget _buildWeekCalendar(
      double screenWidth,
      double screenHeight,
      List<DateTime> weekDates,
      ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: _getCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDates.asMap().entries.map((entry) {
          final date = entry.value;
          final dayLetters = ['F', 'S', 'S', 'M', 'T', 'W', 'T'];
          final dayLetter = dayLetters[entry.key];

          final today = DateTime.now();
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;

          return Column(
            children: [
              // All day letters with dashed circle borders
              CustomPaint(
                painter: DashedCirclePainter(
                  color: Colors.grey[400]!,
                  strokeWidth: 1.5,
                ),
                child: Container(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                  child: Center(
                    child: Text(
                      dayLetter,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.008),
              // Date number - bold if today
              Text(
                '${date.day}',
                style: TextStyle(
                  color: isToday ? Colors.black87 : Colors.black54,
                  fontSize: screenWidth * 0.035,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Main Content Page
  Widget _buildMainContentPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoadingGoals) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.1),
        decoration: _getCardDecoration(),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_goalsError != null || _goalsData == null) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: _getCardDecoration(),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Set Your Daily Targets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.adjustGoals),
              child: Text('Set Goals'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Large Calories Card
        Container(
          padding: EdgeInsets.all(screenWidth * 0.06),
          decoration: _getCardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_goalsData!['calories'] ?? 0}',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenWidth * 0.13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Calories left',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ),
              // UPDATED ICON CONTAINER
              Container(
                width: screenWidth * 0.25,
                height: screenWidth * 0.25,
                padding: EdgeInsets.all(8.0), // This is the grey border thickness
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300]!,
                ),
                child: Container(
                  padding: EdgeInsets.all(3.0), // This is the white border/gap thickness
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Icon(
                      lucide.LucideIcons.flame,
                      size: screenWidth * 0.09, // Adjusted icon size
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: screenHeight * 0.025),

        // Three Macro Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: _getCardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_goalsData!['protein'] ?? 0}g',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'Protein left',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // UPDATED ICON CONTAINER
                    Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      padding: EdgeInsets.all(5.0), // This is the grey border thickness
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300]!,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(3.0), // This is the white border/gap thickness
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Icon(
                            lucide.LucideIcons.zap,
                            color: Colors.amber,
                            size: screenWidth * 0.06, // Adjusted icon size
                            fill: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: _getCardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_goalsData!['carbs'] ?? 0}g',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'Carbs left',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // UPDATED ICON CONTAINER
                    Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      padding: EdgeInsets.all(5.0), // This is the grey border thickness
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300]!,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(3.0), // This is the white border/gap thickness
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Icon(
                            lucide.LucideIcons.wheat,
                            color: Colors.green,
                            size: screenWidth * 0.06, // Adjusted icon size
                            fill: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: _getCardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_goalsData!['fat'] ?? 0}g',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'Fats left',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // UPDATED ICON CONTAINER
                    Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      padding: EdgeInsets.all(5.0), // This is the grey border thickness
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300]!,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(3.0), // This is the white border/gap thickness
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Icon(
                            lucide.LucideIcons.droplet,
                            color: Colors.blue,
                            size: screenWidth * 0.06, // Adjusted icon size
                            fill: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Fiber Section
        SizedBox(height: screenHeight * 0.025),
        _buildFiberSection(),
      ],
    );
  }

  // Fiber Widget
  Widget _buildFiberSection() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: _getCardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Fiber Remaining",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: sw * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    "${_goalsData?['fiber'] ?? 0}",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: sw * 0.08,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: sw * 0.008),
                  Text(
                    "g",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: sw * 0.03,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // UPDATED ICON CONTAINER
          Container(
            width: sw * 0.15,
            height: sw * 0.15,
            padding: EdgeInsets.all(5.0), // This is the grey border thickness
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300]!,
            ),
            child: Container(
              padding: EdgeInsets.all(3.0), // This is the white border/gap thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Icon(
                  lucide.LucideIcons.leaf,
                  size: sw * 0.06, // Adjusted icon size
                  color: Colors.green,
                  fill: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // AI Lab Section with FIXED EQUAL HEIGHT CARDS
  Widget _buildFullAILabSection() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final cardHeight = sh * 0.16; // Fixed height for all cards

    return Container(
      padding: EdgeInsets.all(sw * 0.05),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(lucide.LucideIcons.sparkles, color: const Color(0xFF26A69A), size: sw * 0.06),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Text(
                  "AI Lab Quick Actions",
                  style: TextStyle(color: Colors.black87, fontSize: sw * 0.045, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.01),
          Text(
            "Launch powerful AI assistance with a single tap.",
            style: TextStyle(color: Colors.black54, fontSize: sw * 0.035),
          ),
          SizedBox(height: sh * 0.025),

          // Body Composition Analyzer - Full width
          _aiLabCard("Body Composition Analyzer", "Get 18 detailed body composition metrics.",
              lucide.LucideIcons.personStanding, "body-analyzer", cardHeight, sw, sh),
          SizedBox(height: sh * 0.02),

          // Row 1
          Row(
            children: [
              Expanded(child: _aiLabCard("AI Workout Planner", "Your gym companion.",
                  lucide.LucideIcons.activity, "smart-gymkit", cardHeight, sw, sh)),
              SizedBox(width: sw * 0.03),
              Expanded(child: _aiLabCard("Calorie Burn Calc", "Estimate burned calories.",
                  lucide.LucideIcons.flame, "calorie_calc", cardHeight, sw, sh)),
            ],
          ),
          SizedBox(height: sh * 0.02),

          // Row 2
          Row(
            children: [
              Expanded(child: _aiLabCard("AI Meal Planner", "Get tailored meal plans.",
                  lucide.LucideIcons.utensilsCrossed, "meal_planner", cardHeight, sw, sh)),
              SizedBox(width: sw * 0.03),
              Expanded(child: _aiLabCard("AI Recipe Generator", "Create recipes instantly.",
                  lucide.LucideIcons.chefHat, "recipe_generator", cardHeight, sw, sh)),
            ],
          ),
          SizedBox(height: sh * 0.02),

          // Row 3 - Coming Soon
          Row(
            children: [
              Expanded(child: _comingSoonCard("AI Nutrition Coach", "Smart nutrition guidance.",
                  lucide.LucideIcons.brain, cardHeight, sw, sh)),
              SizedBox(width: sw * 0.03),
              Expanded(child: _comingSoonCard("AI Fitness Tracker", "Intelligent workout tracking.",
                  lucide.LucideIcons.trophy, cardHeight, sw, sh)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiLabCard(String title, String desc, IconData icon, String action, double height, double sw, double sh) {
    return GestureDetector(
      onTap: () => _handleAILabAction(action),
      child: Container(
        height: height,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Color(0xFF26A69A), size: sw * 0.08),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.black87, fontSize: sw * 0.038 ,fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: sh * 0.003),
                Text(desc, style: TextStyle(color: Colors.black54, fontSize: sw * 0.03), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _comingSoonCard(String title, String desc, IconData icon, double height, double sw, double sh) {
    return GestureDetector(
      onTap: () => _showSnackBar('Feature coming soon!'),
      child: Container(
        height: height,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[500], size: sw * 0.08),
                SizedBox(width: sw * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.02, vertical: sw * 0.01),
                  decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                  child: Text("SOON", style: TextStyle(color: Colors.orange[700], fontSize: sw * 0.028, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: sw * 0.038, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: sh * 0.003),
                Text(desc, style: TextStyle(color: Colors.grey[500], fontSize: sw * 0.03), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Wellness Tips
  Widget _buildWellnessTipsSection() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(sw * 0.05),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(lucide.LucideIcons.lightbulb, color: Colors.amber, size: sw * 0.06),
              SizedBox(width: sw * 0.03),
              Text("Wellness Tips", style: TextStyle(color: Colors.black87, fontSize: sw * 0.045, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: sh * 0.02),
          _tip("Aim for 7-9 hours of sleep per night.", sw),
          SizedBox(height: sh * 0.015),
          _tip("Stay hydrated with at least 8 glasses of water daily.", sw),
          SizedBox(height: sh * 0.015),
          _tip("Exercise at least 30 minutes a day to boost energy.", sw),
        ],
      ),
    );
  }

  Widget _tip(String text, double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(lucide.LucideIcons.check, size: sw * 0.04, color: Colors.green),
          SizedBox(width: sw * 0.03),
          Expanded(child: Text(text, style: TextStyle(color: Colors.black54, fontSize: sw * 0.033))),
        ],
      ),
    );
  }
}

// Custom painter for dashed circle border
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const dashWidth = 3.0;
    const dashSpace = 3.0;

    double currentAngle = 0;
    const totalAngle = 2 * 3.14159;

    while (currentAngle < totalAngle) {
      final startAngle = currentAngle;
      final endAngle = (currentAngle + dashWidth / radius).clamp(0.0, totalAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );

      currentAngle = endAngle + dashSpace / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}