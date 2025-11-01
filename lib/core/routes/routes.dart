import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart'; // Not used, can be removed
import 'package:trackai/feedback/services/feedback_service.dart'; // Assuming this is used elsewhere
import 'package:trackai/features/auth/views/login_page.dart';
import 'package:trackai/features/auth/views/signup_page.dart';
import 'package:trackai/features/onboarding/onboardingflow.dart';
import 'package:trackai/features/home/homepage/homepage.dart';
import 'package:trackai/features/home/presentation/homescreen.dart';
import 'package:trackai/features/home/ai-options/bodyAnalyzer.dart';
import 'package:trackai/features/home/ai-options/smartGymkit.dart';
import 'package:trackai/features/home/ai-options/calorieCalculator.dart';
import 'package:trackai/features/home/ai-options/mealPlanner.dart';
import 'package:trackai/features/home/ai-options/recipeGenerator.dart';
import 'package:trackai/features/settings/adjustgoals.dart';
import 'package:trackai/features/tracker/trackerscreen.dart';
import 'package:trackai/features/analytics/analyticsscreen.dart';
import 'package:trackai/features/settings/presentation/settingsscreen.dart';
import 'package:trackai/features/admin/admin_panel_screen.dart';
import 'package:trackai/features/announcements/announcements_page.dart';

// Ensure correct relative paths based on your project structure
import '../../features/analytics/screens/CycleOS/DailyDetailsScreen.dart';
import '../../features/analytics/screens/CycleOS/LogActivityScreen.dart';
import '../../features/analytics/screens/CycleOS/LogMoodScreen.dart';
import '../../features/analytics/screens/CycleOS/LogNotesScreen.dart';
import '../../features/analytics/screens/CycleOS/LogPeriodScreen.dart';
import '../../features/analytics/screens/CycleOS/LogSymptomsScreen.dart';
import '../../features/analytics/screens/CycleOS/period_cycle.dart';

import '../../feedback/presentation/feedback_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String feedback = '/feedback';

  static const String homeScreen = '/home-screen';
  static const String trackerScreen = '/tracker-screen';
  static const String analyticsScreen = '/analytics-screen';
  static const String settingsScreen = '/settings-screen';
  static const String bodyAnalyzer = '/body-analyzer';
  static const String smartGymkit = '/smart-gymkit';
  static const String calorieCalculator = '/calorie-calculator';
  static const String mealPlanner = '/meal-planner';
  static const String recipeGenerator = '/recipe-generator';
  static const String adjustGoals = '/adjust-goals';
  static const String adminPanel = '/admin-panel';
  static const String announcements = '/announcements';

  // Period Tracking Routes
  static const String periodDashboard = '/period-dashboard';
  static const String logPeriod = '/log-period';
  static const String logSymptoms = '/log-symptoms';
  static const String logMood = '/log-mood';
  static const String logActivity = '/log-activity';
  static const String logNotes = '/log-notes';
  static const String dailyDetails = '/daily-details';

  static const String initialRoute = login; // Or change to '/home' or '/' if needed

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Helper to safely extract arguments
    Map<String, dynamic> getArguments(Object? args) {
      if (args is Map<String, dynamic>) {
        return args;
      }
      return {}; // Return empty map if arguments are missing or wrong type
    }

    // Default date (e.g., today) if none is provided
    final DateTime defaultDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    switch (settings.name) {
      case login: // Use constants for consistency
        return _createRoute(const LoginPage());
      case signup:
        return _createRoute(const SignupPage());
      case onboarding:
        return _createRoute(const OnboardingFlow());
      case feedback:
        return _createRoute(const FeedbackScreen());

      case home:
        return _createRoute(const HomePage());
      case homeScreen:
        return _createRoute(const Homescreen());
      case trackerScreen:
        return _createRoute(const Trackerscreen());
      case analyticsScreen:
        return _createRoute(const AnalyticsScreen());
      case settingsScreen:
        return _createRoute(const Settingsscreen());
      case bodyAnalyzer:
        return _createRoute(const BodyCompositionAnalyzer());
      case smartGymkit:
        return _createRoute(const Smartgymkit());
      case calorieCalculator:
        return _createRoute(const CalorieBurnCalculator());
      case mealPlanner:
        return _createRoute(AIMealPlanner()); // Assuming constructor doesn't need args
      case recipeGenerator:
        return _createRoute(const AIRecipeGenerator());
      case adjustGoals:
        return _createRoute(const AdjustGoalsPage());
      case adminPanel:
        return _createRoute(const AdminPanelScreen());
      case announcements:
        return _createRoute(const AnnouncementsPage());

    // --- Period Tracking Routes ---
      case periodDashboard:
        return _createRoute(const PeriodDashboard());

    // --- Routes requiring arguments ---
      case logPeriod:
        final args = getArguments(settings.arguments);
        final date = args['selectedDate'] as DateTime? ?? defaultDate;
        final data = args['existingData'] as Map<String, dynamic>?;
        final docId = args['docId'] as String?;
        return _createRoute(LogPeriodScreen(selectedDate: date, existingData: data, docId: docId));

      case logSymptoms:
        final args = getArguments(settings.arguments);
        final date = args['selectedDate'] as DateTime? ?? defaultDate;
        final data = args['existingData'] as Map<String, dynamic>?;
        final docId = args['docId'] as String?;
        return _createRoute(LogSymptomsScreen(selectedDate: date, existingData: data, docId: docId));

      case logMood:
        final args = getArguments(settings.arguments);
        final date = args['selectedDate'] as DateTime? ?? defaultDate;
        final data = args['existingData'] as Map<String, dynamic>?;
        final docId = args['docId'] as String?;
        return _createRoute(LogMoodScreen(selectedDate: date, existingData: data, docId: docId));

      case logActivity:
        final args = getArguments(settings.arguments);
        final date = args['selectedDate'] as DateTime? ?? defaultDate;
        final data = args['existingData'] as Map<String, dynamic>?;
        final docId = args['docId'] as String?;
        return _createRoute(LogActivityScreen(selectedDate: date, existingData: data, docId: docId));

      case logNotes:
        final args = getArguments(settings.arguments);
        final date = args['selectedDate'] as DateTime? ?? defaultDate;
        final data = args['existingData'] as Map<String, dynamic>?;
        final docId = args['docId'] as String?;
        return _createRoute(LogNotesScreen(selectedDate: date, existingData: data, docId: docId));

      case dailyDetails:
      // Argument here is just the date
        final dateArg = settings.arguments as DateTime?;
        return _createRoute(DailyDetailsScreen(selectedDate: dateArg ?? defaultDate));

      default:
      // Fallback for unknown routes
        return _createRoute(
          Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(fontSize: 18, color: Colors.red), // Use a visible color
              ),
            ),
          ),
        );
    }
  }

  // Helper method for creating page routes (can customize transitions here)
  static PageRoute _createRoute(Widget page) {
    // Example: Use MaterialPageRoute (default)
    return MaterialPageRoute(builder: (_) => page);

    // Example: Use CupertinoPageRoute for iOS-style transitions
    // return CupertinoPageRoute(builder: (_) => page);

    // Example: Custom fade transition
    /*
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    */
  }
}