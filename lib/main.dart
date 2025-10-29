import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:trackai/core/provider/favourite_provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/routes/routes.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/services/auth_services.dart';
import 'package:trackai/core/services/streak_service.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'package:trackai/features/onboarding/plan.dart';
import 'features/home/homepage/log/daily_log_provider.dart';
import 'firebase_options.dart';
import 'package:trackai/core/wrappers/authwrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Firebase once
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  final firebaseApiKeyWeb = dotenv.env['FIREBASE_API_KEY_WEB'];

  // Now other Firebase-dependent services
  await FirebaseService.initializeFirebase();
  await FileDownloadService.requestStoragePermission();
  await StreakService.recordDailyLogin();





  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initializeFirebase();
    await FileDownloadService.requestStoragePermission();
    await StreakService.recordDailyLogin();
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => DailyLogProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TrackAI',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home:
           const AuthWrapper(),
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(themeProvider.isDarkMode),
            ),
            child: ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1200, name: DESKTOP),
                const Breakpoint(start: 1201, end: double.infinity, name: 'XL'),
              ],
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lightPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Allow gradient to show
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary(false)),
        bodyMedium: TextStyle(color: AppColors.textSecondary(false)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Allow gradient to show
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary(true)),
        bodyMedium: TextStyle(color: AppColors.textSecondary(true)),
      ),
    );
  }
}