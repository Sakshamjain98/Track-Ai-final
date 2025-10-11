import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/admin/services/announcement_service.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementManagementScreen> createState() => _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState extends State<AnnouncementManagementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedPriority = 'medium';
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createAnnouncement() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isCreating = true);

    try {
      await AnnouncementService.createAnnouncement(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
      );

      _titleController.clear();
      _messageController.clear();
      _selectedPriority = 'medium';

      _showSnackBar('Announcement created successfully!');
    } catch (e) {
      _showSnackBar('Failed to create announcement: $e', isError: true);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorColor : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.background(isDarkTheme),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDarkTheme),
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDarkTheme),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: AppColors.textPrimary(isDarkTheme),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Announcement Management',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundLinearGradient(isDarkTheme),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  children: [
                    // Create Announcement Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardLinearGradient(isDarkTheme),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.1),
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
                                Icons.add_circle_outline,
                                color: AppColors.textPrimary(isDarkTheme),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Create New Announcement',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(isDarkTheme),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Title Field
                          _buildTextField(
                            controller: _titleController,
                            label: 'Title',
                            hint: 'Enter announcement title...',
                            isDarkTheme: isDarkTheme,
                          ),

                          const SizedBox(height: 16),

                          // Priority Selector
                          Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(isDarkTheme),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.black.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              dropdownColor: AppColors.cardBackground(isDarkTheme),
                              style: TextStyle(
                                color: AppColors.textPrimary(isDarkTheme),
                                fontSize: 14,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'high', child: Text('🔴 High Priority')),
                                DropdownMenuItem(value: 'medium', child: Text('🟡 Medium Priority')),
                                DropdownMenuItem(value: 'low', child: Text('🟢 Low Priority')),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedPriority = value!);
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Message Field
                          _buildTextField(
                            controller: _messageController,
                            label: 'Message',
                            hint: 'Enter announcement message...',
                            isDarkTheme: isDarkTheme,
                            maxLines: 4,
                          ),

                          const SizedBox(height: 20),

                          // Create Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCreating ? null : _createAnnouncement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkTheme ? AppColors.white : AppColors.black,
                                foregroundColor: isDarkTheme ? AppColors.black : AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCreating
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: isDarkTheme ? AppColors.black : AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Create Announcement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Announcements List
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardLinearGradient(isDarkTheme),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.black.withOpacity(0.1),
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
                                Icons.list,
                                color: AppColors.textPrimary(isDarkTheme),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'All Announcements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(isDarkTheme),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: AnnouncementService.getAdminAnnouncementsStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.textPrimary(isDarkTheme),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading announcements',
                                      style: TextStyle(
                                        color: AppColors.errorColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                final announcements = snapshot.data ?? [];

                                if (announcements.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.campaign_outlined,
                                          size: 64,
                                          color: AppColors.textSecondary(isDarkTheme),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No announcements yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.textSecondary(isDarkTheme),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: announcements.length,
                                  itemBuilder: (context, index) {
                                    final announcement = announcements[index];
                                    return _buildAnnouncementItem(announcement, isDarkTheme);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDarkTheme,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.black.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.black,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: isDarkTheme
                ? AppColors.black.withOpacity(0.1)
                : AppColors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementItem(Map<String, dynamic> announcement, bool isDarkTheme) {
    final isActive = announcement['isActive'] ?? true;
    final priority = announcement['priority'] ?? 'medium';
    final createdAt = announcement['createdAt'] as Timestamp?;
    final views = announcement['views'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? (isDarkTheme ? AppColors.black.withOpacity(0.3) : AppColors.white.withOpacity(0.8))
            : (isDarkTheme ? AppColors.black.withOpacity(0.1) : AppColors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AnnouncementService.getPriorityIcon(priority),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkTheme),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.successColor : AppColors.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            announcement['message'] ?? 'No message',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDarkTheme),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textSecondary(isDarkTheme),
              ),
              const SizedBox(width: 4),
              Text(
                AnnouncementService.formatTimestamp(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(isDarkTheme),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.visibility,
                size: 14,
                color: AppColors.textSecondary(isDarkTheme),
              ),
              const SizedBox(width: 4),
              Text(
                '$views views',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(isDarkTheme),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _toggleAnnouncementStatus(announcement['id'], !isActive),
                child: Icon(
                  isActive ? Icons.pause_circle : Icons.play_circle,
                  size: 20,
                  color: isActive ? AppColors.errorColor : AppColors.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAnnouncementStatus(String id, bool newStatus) async {
    try {
      await AnnouncementService.updateAnnouncementStatus(id, newStatus);
      _showSnackBar('Announcement ${newStatus ? 'activated' : 'deactivated'}');
    } catch (e) {
      _showSnackBar('Failed to update announcement: $e', isError: true);
    }
  }
}