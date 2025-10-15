import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/provider/favourite_provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/edit_screen.dart';
import 'package:trackai/features/tracker/tracker_screens/MentalWellbeingTrackerScreen.dart';
import 'package:trackai/features/tracker/tracker_screens/WeightTrackerScreen.dart';
import 'package:trackai/features/tracker/tracker_screens/WorkoutTrackerScreen.dart';
import 'package:trackai/features/tracker/tracker_screens/expense_saving_alcohol_money_etc.dart';
import 'package:trackai/features/tracker/tracker_screens/alcohol_mental_etc.dart';
import 'package:trackai/features/tracker/tracker_screens/meditation.dart';
import 'package:trackai/features/tracker/tracker_screens/mood_tracker.dart';
import 'package:trackai/features/tracker/tracker_screens/sleep_tracker.dart';

class Trackerscreen extends StatefulWidget {
  const Trackerscreen({Key? key}) : super(key: key);

  @override
  State<Trackerscreen> createState() => _TrackerscreenState();
}

class _TrackerscreenState extends State<Trackerscreen> {
  bool showFavoritesOnly = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Tracker-specific icons and colors
  final List<TrackerItem> allTrackers = [
    TrackerItem(
      id: 'sleep',
      title: 'Sleep Tracker',
      description: 'Track your sleep duration and quality.',
      unit: 'hours',
      icon: Icons.bedtime,
      color: const Color(0xFF26A69A),
      screen: SleepTrackerScreen(),
    ),
    TrackerItem(
      id: 'mood',
      title: 'Mood Tracker',
      description: 'Log your daily mood and notes.',
      unit: '1-10 scale',
      icon: Icons.sentiment_satisfied,
      color: const Color(0xFF26A69A),
      screen: MoodTrackerScreen(),
    ),
    TrackerItem(
      id: 'meditation',
      title: 'Meditation Tracker',
      description: 'Log your meditation sessions and duration.',
      unit: 'minutes',
      icon: Icons.self_improvement,
      color: const Color(0xFF26A69A),
      screen: MeditationTrackerScreen(),
    ),
    TrackerItem(
      id: 'expense',
      title: 'Expense Tracker',
      description: 'Monitor your spending and budget.',
      unit: 'currency',
      icon: Icons.attach_money,
      color: const Color(0xFF26A69A),
      screen: ExpenseTrackerScreen(),
    ),
    TrackerItem(
      id: 'savings',
      title: 'Savings Tracker',
      description: 'Keep track of your savings goals.',
      unit: 'currency',
      icon: Icons.savings,
      color: const Color(0xFF26A69A),
      screen: SavingsTrackerScreen(),
    ),
    TrackerItem(
      id: 'alcohol',
      title: 'Alcohol Tracker',
      description: 'Track your alcohol consumption.',
      unit: 'drinks',
      icon: Icons.local_drink,
      color: const Color(0xFF26A69A),
      screen: AlcoholTrackerScreen(),
    ),
    TrackerItem(
      id: 'study',
      title: 'Study Time Tracker',
      description: 'Log your study sessions and focus periods.',
      unit: 'hours',
      icon: Icons.book,
      color: const Color(0xFF26A69A),
      screen: StudyTrackerScreen(),
    ),
    TrackerItem(
      id: 'mental_wellbeing',
      title: 'Mental Well-being Tracker',
      description: 'Reflect on your mental state and well-being.',
      unit: '1-5 scale',
      icon: Icons.favorite,
      color: const Color(0xFF26A69A),
      screen: MentalWellbeingTrackerScreen(),
    ),
    TrackerItem(
      id: 'workout',
      title: 'Workout Tracker',
      description: 'Log your workouts, sets, reps, and duration.',
      unit: 'details',
      icon: Icons.fitness_center,
      color: const Color(0xFF26A69A),
      screen: WorkoutTrackerScreen(),
    ),
    TrackerItem(
      id: 'weight',
      title: 'Weight Tracker',
      description: 'Monitor your body weight.',
      unit: 'kg / lbs',
      icon: Icons.scale,
      color: const Color(0xFF26A69A),
      screen: WeightTrackerScreen(),
    ),
    TrackerItem(
      id: 'menstrual',
      title: 'Menstrual Cycle',
      description: 'Log your period start date to predict the next one.',
      unit: 'date',
      icon: Icons.water_drop,
      color: const Color(0xFF26A69A),
      screen: MenstrualTrackerScreen(),
    ),
  ];

  List<TrackerItem> getFilteredTrackers(Set<String> favoriteTrackers) {
    List<TrackerItem> filtered = allTrackers;

    if (showFavoritesOnly) {
      filtered = filtered
          .where((tracker) => favoriteTrackers.contains(tracker.id))
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (tracker) =>
        tracker.title.toLowerCase().contains(
          searchQuery.toLowerCase(),
        ) ||
            tracker.description.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
      )
          .toList();
    }

    return filtered;
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.black,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 12,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, FavoritesProvider>(
      builder: (context, themeProvider, favoritesProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final favoriteTrackers = favoritesProvider.favoriteTrackers;
        final filteredTrackers = getFilteredTrackers(favoriteTrackers);
        final favoritesCount = favoritesProvider.favoritesCount;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDark),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Text(
                  'Your Trackers (${filteredTrackers.length})',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          showFavoritesOnly = !showFavoritesOnly;
                        });
                        HapticFeedback.lightImpact();
                      },
                      icon: Icon(
                        showFavoritesOnly
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.black,
                        size: 26,
                      ),
                      tooltip: showFavoritesOnly
                          ? 'Show All Trackers'
                          : 'Show Favorites Only',
                    ),
                    if (favoritesCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$favoritesCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.black,
                ),
                onSelected: (value) {
                  if (value == 'create_custom') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Create Custom Tracker feature coming soon!',
                        ),
                        backgroundColor: AppColors.black,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else if (value == 'clear_favorites') {
                    _showClearFavoritesDialog(
                      context,
                      favoritesProvider,
                      isDark,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'create_custom',
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create Custom Tracker',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (favoritesCount > 0)
                    PopupMenuItem(
                      value: 'clear_favorites',
                      child: Row(
                        children: [
                          Icon(
                            Icons.clear_all_rounded,
                            color: Colors.red.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Clear All Favorites',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                color: AppColors.inputFill(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardLinearGradient(isDark),
            ),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search all trackers...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.black,
                        size: 22,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.black,
                        ),
                      )
                          : null,
                      filled: true,
                      fillColor: AppColors.inputFill(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.black,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.black,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.black,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 16,
                    ),
                  ),
                ),

                // Trackers List
                Expanded(
                  child: filteredTrackers.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill(isDark),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            showFavoritesOnly
                                ? Icons.star_outline_rounded
                                : Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          showFavoritesOnly
                              ? 'No favorite trackers yet'
                              : 'No trackers found',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          showFavoritesOnly
                              ? 'Star some trackers to see them here'
                              : 'Try adjusting your search query',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredTrackers.length,
                    itemBuilder: (context, index) {
                      final tracker = filteredTrackers[index];
                      final isFavorite = favoritesProvider.isFavorite(
                        tracker.id,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: _getCardDecoration(isDark),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => tracker.screen,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputFill(isDark),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        tracker.icon,
                                        color: tracker.color,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tracker.title,
                                            style: TextStyle(
                                              color:
                                              AppColors.textPrimary(
                                                isDark,
                                              ),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Unit: ${tracker.unit}',
                                            style: TextStyle(
                                              color:
                                              AppColors.textSecondary(
                                                isDark,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        favoritesProvider.toggleFavorite(
                                          tracker.id,
                                        );
                                        HapticFeedback.lightImpact();
                                      },
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Icon(
                                          isFavorite
                                              ? Icons.star_rounded
                                              : Icons
                                              .star_outline_rounded,
                                          key: ValueKey(isFavorite),
                                          color: AppColors.black,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tracker.description,
                                  style: TextStyle(
                                    color: AppColors.textSecondary(
                                      isDark,
                                    ),
                                    fontSize: 15,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                              tracker.screen,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Log Data',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.black,
                                          foregroundColor: AppColors.black,
                                          padding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditLogsScreen(
                                                    trackerId: tracker.id,
                                                    trackerTitle:
                                                    tracker.title,
                                                    trackerColor:
                                                    AppColors.black,
                                                    trackerIcon:
                                                    tracker.icon,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.edit_rounded,
                                          color: AppColors.black,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: AppColors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          AppColors.inputFill(isDark),
                                          foregroundColor: AppColors.black,
                                          padding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: AppColors.black,
                                              width: 1,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show dialog to confirm clearing all favorites
  void _showClearFavoritesDialog(
      BuildContext context,
      FavoritesProvider favoritesProvider,
      bool isDark,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.inputFill(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Favorites?',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will remove all trackers from your favorites list. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              favoritesProvider.clearAllFavorites();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All favorites cleared'),
                  backgroundColor: AppColors.black,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class TrackerItem {
  final String id;
  final String title;
  final String description;
  final String unit;
  final IconData icon;
  final Color color;
  final Widget screen;

  TrackerItem({
    required this.id,
    required this.title,
    required this.description,
    required this.unit,
    required this.icon,
    required this.color,
    required this.screen,
  });
}