import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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

  BoxDecoration _getHealthDisclaimerDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? Colors.green[900]!.withOpacity(0.3) : Colors.green[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDarkTheme ? Colors.green[700]!.withOpacity(0.5) : Colors.green[500]!.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(isDarkTheme ? 0.2 : 0.1),
          blurRadius: 6,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Manual date formatting to avoid intl dependency
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
            color: AppColors.textPrimary(isDarkTheme),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(
              Icons.description, // Matches web's FileTextIcon
              color: AppColors.textPrimary(isDarkTheme),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Terms of Service',
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
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
                  Icons.description, // Matches web's FileTextIcon
                  color: AppColors.textPrimary(isDarkTheme),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'TrackAI Terms of Service',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDarkTheme),
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
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),

            // Legal Disclaimer
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
                        Icons.warning,
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
                    'IMPORTANT: This is a template Terms of Service and does NOT constitute legal advice. You MUST consult with a qualified legal professional to draft or review your Terms of Service to ensure they are appropriate for your specific application, its features (including AI), data handling practices, and target regions (USA/EU). This template is for informational and illustrative purposes ONLY and should not be used as-is for a live application.',
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

            // Health Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _getHealthDisclaimerDecoration(isDarkTheme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        color: isDarkTheme ? Colors.green[300] : Colors.green[800],
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Health Disclaimer',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.green[300] : Colors.green[800],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'IMPORTANT: The information and suggestions provided by the AI features, and by TrackAI in general, are for informational and educational purposes only. TrackAI is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition or health objectives. Reliance on any information provided by TrackAI is solely at your own risk.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
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
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '1. Introduction',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Welcome to TrackAI ("App", "we", "us", "our"), your personal AI-powered wellness companion. These Terms of Service ("Terms") govern your access to and use of our application and related services (collectively, the "Service"). By accessing or using TrackAI, you agree to be bound by these Terms. If you disagree with any part of the terms, then you may not access the Service.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Acceptance of Terms
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
                        Icons.check_circle,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '2. Acceptance of Terms',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'By downloading, accessing, or using the TrackAI application, you signify your agreement to these Terms. If you do not agree to these Terms, you may not use the App. We reserve the right to modify these Terms at any time. Your continued use of the App after such changes constitutes your acceptance of the new Terms.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Use of the Service
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
                        Icons.app_settings_alt,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '3. Use of the Service',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'TrackAI provides tools for tracking wellness-related data, AI-driven insights, and other features related to health and well-being. You are granted a non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes, subject to these Terms.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You agree not to:',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Use the App for any illegal purpose or in violation of any local, state, national, or international law.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Violate or encourage others to violate the rights of third parties, including intellectual property rights.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Use the App to generate content that is harmful, fraudulent, deceptive, threatening, harassing, defamatory, obscene, or otherwise objectionable.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Attempt to decompile, reverse engineer, or otherwise attempt to discover the source code of the App.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // AI-Powered Features & Disclaimers
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
                        Icons.memory,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '4. AI-Powered Features & Disclaimers',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'TrackAI utilizes artificial intelligence to provide features such as meal planning, workout suggestions, and nutritional analysis from images. You acknowledge that AI-generated content may sometimes be inaccurate or incomplete. Use your judgment and verify critical information when necessary.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Data, Privacy, and Permissions
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
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '5. Data, Privacy, and Permissions',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your privacy is paramount. TrackAI is designed to be privacy-first by storing most of your data—including your profile, goals, and tracker logs—locally on your device using your device\'s storage. This data is not sent to our servers.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Certain features require interaction with third-party services or device permissions:',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Authentication: To secure your account, we use Firebase Authentication (a Google service). Your login credentials are managed by Firebase.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'AI Features: To provide intelligent features, your inputs (e.g., a photo of a meal, your fitness goals) are sent for processing by Google\'s AI models.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDarkTheme),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Permissions: The app will ask for Camera and/or Gallery access only when you use features that require it, such as the Food Scanner.',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'For a complete and detailed explanation of what data is collected and why, please read our Privacy Policy. By using the Service, you agree to the data practices outlined in our Privacy Policy.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Intellectual Property
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
                        Icons.copyright,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '6. Intellectual Property',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'The TrackAI application, including its "look and feel", underlying software, and proprietary content are owned by TrackAI or its licensors and are protected by intellectual property laws.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Disclaimers of Warranties
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
                        Icons.warning,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '7. Disclaimers of Warranties',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'THE SERVICE IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS. TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, TRACKAI DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Limitation of Liability
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
                        Icons.security,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '8. Limitation of Liability',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL TRACKAI BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Governing Law
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
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '9. Governing Law',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'These Terms shall be governed by the laws of [Specify Jurisdiction, e.g., "the State of Delaware, USA"].',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Legal Advice Needed: You MUST consult with a legal professional to determine the appropriate governing law and dispute resolution clauses.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Termination
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
                        Icons.cancel,
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '10. Termination',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We may terminate or suspend your access to the Service immediately, without prior notice or liability, if you breach these Terms.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Changes to Terms
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
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '11. Changes to Terms',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'We reserve the right to modify or replace these Terms at any time.',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
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
                        color: AppColors.textPrimary(isDarkTheme),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '12. Contact Us',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If you have any questions about these Terms, please contact us at: terms@trackai.example.com',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
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