import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trackai/core/services/auth_services.dart';
import 'package:trackai/features/home/homepage/homepage.dart';
import 'package:trackai/features/auth/views/login_page.dart';
import 'package:trackai/features/onboarding/service/observices.dart';
import 'package:trackai/features/onboarding/onboardingflow.dart';
import 'package:trackai/features/admin/services/admin_service.dart';
import 'package:trackai/features/admin/admin_panel_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper: StreamBuilder rebuilding...');
        print('AuthWrapper: Connection state: ${snapshot.connectionState}');
        print('AuthWrapper: Has data: ${snapshot.hasData}');
        print('AuthWrapper: User: ${snapshot.data?.email}');

        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // User is not authenticated
        if (user == null) {
          print('AuthWrapper: User is not authenticated, showing LoginPage');
          return const LoginPage();
        }

        // User is authenticated
        print('AuthWrapper: User is authenticated, checking onboarding status');
        print('AuthWrapper: User email: ${user.email}');
        print('AuthWrapper: User UID: ${user.uid}');

        // Check if user is admin first
        if (AdminService.isAdminEmail(user.email)) {
          print('AuthWrapper: Admin user detected, showing AdminPanelScreen');
          return const AdminPanelScreen();
        }

        // Check onboarding status for authenticated users using stream
        return StreamBuilder<bool>(
          stream: OnboardingService.onboardingCompletionStream(),
          builder: (context, onboardingSnapshot) {
            print(
              'AuthWrapper: Onboarding stream - Connection state: ${onboardingSnapshot.connectionState}',
            );
            print(
              'AuthWrapper: Onboarding completed: ${onboardingSnapshot.data}',
            );

            // Show loading while checking onboarding status
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasCompletedOnboarding = onboardingSnapshot.data ?? false;

            if (!hasCompletedOnboarding) {
              print(
                'AuthWrapper: User has not completed onboarding, showing OnboardingFlow',
              );
              return const OnboardingFlow();
            }

            print(
              'AuthWrapper: User has completed onboarding, showing HomePage',
            );
            return const HomePage();
          },
        );
      },
    );
  }
}
