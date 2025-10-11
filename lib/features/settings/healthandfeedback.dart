import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';

class HealthFeedbackPage extends StatefulWidget {
  @override
  _HealthFeedbackPageState createState() => _HealthFeedbackPageState();
}

class _HealthFeedbackPageState extends State<HealthFeedbackPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  bool isReportSent = false;
  AnimationController? animationController;
  Animation<double>? slideAnimation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    animationController?.dispose();
    emailController.dispose();
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.black,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _getSubmitCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      gradient: AppColors.cardLinearGradient(isDarkTheme),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.black,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _submitFeedback() {
    setState(() {
      isReportSent = true;
    });
    animationController?.forward();

    // Hide the success bar after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        animationController?.reverse().then((_) {
          setState(() {
            isReportSent = false;
          });
        });
      }
    });

    // Clear form
    emailController.clear();
    subjectController.clear();
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkTheme),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardLinearGradient(isDarkTheme),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDarkTheme),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health & Feedback',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FAQ Section
                Container(
                  width: double.infinity,
                  decoration: _getCardDecoration(isDarkTheme),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: AppColors.black,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkTheme),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildFAQItem(
                        'How do I log data for a tracker?',
                        'Navigate to the \'Trackers\' page from the main menu. Find the tracker you wish to log data for and click the \'Log Data\' button. A dialog will appear prompting you to enter the relevant information.',
                        isDarkTheme,
                      ),
                      SizedBox(height: 16),
                      _buildFAQItem(
                        'How can I customize my dashboard on the Analytics page?',
                        'Go to the \'Analytics\' page. Click on the \'Configure Dashboard Charts\' button at the top. You can then select up to 4 trackers to display as charts on your analytics dashboard.',
                        isDarkTheme,
                      ),
                      SizedBox(height: 16),
                      _buildFAQItem(
                        'Where is my data stored?',
                        'Currently, all your tracker logs, preferences, and dashboard configurations are stored locally in your web browser\'s storage. This means the data is specific to the browser and device you are using.',
                        isDarkTheme,
                      ),
                      SizedBox(height: 16),
                      _buildFAQItem(
                        'How do the AI Lab tools work?',
                        'The AI Lab features use generative AI models to provide assistance. For example, the \'Image to Text\' tool can analyze medical photos, while others can help generate meal plans or workout routines based on your input.',
                        isDarkTheme,
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill(isDarkTheme),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.black,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              color: AppColors.black,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Explore AI Lab Features',
                                style: TextStyle(
                                  color: AppColors.textPrimary(isDarkTheme),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.open_in_new,
                              color: AppColors.black,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Submit Feedback Section
                Container(
                  width: double.infinity,
                  decoration: _getSubmitCardDecoration(isDarkTheme),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            color: AppColors.black,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDarkTheme),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'We value your input! Let us know how we can improve TrackAI.',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDarkTheme),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Email Field
                      Text(
                        'Your Email (Optional)',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                        ),
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(isDarkTheme),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Subject Field
                      Text(
                        'Subject',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: subjectController,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                        ),
                        decoration: InputDecoration(
                          hintText: 'E.g., Suggestion for new tracker',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(isDarkTheme),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Message Field
                      Text(
                        'Message',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        maxLines: 5,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tell us your thoughts...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(isDarkTheme),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.textPrimary(isDarkTheme),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Submit Feedback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100), // Extra space for the success bar
              ],
            ),
          ),

          // Success Bar
          if (isReportSent)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: slideAnimation!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, slideAnimation!.value * 100),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent(isDarkTheme),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.black,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.black,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Report sent successfully!',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDarkTheme),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isDarkTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        SizedBox(height: 6),
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary(isDarkTheme),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}