import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';

class OnboardingCompletionPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingCompletionPage({
    Key? key,
    required this.onComplete,
    required this.onBack,
  }) : super(key: key);

  @override
  State<OnboardingCompletionPage> createState() =>
      _OnboardingCompletionPageState();
}

class _OnboardingCompletionPageState extends State<OnboardingCompletionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white, // ✅ white background
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black, // ✅ black arrow
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        'How TrackAI Works',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // ✅ black text
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Here\'s how we help you succeed.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600], // ✅ grey text
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildFeatureItem(
                        'G',
                        'Powered by Google AI',
                        'Built on Google\'s most advanced APIs for reliable and smart tracking.',
                        Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureItem(
                        '⚡',
                        'Smarter Progress Insights',
                        'AI-driven tracking to help you improve habits, health, and productivity.',
                        Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      _buildFeatureItem(
                        '🔒',
                        'Secure & Private',
                        'Your data is encrypted and stays 100% in your control.',
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black,
                ),
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    'Start My Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    String emoji,
    String title,
    String description,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: emoji == 'G'
                  ? Text(
                      'G',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    )
                  : Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
