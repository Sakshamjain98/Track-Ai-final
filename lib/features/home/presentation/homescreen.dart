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
  PageController _pageController = PageController(initialPage: 1);
  int _currentPageIndex = 1;

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Color _getDateColor(DateTime date) {
    final today = DateTime.now();
    final isToday = date.day == today.day &&
        date.month == today.month &&
        date.year == today.year;
    final dateString = StreakService.formatDateStatic(date);
    final isLoggedIn = _streakData[dateString] ?? false;

    if (_accountCreationDate != null) {
      final accountCreationDateOnly = DateTime(
        _accountCreationDate!.year,
        _accountCreationDate!.month,
        _accountCreationDate!.day,
      );
      final currentDateOnly = DateTime(date.year, date.month, date.day);
      if (currentDateOnly.isBefore(accountCreationDateOnly)) {
        return Colors.transparent;
      }
    }

    // Modified: Today's date should have white background
    if (isToday) return Colors.white;
    if (date.isAfter(today)) return Colors.transparent;
    if (isLoggedIn) return Colors.green.withOpacity(0.3);
    return Colors.red.withOpacity(0.3);
  }

  Color _getDateTextColor(DateTime date) {
    final today = DateTime.now();
    final isToday = date.day == today.day &&
        date.month == today.month &&
        date.year == today.year;

    // Modified: Today's date should have black text
    if (isToday) return Colors.black;
    return Colors.black87;
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 1,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // calendar
              _buildCalendar(screenWidth, screenHeight, weekDates),
              SizedBox(height: screenHeight * 0.03),

              // PageView
              SizedBox(
                height: screenHeight * 0.55,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPageIndex = index),
                  children: [
                    _buildNewFeaturesPage(),
                    _buildMainContentPage(),
                    _buildLogActivitiesPage(),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.01,
                    ),
                    width: _currentPageIndex == index
                        ? screenWidth * 0.03
                        : screenWidth * 0.02,
                    height: screenWidth * 0.02,
                    decoration: BoxDecoration(
                      color: _currentPageIndex == index
                          ? Colors.black
                          : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              SizedBox(height: screenHeight * 0.03),

              // AI Lab
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

  // ---------------- Calendar ----------------
  Widget _buildCalendar(
      double screenWidth,
      double screenHeight,
      List<DateTime> weekDates,
      ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _navigateToWeek(-1),
                icon: Icon(
                  Icons.chevron_left,
                  size: screenWidth * 0.06,
                  color: Colors.black87,
                ),
              ),
              Flexible(
                child: Text(
                  _getMonthYear(_currentDate),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _navigateToWeek(1),
                icon: Icon(
                  Icons.chevron_right,
                  size: screenWidth * 0.06,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDates.map((date) {
              final today = DateTime.now();
              final isToday = date.day == today.day &&
                  date.month == today.month &&
                  date.year == today.year;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
                  height: screenWidth * 0.1,
                  child: isToday
                      ? CustomPaint(
                    painter: DashedCirclePainter(
                      color: Colors.grey[400]!,
                      strokeWidth: 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: _getDateColor(date),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: _getDateTextColor(date),
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- Pages ----------------
  Widget _buildNewFeaturesPage() => _simpleCard(
    Icons.auto_awesome,
    "New Features Coming Soon!",
    "We're always working on new ways...",
  );

  Widget _buildLogActivitiesPage() => _simpleCard(
    Icons.fitness_center,
    "Log Your Activities",
    "Go to tracker to log your meals...",
  );

  Widget _simpleCard(IconData icon, String title, String subtitle) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(sw * 0.05),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: sw * 0.08),
          SizedBox(height: sh * 0.015),
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: sw * 0.045,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sh * 0.01),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black54,
              fontSize: sw * 0.03,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentPage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainContentCard(),
            SizedBox(height: screenHeight * 0.025),
            _buildMacroTrackingSection(),
            SizedBox(height: screenHeight * 0.018),
            _buildFiberSection(),
          ],
        ),
      ),
    );
  }

  // ---------------- Content Cards ----------------
  Widget _buildMainContentCard() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    if (_isLoadingGoals) return _loadingCard("Loading your targets...");
    if (_goalsError != null)
      return _errorCard("Unable to load targets", _loadGoalsData);
    if (_goalsData == null)
      return _errorCard(
        "Set Your Daily Targets",
            () => Navigator.pushNamed(context, AppRoutes.adjustGoals),
      );

    return Container(
      padding: EdgeInsets.all(sw * 0.05),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.target,
                color: Colors.blue,
                size: sw * 0.05,
              ),
              SizedBox(width: sw * 0.02),
              Expanded(
                child: Text(
                  "Your Daily Macro Targets",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.005),
          Text(
            "Personalized goals based on your profile.",
            style: TextStyle(
              color: Colors.black54,
              fontSize: sw * 0.032,
            ),
          ),
          SizedBox(height: sh * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Calories Remaining",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: sw * 0.035,
                    ),
                  ),
                  SizedBox(height: sh * 0.008),
                  Text(
                    "${_goalsData!['calories'] ?? 0} kcal",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: sw * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Updated fire icon with circular grey border
              Container(
                width: sw * 0.15,
                height: sw * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[300]!, // Grey border color
                    width: 2,
                  ),
                  color: Colors.transparent, // Transparent background
                ),
                child: Center(
                  child: Icon(
                    lucide.LucideIcons.flame,
                    size: sw * 0.075,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _loadingCard(String text) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(sw * 0.05),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ),
          SizedBox(height: sh * 0.02),
          Text(
            text,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String title, VoidCallback onTap) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(sw * 0.05),
        decoration: _getCardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: sw * 0.08,
            ),
            SizedBox(height: sh * 0.015),
            Text(
              title,
              style: TextStyle(
                color: Colors.black87,
                fontSize: sw * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTrackingSection() {
    final sw = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Expanded(
          child: _macroCard(
            "Protein",
            "${_goalsData?['protein'] ?? 0}",
            "g left",
            lucide.LucideIcons.zap, // Updated to ZapIcon
            Colors.amber,
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _macroCard(
            "Carbs",
            "${_goalsData?['carbs'] ?? 0}",
            "g left",
            lucide.LucideIcons.wheat, // Updated to WheatIcon
            Colors.green,
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _macroCard(
            "Fats",
            "${_goalsData?['fat'] ?? 0}",
            "g left",
            lucide.LucideIcons.droplet, // Updated to DropletIcon
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _macroCard(
      String title,
      String value,
      String unit,
      IconData icon,
      Color iconColor,
      ) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(sw * 0.03),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black54,
              fontSize: sw * 0.035,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: sh * 0.01),
          // Circular bordered icon container
          Container(
            width: sw * 0.15,
            height: sw * 0.13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[300]!, // Grey border color
                width: 2,
              ),
              color: Colors.transparent, // Transparent background
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: sw * 0.07,
              ),
            ),
          ),
          SizedBox(height: sh * 0.01),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: sw * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.black54,
              fontSize: sw * 0.03,
            ),
          ),
        ],
      ),
    );
  }

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
          Icon(
            lucide.LucideIcons.leaf, // Updated to LeafIcon
            size: sw * 0.08,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  // ---------------- AI Lab ----------------
  Widget _buildFullAILabSection() {
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
              Icon(
                lucide.LucideIcons.sparkles,
                color: const Color(0xFF26A69A),
                size: sw * 0.06,
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Text(
                  "AI Lab Quick Actions",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.01),
          Text(
            "Launch powerful AI assistance with a single tap.",
            style: TextStyle(
              color: Colors.black54,
              fontSize: sw * 0.035,
            ),
          ),
          SizedBox(height: sh * 0.025),
          _aiLabCard(
            "Body Composition Analyzer",
            "Get 18 detailed body composition metrics.",
            lucide.LucideIcons.personStanding,
            "body-analyzer",
          ),
          SizedBox(height: sh * 0.02),
          Row(
            children: [
              Expanded(
                child: _aiLabCard(
                  "AI Workout Planner",
                  "Your gym companion.",
                  lucide.LucideIcons.activity,
                  "smart-gymkit",
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: _aiLabCard(
                  "Calorie Burn Calc",
                  "Estimate burned calories.",
                  lucide.LucideIcons.flame,
                  "calorie_calc",
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.015),
          Row(
            children: [
              Expanded(
                child: _aiLabCard(
                  "AI Meal Planner",
                  "Get tailored meal plans.",
                  lucide.LucideIcons.utensilsCrossed,
                  "meal_planner",
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: _aiLabCard(
                  "AI Recipe Generator",
                  "Create recipes instantly.",
                  lucide.LucideIcons.chefHat,
                  "recipe_generator",
                ),
              ),
            ],
          ),
          // New "Coming Soon" cards row
          SizedBox(height: sh * 0.015),
          Row(
            children: [
              Expanded(
                child: _comingSoonCard(
                  "AI Nutrition Coach",
                  "Smart nutrition guidance.",
                  lucide.LucideIcons.brain,
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: _comingSoonCard(
                  "AI Fitness Tracker",
                  "Intelligent workout tracking.",
                  lucide.LucideIcons.trophy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiLabCard(String title, String desc, IconData icon, String action) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => _handleAILabAction(action),
      child: Container(
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFF26A69A), size: sw * 0.07),
            SizedBox(height: sh * 0.008),
            Text(
              title,
              style: TextStyle(
                color: Colors.black87,
                fontSize: sw * 0.036,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              desc,
              style: TextStyle(
                color: Colors.black54,
                fontSize: sw * 0.028,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  Widget _comingSoonCard(String title, String desc, IconData icon) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => _showSnackBar('Feature coming soon!'),
      child: Container(
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(
          color: Colors.grey[100], // Slightly different background for "coming soon"
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!, // Slightly more prominent border
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.grey[500], // Greyed out icon
                  size: sw * 0.07,
                ),
                SizedBox(width: sw * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.02,
                    vertical: sw * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "SOON",
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: sw * 0.025,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: sh * 0.008),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600], // Greyed out text
                fontSize: sw * 0.036,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              desc,
              style: TextStyle(
                color: Colors.grey[500], // Greyed out description
                fontSize: sw * 0.028,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Wellness Tips ----------------
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
              Icon(
                lucide.LucideIcons.lightbulb, // Matches LightbulbIcon
                color: Colors.amber,
                size: sw * 0.06,
              ),
              SizedBox(width: sw * 0.03),
              Text(
                "Wellness Tips",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.02),
          _tip("Aim for 7-9 hours of sleep per night."),
          SizedBox(height: sh * 0.015),
          _tip("Stay hydrated with at least 8 glasses of water daily."),
          SizedBox(height: sh * 0.015),
          _tip("Exercise at least 30 minutes a day to boost energy."),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    final sw = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.all(sw * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            lucide.LucideIcons.check, // Updated to check (closest match to CheckCircleIcon)
            size: sw * 0.04,
            color: Colors.green,
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black54,
                fontSize: sw * 0.033,
              ),
            ),
          ),
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
    const totalAngle = 2 * 3.14159; // 2π

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
