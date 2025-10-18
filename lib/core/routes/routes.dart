import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trackai/feedback/services/feedback_service.dart';
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

  static const String initialRoute = login;
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _createRoute(const LoginPage());
      case '/signup':
        return _createRoute(const SignupPage());


      case '/onboarding':
        return _createRoute(const OnboardingFlow());
      case '/feedback':
        return _createRoute(const FeedbackScreen());

      case '/home':
        return _createRoute(const HomePage());
      case '/home-screen':
        return _createRoute(const Homescreen());
      case '/tracker-screen':
        return _createRoute(const Trackerscreen());
      case '/analytics-screen':
        return _createRoute(const AnalyticsScreen());
      case '/settings-screen':
        return _createRoute(const Settingsscreen());
      case '/body-analyzer':
        return _createRoute(const BodyCompositionAnalyzer());
      case '/smart-gymkit': // Added slash
        return _createRoute(const Smartgymkit());
      case '/calorie-calculator': // Added slash
        return _createRoute(const CalorieBurnCalculator());
      case '/meal-planner': // Added slash
        return _createRoute(AIMealPlanner());
      case '/recipe-generator': // Added slash
        return _createRoute(const AIRecipeGenerator());
      case '/adjust-goals':
        return _createRoute(const AdjustGoalsPage());
      case '/admin-panel':
        return _createRoute(const AdminPanelScreen());
      case '/announcements':
        return _createRoute(const AnnouncementsPage());

      default:
        return _createRoute(
          Scaffold(
            body: Center(
              child: Text(
                'Route not found: ${settings.name}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        );
    }
  }

  static PageRoute _createRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
