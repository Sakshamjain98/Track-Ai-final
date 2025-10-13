import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/auth/views/login_page.dart';
import 'package:trackai/features/admin/announcement_management_screen.dart';
import 'package:trackai/features/recipes/presentation/recipe_management_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;
        final user = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDarkTheme),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.textPrimary(isDarkTheme),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _signOut(context),
                icon: Icon(
                  Icons.logout,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDarkTheme),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Admin Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary(isDarkTheme).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary(isDarkTheme),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: AppColors.primary(isDarkTheme),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Welcome Message
                    Text(
                      'This is Admin Panel',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkTheme),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Admin Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardLinearGradient(isDarkTheme),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary(isDarkTheme).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user,
                                color: AppColors.primary(isDarkTheme),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Administrator Access',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(isDarkTheme),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildInfoRow(
                            'Logged in as:',
                            user?.email ?? 'admin1@gmail.com',
                            isDarkTheme,
                          ),

                          const SizedBox(height: 8),

                          _buildInfoRow(
                            'User ID:',
                            user?.uid ?? 'offline-admin',
                            isDarkTheme,
                          ),

                          const SizedBox(height: 8),

                          _buildInfoRow(
                            'Role:',
                            'Administrator',
                            isDarkTheme,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnnouncementManagementScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.campaign,
                              color: AppColors.white,
                            ),
                            label: Text(
                              'Announcements',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkTheme ? AppColors.white : AppColors.black,
                              foregroundColor: isDarkTheme ? AppColors.black : AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RecipeManagementScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.restaurant_menu,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Recipes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Add user management functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('User management coming soon!'),
                                  backgroundColor: isDarkTheme ? AppColors.white : AppColors.black,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.people,
                              color: isDarkTheme ? AppColors.white : AppColors.black,
                            ),
                            label: Text(
                              'Users',
                              style: TextStyle(
                                color: isDarkTheme ? AppColors.white : AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDarkTheme ? AppColors.white : AppColors.black,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Analytics coming soon!'),
                                  backgroundColor: isDarkTheme ? AppColors.white : AppColors.black,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.analytics,
                              color: isDarkTheme ? AppColors.white : AppColors.black,
                            ),
                            label: Text(
                              'Analytics',
                              style: TextStyle(
                                color: isDarkTheme ? AppColors.white : AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isDarkTheme ? AppColors.white : AppColors.black,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkTheme),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary(isDarkTheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Check if user is actually logged in via Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseAuth.instance.signOut();
      }
      
      // Navigate back to login page for both Firebase and offline admin
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
}