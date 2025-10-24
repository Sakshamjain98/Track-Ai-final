import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart'; // Assuming AppColors handles basic black/white based on theme
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/recipes/presentation/recipe_library_screen.dart';
import '../../features/analytics/screens/WhLib/period_cycle.dart';
import '../../features/recipes/presentation/ReadMeWhenFreeScreen.dart';


class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Use simple black/white based on theme
        final bool isDarkTheme = themeProvider.isDarkMode;
        final Color backgroundColor = isDarkTheme ? Colors.black : Colors.white;
        final Color primaryTextColor = isDarkTheme ? Colors.white : Colors.black;
        final Color secondaryTextColor = isDarkTheme ? Colors.grey[400]! : Colors.grey[600]!;
        final Color cardBackgroundColor = isDarkTheme ? Colors.grey[900]! : Colors.grey[100]!;
        final Color borderColor = isDarkTheme ? Colors.grey[700]! : Colors.grey[300]!;
        final Color iconContainerColor = isDarkTheme ? Colors.grey[800]! : Colors.grey[200]!;
        final Color iconColor = isDarkTheme ? Colors.white70 : Colors.black87;


        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: backgroundColor,
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
                          color: iconContainerColor, // Simple background
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.library_books,
                          color: primaryTextColor, // Black/White icon
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
                                color: primaryTextColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            // REMOVED: "Your personal collection..." text
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // First Row - Recipe Library & Workouts Library
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align tops
                    children: [
                      Expanded(
                        child: _buildLibraryCard(
                          context,
                          'Recipe Library',
                          'Browse delicious cooking guides and recipes.',
                          Icons.restaurant_menu_outlined,
                          primaryTextColor, // Use primary text color for icon
                          isDarkTheme,
                          cardBackgroundColor,
                          borderColor,
                          primaryTextColor,
                          secondaryTextColor,
                          iconContainerColor,
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
                          'Access workout guide videos.',
                          Icons.fitness_center_outlined,
                          primaryTextColor, // Use primary text color for icon
                          isDarkTheme,
                          cardBackgroundColor,
                          borderColor,
                          primaryTextColor,
                          secondaryTextColor,
                          iconContainerColor,
                          onTap: () => _showComingSoon(context, isDarkTheme),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // MODIFIED: Second Row is now just the full-width Period Cycle card
                  _buildLibraryCard(
                    context,
                    'Period Cycle',
                    'Track your menstrual cycle and health insights.',
                    Icons.favorite_outline,
                    primaryTextColor, // This is the default icon color
                    isDarkTheme,
                    cardBackgroundColor,
                    borderColor,
                    primaryTextColor,
                    secondaryTextColor,
                    iconContainerColor,
                    isNew: true, // This will now trigger the NEW pink styling
                    isFullWidth: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PeriodDashboard(),
                        ),
                      );
                    },
                  ),

                  // REMOVED: "Read Me When Free" Card

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET MODIFIED ---
  // This function now includes the 'isNew' styling from your first file
  Widget _buildLibraryCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color iconColor, // Pass the decided icon color (black/white)
      bool isDarkTheme,
      Color cardBackgroundColor,
      Color borderColor,
      Color primaryTextColor,
      Color secondaryTextColor,
      Color iconContainerColor,
      {
        bool isFullWidth = false,
        bool isBeta = false,
        bool isNew = false,
        required VoidCallback onTap,
      }) {

    // Define badge colors based on theme
    final Color badgeBgColor = isDarkTheme ? Colors.white : Colors.black;
    final Color badgeTextColor = isDarkTheme ? Colors.black : Colors.white;
    final Color betaBadgeBgColor = isDarkTheme ? Colors.grey[800]! : Colors.grey[300]!;
    final Color betaBadgeTextColor = isDarkTheme ? Colors.grey[400]! : Colors.grey[700]!;

    // The "New" border color is now pink
    final Color newBorderColor = isDarkTheme ? Colors.pinkAccent[100]! : Colors.pinkAccent;


    // --- NEW LOGIC from your first file ---
    // Define final colors/decorations based on 'isNew'
    final Color finalIconColor;
    final Decoration finalIconContainerDecoration;
    final Decoration finalNewBadgeDecoration;

    if (isNew) {
      finalIconColor = Colors.white; // Icon is white on pink bg
      finalIconContainerDecoration = BoxDecoration(
        gradient: LinearGradient( // Pink gradient bg for icon
          colors: [Colors.pink, Colors.pink.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.pink.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );
      finalNewBadgeDecoration = BoxDecoration( // Pink gradient bg for badge
        gradient: LinearGradient(colors: [Colors.pink, Colors.pink.shade400]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else {
      finalIconColor = iconColor; // Use the passed (black/white) color
      finalIconContainerDecoration = BoxDecoration(
        color: iconContainerColor, // Use the passed (grey) color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      );
      finalNewBadgeDecoration = BoxDecoration(
        color: badgeBgColor, // Black/White badge
        borderRadius: BorderRadius.circular(12),
      );
    }
    // --- END NEW LOGIC ---


    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBackgroundColor, // Simple background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Will use newBorderColor (pink) if isNew is true
            color: isNew ? newBorderColor : borderColor,
            width: isNew ? 1.5 : 1, // Slightly thicker border if new
          ),
          // Simplified shadow + new pink shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (isNew) // Add pink glow from your first file
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: finalIconContainerDecoration, // <-- USE NEW DECORATION
                  child: Icon(
                    icon,
                    color: finalIconColor, // <-- USE NEW COLOR
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
                        decoration: finalNewBadgeDecoration, // <-- USE NEW DECORATION
                        child: Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white, // <-- Text on pink is white
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
                          color: betaBadgeBgColor, // Greyish beta badge
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Beta',
                          style: TextStyle(
                            color: betaBadgeTextColor,
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
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, bool isDarkTheme) {
    final Color snackBarBg = isDarkTheme ? Colors.grey[800]! : Colors.grey[900]!;
    final Color snackBarText = Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline, // Changed icon
              color: snackBarText.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded( // Ensure text wraps
              child: Text(
                'Coming soon! Stay tuned for updates.',
                style: TextStyle(
                  color: snackBarText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: snackBarBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16), // Add margin
        duration: const Duration(seconds: 2),
      ),
    );
  }
}