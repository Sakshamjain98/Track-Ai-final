import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:trackai/core/constants/appcolors.dart';

class TargetAnalysisPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final double targetAmount;
  final String targetUnit;
  final int targetTimeframe;
  final String goal;

  const TargetAnalysisPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.targetAmount,
    required this.targetUnit,
    required this.targetTimeframe,
    required this.goal,
  }) : super(key: key);

  @override
  State<TargetAnalysisPage> createState() => _TargetAnalysisPageState();
}

class _TargetAnalysisPageState extends State<TargetAnalysisPage> {
  String _analysisText = "";
  String _recommendationText = "";
  bool _isLoading = true;
  bool _errorOccurred = false;

  @override
  void initState() {
    super.initState();
    _generateAnalysis();
  }

  Future<void> _generateAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorOccurred = false;
    });



    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      print('Loaded API Key: $apiKey'); // Debug
      if (apiKey.isEmpty) {
        throw Exception('API key not found in .env file');
      }

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      String goalType = widget.goal == 'gain_weight' ? 'gain' : 'lose';
      String prompt = '''
      Analyze this fitness goal and provide a concise analysis and recommendation:
      
      Goal: ${goalType} ${widget.targetAmount} ${widget.targetUnit} in ${widget.targetTimeframe} weeks.
      
      Please provide:
      1. A brief analysis of whether this is an aggressive, moderate, or conservative goal
      2. A short recommendation on how to approach this goal safely and effectively
      
      Format the response with two short paragraphs separated by a blank line.
      Keep the response under 30-40 words for 2nd point and 10-12 words for 1st point.
    ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content).timeout(
        Duration(seconds: 30),
        onTimeout: () => throw Exception('API request timed out'),
      );

      print('Raw API Response: ${response.text}'); // Debug raw response
      final text = response.text ?? '';
      final parts = text.contains('\n\n') ? text.split('\n\n') : [text, 'Consult a professional for advice.'];

      setState(() {
        _analysisText = parts.isNotEmpty ? parts[0] : 'No analysis provided';
        _recommendationText = parts.length > 1 ? parts[1] : 'Consult a professional for advice.';
        _isLoading = false;
      });
    } catch (e) {
      print('Detailed Error: $e'); // Log detailed error
      setState(() {
        _errorOccurred = true;
        _isLoading = false;
        _analysisText = 'Error: $e';
        _recommendationText = 'Please check your API setup or model version.';
      });
    }
  }

  // --- ADDED START ---
  /// Helper function to build the goal summary text
  String _buildGoalSummaryText() {
    String action = widget.goal == 'gain_weight' ? 'Gaining' : 'Losing';
    String timeframe = widget.targetTimeframe > 1 ? 'weeks' : 'week';
    // Format to 0 decimal places for clean display
    String amount = widget.targetAmount.toStringAsFixed(0);
    return '$action $amount ${widget.targetUnit} in ${widget.targetTimeframe} $timeframe';
  }
  // --- ADDED END ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Icon

                      const SizedBox(height: 32),

                      // Title
                      const Text(
                        'Your Target Analysis',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.start,
                      ),

                      // --- ADDED START ---
                      // This is the "number text" you requested above the box
                      const SizedBox(height: 16),
                      Text(
                        _buildGoalSummaryText(),
                        style: TextStyle(
                          fontSize: 22, // Slightly smaller than title
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.6), // Muted color
                        ),
                      ),
                      const SizedBox(height: 24), // Replaced the original 40
                      // --- ADDED END ---


                      // Analysis Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: _isLoading
                            ? Column(
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary(true),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Generating your personalized analysis...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        )
                            : Column(
                          children: [
                            Text(
                              _analysisText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.start,
                            ),

                            const SizedBox(height: 20),

                            Text(
                              _recommendationText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.start,
                            ),

                            if (_errorOccurred)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton(
                                  onPressed: _generateAnalysis,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Try Again',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: Colors.black,
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }
}