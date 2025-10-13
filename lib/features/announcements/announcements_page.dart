import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import '../admin/services/announcement_service.dart';
import '../admin/services/announcement_notification_service.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mark all announcements as seen when page is opened
    AnnouncementNotificationService.markAllAnnouncementsAsSeen();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDarkTheme),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: isDarkTheme ? AppColors.white : AppColors.black,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Latest Updates',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: false,
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: AnnouncementService.getAnnouncementsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      isDarkTheme ? AppColors.white : AppColors.black,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(isDarkTheme);
              }

              final announcements = snapshot.data ?? [];

              // Always show announcements + feedback section
              return _buildAnnouncementsWithFeedback(announcements, isDarkTheme, context);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsWithFeedback(
      List<Map<String, dynamic>> announcements,
      bool isDarkTheme,
      BuildContext context
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Show announcements if available
          if (announcements.isNotEmpty)
            ...announcements.asMap().entries.map((entry) {
              final index = entry.key;
              final announcement = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: _buildAnnouncementCard(
                  context,
                  announcement,
                  isDarkTheme,
                  index,
                ),
              );
            }).toList(),

          // Show empty state card if no announcements
          if (announcements.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(isDarkTheme),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDarkTheme ? AppColors.white.withOpacity(0.1) : AppColors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_outlined,
                      size: 50,
                      color: isDarkTheme ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Coming Soon!',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re working on a dedicated space for app updates. Check back later!',
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

          // Always show feedback section at the bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDarkTheme),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                      Icons.lightbulb_outline,
                      color: isDarkTheme ? AppColors.white : AppColors.black,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Suggest an Improvement',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDarkTheme),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Have an idea for a new feature or an improvement? Let us know!',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/feedback'); // Navigate to feedback screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkTheme ? AppColors.white : AppColors.black,
                    foregroundColor: isDarkTheme ? AppColors.black : AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Suggestion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkTheme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDarkTheme),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Unable to Load Updates',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'re having trouble connecting to our servers. Please check your internet connection and try again.',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context,
      Map<String, dynamic> announcement,
      bool isDarkTheme,
      int index,
      ) {
    final priority = announcement['priority'] ?? 'medium';
    final title = announcement['title'] ?? '';
    final content = announcement['message'] ?? '';
    final createdAt = announcement['createdAt']?.toDate();

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = isDarkTheme ? AppColors.white : AppColors.black;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDarkTheme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: priorityColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
