import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(isDarkTheme ? 0.3 : 0.1),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _getWarningCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? Colors.amber[900]!.withOpacity(0.2) : Colors.amber[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? Colors.amber[700]!.withOpacity(0.4) : Colors.amber[500]!.withOpacity(0.4),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(isDarkTheme ? 0.2 : 0.1),
          blurRadius: 6,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Manual date formatting to replace DateFormat
  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkTheme ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // Matches web's ArrowLeftIcon
            color: isDarkTheme ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              Icons.security, // Matches web's ShieldCheckIcon
              color: isDarkTheme ? Colors.white : Colors.black,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Icon(
                  Icons.security, // Matches web's ShieldCheckIcon
                  color: isDarkTheme ? Colors.white : Colors.black,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'TrackAI Privacy Policy',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Last Updated: ${_formatDate(DateTime.now())}',
              style: TextStyle(
                color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),

            // Legal Disclaimer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getWarningCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning, // Matches AdjustGoalsPage's error icon
                        color: AppColors.errorColor,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Legal Disclaimer',
                        style: TextStyle(
                          color: AppColors.errorColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'IMPORTANT: This is a template Privacy Policy and does NOT constitute legal advice. You MUST consult with a qualified legal professional to draft or review your Privacy Policy to ensure it is appropriate for your specific application, its features (including AI), data handling practices (especially regarding health and personal data), and target regions (USA/EU, considering GDPR, CCPA/CPRA, HIPAA if applicable, etc.). This template is for informational and illustrative purposes ONLY and should not be used as-is for a live application.',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Introduction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '1. Introduction',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Welcome to TrackAI ("App", "we", "us", "our"). We are committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application. By using TrackAI, you consent to the data practices described in this policy.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Permissions Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '2. Permissions We Request',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The app only requests permissions when you use specific features that require them:',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Camera Permission
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.camera_alt, // Matches web's CameraIcon
                          color: isDarkTheme ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Camera Permission',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Requested when you use the Food Scanner feature to take a new picture of your meal for nutritional analysis.',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),

                  // Gallery Access
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.photo_library, // Matches web's ImageIcon
                          color: isDarkTheme ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File/Gallery Access',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Requested if you choose to upload an existing photo from your device\'s gallery for the Food Scanner.',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Information Collection Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.data_usage,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '3. Information We Collect and Why',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'TrackAI is designed to be privacy-first. We handle data in two ways: data stored locally on your device, and data processed by third-party services for specific features.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Data Stored Locally
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.storage, // Matches web's DatabaseIcon
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data Stored Locally on Your Device',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'The following information is stored directly in your device\'s local storage. This data is not sent to our servers and remains private to you.',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Profile & Goals
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile & Goals',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Information you provide during onboarding (age, gender, weight, height, goals) and your calculated macro targets. Used to personalize the app, power calculations for BMI and nutrition charts, and tailor AI recommendations.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Tracker Logs
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.track_changes,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tracker Logs',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'All entries for any tracker (e.g., mood ratings, sleep hours, exercise details, custom tracker data). This is the core function of the app, allowing you to track your habits and view your progress in the Analytics section.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // App Preferences
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.settings,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'App Preferences',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your settings, such as favorite trackers, dashboard configuration, and theme choice. Used to customize your experience and remember your settings between visits.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Temporary AI Results
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.memory,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Temporary AI Results & Session Data',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'The app may remember the last result from an AI tool (like a meal plan) for your convenience. The history of "Ask AI" messages is stored only for your current session and is deleted when you close the app. Used to make the app more user-friendly so you can easily refer back to recent information during a session.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Data Processed by Third-Party Services
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.cloud_sync, // Matches web's ServerIcon
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data Processed by Third-Party Services',
                                style: TextStyle(
                                  color: isDarkTheme ? Colors.white : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'To enable certain features, we use secure, trusted third-party services. The information is sent for processing only and is not stored by TrackAI on any server.',
                          style: TextStyle(
                            color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Firebase Authentication
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.security,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Firebase Authentication',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your account information (email, name, securely hashed password, or Google account ID). Used to provide a secure way for you to log in, manage your account, and protect your data. This is handled by Google\'s Firebase platform.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // Google AI
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.memory,
                              color: isDarkTheme ? Colors.white : Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Google AI (via Genkit)',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.white : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'The specific inputs you provide to AI features (e.g., a photo for nutritional analysis, text prompts for meal plans, or questions for the assistant). Used for AI models to analyze your request and generate a tailored response. Your inputs are governed by Google\'s privacy policies.',
                                    style: TextStyle(
                                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Data Storage and Security
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '4. Data Storage and Security',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'As most of your data is stored in your device\'s local storage, its security is tied to your device\'s security. This means:\n\n• Your data is not automatically synced across devices.\n• Clearing your device\'s data for this app will permanently delete your locally stored information.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Your Data Rights
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '5. Your Data Rights (USA/EU Focus)',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Given that data is stored locally on your device, you have direct control over it. This includes:\n\n• Access: You can access your data directly within the App.\n• Modification: You can modify or delete individual log entries (if this functionality is provided by the App).\n• Deletion: You can delete all your data by clearing your device\'s local storage for this App, or using any in-app "delete all data" feature if available.\n\nFor users in the European Union (GDPR) and California (CCPA/CPRA): You have specific rights regarding your data. Since most data is local, you directly control it. For data processed by third-party services like Firebase and Google, their respective privacy policies apply. If you have questions about your data, please contact us, and we will provide information or facilitate as appropriate.\n\nLegal Advice Needed: A legal professional will help you detail these rights accurately.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Children's Privacy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.child_care,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '6. Children\'s Privacy',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'TrackAI is not intended for use by children under the age of 13 (or a higher age if stipulated by local law, e.g., 16 in some EU countries for GDPR consent). We do not knowingly collect personal information from children.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Changes to Privacy Policy
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.update,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '7. Changes to This Privacy Policy',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the App and updating the "Last Updated" date.',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Contact Us
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.contact_mail,
                        color: isDarkTheme ? Colors.white : Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '8. Contact Us',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If you have any questions about this Privacy Policy, please contact us at: privacy@trackai.example.com',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}