import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/recipes/presentation/recipe_library_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.withOpacity(0.15),
                              Colors.blue.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.library_books,
                          color: Colors.teal,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Library',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDarkTheme),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your personal collection of saved plans and content.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // First Row - Recipe Library & Workouts Library
                  Row(
                    children: [
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'Recipe Library',
                          'Browse delicious cooking guides and recipes.',
                          Icons.restaurant_menu_outlined,
                          Colors.orange,
                          isDarkTheme,
                          screenWidth,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RecipeLibraryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'Workouts Library',
                          'Access workout guide videos. Coming soon!',
                          Icons.fitness_center_outlined,
                          Colors.blue,
                          isDarkTheme,
                          screenWidth,
                          onTap: () => _showComingSoon(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Second Row - WH Library & Saved Items
                  Row(
                    children: [
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'WH Library',
                          'Track your cycle and explore women\'s health topics.',
                          Icons.favorite_outline,
                          Colors.pink,
                          isDarkTheme,
                          screenWidth,
                          onTap: () => _showComingSoon(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'Saved Items',
                          'View your saved meal and workout plans.',
                          Icons.bookmark_outline,
                          Colors.purple,
                          isDarkTheme,
                          screenWidth,
                          onTap: () => _showComingSoon(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Third Row - Read Me When (Full Width)
                  _buildLibraryCard(
                    context,
                    'Read Me When',
                    'Notes for when you\'re feeling a certain way.',
                    Icons.psychology_outlined,
                    Colors.green,
                    isDarkTheme,
                    screenWidth,
                    isFullWidth: true,
                    isBeta: true,
                    onTap: () => _showComingSoon(context),
                  ),

                  const SizedBox(height: 32),

                  // Coming Soon Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cardBackground(isDarkTheme),
                          AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.15),
                                Colors.orange.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.amber[700],
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'More Features Coming Soon!',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDarkTheme),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We\'re working hard to bring you more personalized content, guided workouts, and wellness resources. Stay tuned!',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLibraryCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color iconColor,
      bool isDarkTheme,
      double screenWidth, {
        bool isFullWidth = false,
        bool isBeta = false,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cardBackground(isDarkTheme),
              AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: isDarkTheme
                  ? Colors.white.withOpacity(0.02)
                  : Colors.white.withOpacity(0.7),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                if (isBeta)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Beta',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Coming soon! Stay tuned for updates.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
