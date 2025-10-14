import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/recipes/presentation/recipe_library_screen.dart';
import '../../features/analytics/screens/period_cycle.dart';
import '../../features/recipes/presentation/ReadMeWhenFreeScreen.dart';


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
                              'Your personal collection of wellness tools and content.',
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

                  // Second Row - Period Cycle Tracker & Saved Items
                  Row(
                    children: [
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'Period Cycle',
                          'Track your menstrual cycle and health insights.',
                          Icons.favorite_outline,
                          Colors.pink,
                          isDarkTheme,
                          screenWidth,
                          isNew: true, // Add "New" badge
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PeriodCycleScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                    ],
                  ),

                  const SizedBox(height: 16),

                  // Third Row - Read Me When Free (Full Width)
                  _buildLibraryCard(
                    context,
                    'Read Me When Free',
                    'Ancient wisdom and inspiring thoughts for reflection.',
                    Icons.auto_stories,
                    Colors.deepPurple,
                    isDarkTheme,
                    screenWidth,
                    isFullWidth: true,
                    isBeta: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReadMeWhenFreeScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Fourth Row - Health Library (Full Width)
                  _buildLibraryCard(
                    context,
                    'Health & Wellness Hub',
                    'Comprehensive women\'s health resources and guides.',
                    Icons.health_and_safety_outlined,
                    Colors.teal,
                    isDarkTheme,
                    screenWidth,
                    isFullWidth: true,
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
        bool isNew = false,
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
            color: isNew
                ? Colors.pink.withOpacity(0.3)
                : AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
            width: isNew ? 2 : 1,
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
            if (isNew)
              BoxShadow(
                color: Colors.pink.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
                    gradient: isNew
                        ? LinearGradient(colors: [iconColor, iconColor.withOpacity(0.7)])
                        : null,
                    color: !isNew ? iconColor.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: isNew
                        ? [
                      BoxShadow(
                        color: iconColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isNew ? Colors.white : iconColor,
                    size: 24,
                  ),
                ),
                Row(
                  children: [
                    if (isNew)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.pink, Colors.pink.shade400]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
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
