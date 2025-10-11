import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color darkPrimary = Color(0xFF1C1C1C); // Dark gray
  static const Color darkSecondary = Color(0xFF121212); 
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkAccent = Color(0xFF444444);
  static const Color darkCardBackground = Color(0xFF1A1A1A);
  static const Color darkSurfaceColor = Color(0xFF222222);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  static const Color lightPrimary = Color(0xFFF5F5F5); // Light gray
  static const Color lightSecondary = Color(0xFFE0E0E0);
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFB0B0B0);
  static const Color lightCardBackground = Color(0xFFF8F8F8);
  static const Color lightSurfaceColor = Color(0xFFEFEFEF);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color darkGrey = Color(0xFF2C2C2C);
  static const Color lightGrey = Color(0xFFB0B0B0);
  static const Color errorColor = Color(0xFFFF6B6B); // keep red for errors
  static const Color successColor = Color(0xFF4CAF50); // optional green for success
  static const Color warningColor = Color(0xFFFFB347); // optional amber

  // Dynamic Colors
  static Color primary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color secondary(bool isDark) => isDark ? darkSecondary : lightSecondary;
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color accent(bool isDark) => isDark ? darkAccent : lightAccent;
  static Color cardBackground(bool isDark) => isDark ? darkCardBackground : lightCardBackground;
  static Color surfaceColor(bool isDark) => isDark ? darkSurfaceColor : lightSurfaceColor;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textDisabled(bool isDark) => isDark ? Color(0xFF707070) : Color(0xFFB0B0B0);

  // Gradients
  static const List<Color> darkPrimaryGradient = [
    Color(0xFF1C1C1C),
    Color(0xFF2C2C2C),
  ];

  static const List<Color> darkBackgroundGradient = [
    Color(0xFF000000),
    Color(0xFF1A1A1A),
  ];

  static const List<Color> darkCardGradient = [
    Color(0xFF222222),
    Color(0xFF121212),
  ];

  static const List<Color> darkAccentGradient = [
    Color(0xFF333333),
    Color(0xFF555555),
  ];

  static const List<Color> lightPrimaryGradient = [
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
  ];

  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF8F8F8),
  ];

  static const List<Color> lightCardGradient = [
    Color(0xFFF8F8F8),
    Color(0xFFFFFFFF),
  ];

  static const List<Color> lightAccentGradient = [
    Color(0xFFB0B0B0),
    Color(0xFFD0D0D0),
  ];

  static List<Color> primaryGradient(bool isDark) =>
      isDark ? darkPrimaryGradient : lightPrimaryGradient;
  static List<Color> backgroundGradient(bool isDark) =>
      isDark ? darkBackgroundGradient : lightBackgroundGradient;
  static List<Color> cardGradient(bool isDark) =>
      isDark ? darkCardGradient : lightCardGradient;
  static List<Color> accentGradient(bool isDark) =>
      isDark ? darkAccentGradient : lightAccentGradient;

  static LinearGradient primaryLinearGradient(bool isDark) => LinearGradient(
    colors: primaryGradient(isDark),
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundLinearGradient(bool isDark) => LinearGradient(
    colors: backgroundGradient(isDark),
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardLinearGradient(bool isDark) => LinearGradient(
    colors: cardGradient(isDark),
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient accentLinearGradient(bool isDark) => LinearGradient(
    colors: accentGradient(isDark),
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF333333), Color(0xFF555555)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Color shimmerBase(bool isDark) =>
      isDark ? Color(0xFF222222) : Color(0xFFE0E0E0);
  static Color shimmerHighlight(bool isDark) =>
      isDark ? Color(0xFF444444) : Color(0xFFF5F5F5);

  static const Color bottomNavSelected = Color(0xFF555555);
  static Color bottomNavUnselected(bool isDark) =>
      isDark ? Color(0xFF999999) : Color(0xFFB0B0B0);

  static Color inputFill(bool isDark) =>
      isDark ? Color(0xFF222222) : Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFF555555);
  static const Color inputFocusedBorder = Color(0xFF777777);
  static Color accentPrimary(bool isDark) => isDark ? Colors.blueAccent.shade100 : Colors.blueAccent;
  static Color accentSecondary(bool isDark) => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  static Color borderColor(bool isDark) => isDark ? Colors.grey.shade700 : Colors.grey.shade300;
}
