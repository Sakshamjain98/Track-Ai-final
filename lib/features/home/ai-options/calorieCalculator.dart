import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Caloriecalculator extends StatefulWidget {
  const Caloriecalculator({Key? key}) : super(key: key);

  @override
  _CaloriecalculatorState createState() => _CaloriecalculatorState();
}

class _CaloriecalculatorState extends State<Caloriecalculator> {
  bool isLoading = false;
  bool isLoadingLastCalculation = false;
  Map<String, dynamic>? lastCalculation;
  bool isLastCalculationExpanded = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController activityController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String selectedWeightUnit = 'Kilograms (kg)';
  String selectedActivity = '';

  final List<String> weightUnits = ['Kilograms (kg)', 'Pounds (lbs)'];

  final List<String> commonActivities = [
    'Select an activity',
    'Running',
    'Walking',
    'Cycling',
    'Swimming',
    'Lifting',
    'Yoga',
    'HIIT',
    'Rowing',
    'Stair Climber',
    'Elliptical',
    'Hiking',
    'Dancing',
    'Pilates',
    'Jumping Rope',
    'Football (Soccer)',
    'Basketball',
    'Tennis',
    'Badminton',
  ];

  @override
  void initState() {
    super.initState();
    _loadLastCalculation();
    isLastCalculationExpanded = false;
    selectedActivity = commonActivities[0]; // Set default to 'Select an activity'
  }

  String _generateCalculationHash(Map<String, String> calcParams) {
    String paramString =
        '${calcParams['activity']}_${calcParams['duration']}_${calcParams['weight']}_${calcParams['weightUnit']}';
    var bytes = utf8.encode(paramString);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: AppColors.cardLinearGradient(isDarkTheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPrimary.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        gradient: AppColors.cardLinearGradient(isDarkTheme),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
  }

  Future<Map<String, dynamic>?> _calculateCaloriesBurnWithGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found in .env file');
      }

      final activity = selectedActivity != 'Select an activity'
          ? selectedActivity
          : activityController.text.trim();
      final duration = durationController.text.trim();
      final weight = weightController.text.trim();
      final weightUnit = selectedWeightUnit;

      // Convert weight to kg if needed
      double weightInKg = double.parse(weight);
      if (weightUnit == 'Pounds (lbs)') {
        weightInKg = weightInKg * 0.453592; // Convert lbs to kg
      }

      String prompt =
          '''
Calculate the calories burned for the following activity:

**Activity Details:**
- Activity: ${activity}
- Duration: ${duration} minutes
- Weight: ${weight} ${weightUnit} (${weightInKg.toStringAsFixed(1)} kg)

**Response Format (JSON only):**
{
  "activity": "${activity}",
  "duration": ${duration},
  "weight": ${weight},
  "weightUnit": "${weightUnit}",
  "weightInKg": ${weightInKg.toStringAsFixed(1)},
  "caloriesBurned": 250,
  "explanation": "Detailed explanation of how the calories were calculated, including MET values and formula used",
  "calculatedOn": "${DateTime.now().toString().split(' ')[0]}"
}

**Important Guidelines:**
1. Use accurate MET (Metabolic Equivalent of Task) values for the activity
2. Apply the standard formula: (MET × 3.5 × weight in kg) / 200 × minutes
3. Provide a clear explanation of the calculation process
4. Round the final result to the nearest whole number
5. Consider activity intensity if specified
6. Return ONLY valid JSON, no additional text or formatting
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey}',
      );

      print('Making API request to: ${url}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode != 200) {
        Map<String, dynamic>? errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {
          // If response body is not JSON
        }

        if (errorData != null && errorData.containsKey('error')) {
          final error = errorData['error'];
          throw Exception(
            'Gemini API Error: ${error['message'] ?? 'Unknown error'}',
          );
        } else {
          throw Exception(
            'Failed to calculate calories: ${response.statusCode} - ${response.body}',
          );
        }
      }

      final responseData = json.decode(response.body);

      if (responseData['candidates'] == null ||
          responseData['candidates'].isEmpty) {
        throw Exception('No calculation generated by AI');
      }

      final generatedText =
          responseData['candidates'][0]['content']['parts'][0]['text'];

      print('Generated text: ${generatedText}');

      // Clean up the response text to extract JSON
      String cleanedText = generatedText.trim();

      // Remove any markdown code blocks if present
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      // Parse the JSON response
      final calculationData = json.decode(cleanedText) as Map<String, dynamic>;

      // Validate the structure
      if (!calculationData.containsKey('caloriesBurned')) {
        throw Exception(
          'Invalid calculation structure: missing caloriesBurned',
        );
      }

      return calculationData;
    } catch (e) {
      print('Error calculating calories with Gemini: $e');
      rethrow;
    }
  }

  Future<void> _loadLastCalculation() async {
    if (_auth.currentUser == null) return;

    setState(() {
      isLoadingLastCalculation = true;
    });

    try {
      final userId = _auth.currentUser!.uid;
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('calorie_calculations')
          .doc('latest')
          .get();

      if (doc.exists) {
        setState(() {
          lastCalculation = {
            'id': doc.id,
            'activity': doc.data()!['activity'] ?? '',
            'duration': doc.data()!['duration'] ?? '',
            'weight': doc.data()!['weight'] ?? '',
            'weightUnit': doc.data()!['weightUnit'] ?? '',
            'caloriesBurned': doc.data()!['caloriesBurned'] ?? 0,
            'explanation': doc.data()!['explanation'] ?? '',
            'date': doc.data()!['date'] ?? '',
            'createdAt': doc.data()!['createdAt'],
            'calculationHash': doc.data()!['calculationHash'] ?? '',
          };
        });
      }
    } catch (e) {
      print('Error loading last calculation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading last calculation: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        isLoadingLastCalculation = false;
      });
    }
  }

  Future<bool> _saveCalculationToFirebase(
    Map<String, dynamic> calculation,
  ) async {
    if (_auth.currentUser == null) return false;

    try {
      final userId = _auth.currentUser!.uid;
      final calcParams = {
        'activity': calculation['activity'].toString(),
        'duration': calculation['duration'].toString(),
        'weight': calculation['weight'].toString(),
        'weightUnit': calculation['weightUnit'].toString(),
      };

      final calculationHash = _generateCalculationHash(calcParams);

      // Always overwrite the latest calculation
      final calculationData = {
        'activity': calculation['activity'],
        'duration': calculation['duration'],
        'weight': calculation['weight'],
        'weightUnit': calculation['weightUnit'],
        'caloriesBurned': calculation['caloriesBurned'],
        'explanation': calculation['explanation'],
        'date': DateTime.now().toString().split(' ')[0],
        'calculationHash': calculationHash,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use 'latest' as document ID to always override
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('calorie_calculations')
          .doc('latest')
          .set(calculationData);

      return true;
    } catch (e) {
      print('Error saving calculation to Firebase: $e');
      return false;
    }
  }

  Future<void> _deleteLastCalculation() async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('calorie_calculations')
          .doc('latest')
          .delete();

      setState(() {
        lastCalculation = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Last calculation deleted successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      print('Error deleting calculation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting calculation: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> calculateCalories() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to calculate calories'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final activity = selectedActivity != 'Select an activity'
        ? selectedActivity
        : activityController.text.trim();

    if (activity.isEmpty ||
        durationController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final calculation = await _calculateCaloriesBurnWithGemini();

      if (calculation == null) {
        throw Exception('Failed to calculate calories');
      }

      final saved = await _saveCalculationToFirebase(calculation);

      if (saved) {
        setState(() {
          lastCalculation = calculation;
        });

        await _loadLastCalculation();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calorie calculation completed and saved!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        throw Exception('Failed to save calculation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating calories: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          duration: Duration(seconds: 4),
        ),
      );

      print('Detailed error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildInputField({
  required String label,
  required TextEditingController controller,
  String? placeholder,
  required bool isDarkTheme,
  TextInputType? keyboardType,
  Widget? suffixIcon,
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
      SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textPrimary(isDarkTheme)),
        decoration: InputDecoration(
          hintText: placeholder,
          suffixIcon: suffixIcon,
          hintStyle: TextStyle(
            color: AppColors.textSecondary(isDarkTheme),
          ),
          filled: true,
          fillColor: AppColors.inputFill(isDarkTheme),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderColor(isDarkTheme),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderColor(isDarkTheme),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkTheme ? Colors.white : Colors.black,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderColor(isDarkTheme).withOpacity(0.5),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildDropdownField({
  required String label,
  required String value,
  required List<String> options,
  required bool isDarkTheme,
  required Function(String?) onChanged,
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
      SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        style: TextStyle(
          color: AppColors.textPrimary(isDarkTheme),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputFill(isDarkTheme),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderColor(isDarkTheme),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderColor(isDarkTheme),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkTheme ? Colors.white : Colors.black,
              width: 2,
            ),
          ),
        ),
        dropdownColor: AppColors.inputFill(isDarkTheme),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    ],
  );
}

  Widget buildLastCalculationSection(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isLastCalculationExpanded = !isLastCalculationExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppColors.textPrimary(isDarkTheme),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'View Last Calculation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDarkTheme),
                    ),
                  ),
                ),
                Container(
                  child: IconButton(
                    icon: Icon(
                      isLastCalculationExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary(isDarkTheme),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        isLastCalculationExpanded = !isLastCalculationExpanded;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isLastCalculationExpanded) ...[
            SizedBox(height: 16),
            if (isLoadingLastCalculation)
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              )
            else if (lastCalculation != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill(isDarkTheme),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lastCalculation!['activity']} - ${lastCalculation!['caloriesBurned']} kcal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(isDarkTheme),
                            ),
                          ),
                          Text(
                            '${lastCalculation!['duration']} min • ${lastCalculation!['weight']} ${lastCalculation!['weightUnit']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(isDarkTheme),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.errorColor,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.cardBackground(isDarkTheme),
                            title: Text(
                              'Delete Last Calculation',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDarkTheme),
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete the last calculation?',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDarkTheme),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDarkTheme ? AppColors.accent(isDarkTheme) : AppColors.black,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteLastCalculation();
                                },
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.white),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: isDarkTheme ? AppColors.errorColor : AppColors.black,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No previous calculation found. Calculate your first calorie burn above!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(isDarkTheme),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget buildResultDisplay(bool isDarkTheme) {
    if (lastCalculation == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: _getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimation Result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkTheme),
            ),
          ),
          SizedBox(height: 20),

          // Calories Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estimated Calories Burned',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDarkTheme),
                ),
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${lastCalculation!['caloriesBurned']}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? Colors.white : Colors.black,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary(isDarkTheme),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 24),

          // AI Explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent(isDarkTheme),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lucide.LucideIcons.brain,
                  size: 16,
                  color: AppColors.textPrimary(isDarkTheme),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI's Explanation:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDarkTheme),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      lastCalculation!['explanation'] ??
                          'No explanation available.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(isDarkTheme),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDarkTheme),
              ),
            ),
            elevation: 1,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDarkTheme),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(
                  lucide.LucideIcons.flame,
                  color: Color(0xFF26A69A),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Calorie Burn Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkTheme),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Form Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: _getCardDecoration(isDarkTheme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            lucide.LucideIcons.flame,
                            color: Color(0xFF26A69A),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Calorie Burn Calculator',
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
                        'Get an AI-powered estimate of calories burned during an activity.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(isDarkTheme),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Activity Dropdown
                      buildDropdownField(
                        label: 'Select Activity',
                        value: selectedActivity,
                        options: commonActivities,
                        isDarkTheme: isDarkTheme,
                        onChanged: (value) {
                          setState(() {
                            selectedActivity = value!;
                            if (selectedActivity != 'Select an activity') {
                              activityController.clear();
                            }
                          });
                        },
                      ),

                      SizedBox(height: 24),

                      // Custom Activity Input
                      Text(
                        'Or enter a custom activity:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(isDarkTheme),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: activityController,
                        enabled: selectedActivity == 'Select an activity',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                        ),
                        decoration: InputDecoration(
                          hintText: "E.g., 'Vigorous gardening'",
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(isDarkTheme),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.inputBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.inputBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.inputFocusedBorder,
                              width: 2,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.inputBorder.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Duration and Weight
                      Row(
                        children: [
                          Expanded(
                            child: buildInputField(
                              label: 'Duration (minutes)',
                              controller: durationController,
                              isDarkTheme: isDarkTheme,
                              placeholder: 'E.g., 30',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: buildInputField(
                              label: 'Your Current Weight',
                              controller: weightController,
                              isDarkTheme: isDarkTheme,
                              placeholder: '69.0',
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      buildDropdownField(
                        isDarkTheme: isDarkTheme,
                        label: 'Weight Unit',
                        value: selectedWeightUnit,
                        options: weightUnits,
                        onChanged: (value) {
                          setState(() {
                            selectedWeightUnit = value!;
                          });
                        },
                      ),

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : calculateCalories,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkTheme ? AppColors.accent(isDarkTheme) : AppColors.black,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          AppColors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Calculating...'),
                                  ],
                                )
                              : Text(
                                  'Calculate Calories Burned',
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

                // Last Calculation Section
                SizedBox(height: 24),
                buildLastCalculationSection(isDarkTheme),

                // Result Display
                if (lastCalculation != null) ...[
                  SizedBox(height: 24),
                  buildResultDisplay(isDarkTheme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}