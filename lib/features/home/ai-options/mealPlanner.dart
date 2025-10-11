import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/ai-options/service/filedownload.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class Mealplanner extends StatefulWidget {
  const Mealplanner({Key? key}) : super(key: key);

  @override
  _MealplannerState createState() => _MealplannerState();
}

class _MealplannerState extends State<Mealplanner> {
  bool isLoading = false;
  bool isLoadingRecentPlans = false;
  Map<String, dynamic>? mealPlan;
  List<Map<String, dynamic>> recentPlans = [];
  bool isRecentPlansExpanded = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController caloriesController = TextEditingController(
    text: '2000',
  );
  final TextEditingController cuisineController = TextEditingController();
  final TextEditingController healthConditionsController =
      TextEditingController();
  final TextEditingController restrictionsController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();

  String selectedDays = '7 Days';
  String selectedDietType = 'Any / No Specific Diet';

  final List<String> dayOptions = [
    '3 Days',
    '5 Days',
    '7 Days',
    '14 Days',
    '30 Days',
  ];
  final List<String> dietOptions = [
    'Any / No Specific Diet',
    'Keto',
    'Paleo',
    'Vegan',
    'Vegetarian',
    'Mediterranean',
    'Low Carb',
    'Intermittent Fasting',
    'DASH Diet',
    'Whole30',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentPlans();
    isRecentPlansExpanded = false;
  }

  String _generatePlanHash(Map<String, String> planParams) {
    String paramString =
        '${planParams['calories']}_${planParams['days']}_${planParams['dietType']}_${planParams['cuisine']}_${planParams['healthConditions']}_${planParams['restrictions']}_${planParams['preferences']}';
    var bytes = utf8.encode(paramString);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> _generateMealPlanWithGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found in .env file');
      }

      final numDays = int.parse(selectedDays.split(' ')[0]);
      final targetCalories = caloriesController.text.trim();
      final dietType = selectedDietType;
      final cuisine = cuisineController.text.trim();
      final healthConditions = healthConditionsController.text.trim();
      final restrictions = restrictionsController.text.trim();
      final preferences = preferencesController.text.trim();

      String prompt = '''
Create a detailed ${numDays}-day meal plan with the following specifications:

**Requirements:**
- Daily calorie target: ${targetCalories} kcal
- Diet type: ${dietType}
${cuisine.isNotEmpty ? '- Cuisine preference: ${cuisine}' : ''}
${healthConditions.isNotEmpty ? '- Health conditions: ${healthConditions}' : ''}
${restrictions.isNotEmpty ? '- Dietary restrictions: ${restrictions}' : ''}
${preferences.isNotEmpty ? '- Food preferences: ${preferences}' : ''}

**Response Format (JSON only):**
{
  "Day 1": {
    "breakfast": {
      "name": "Meal name",
      "calories": 350,
      "recipe": "Detailed cooking instructions"
    },
    "lunch": {
      "name": "Meal name",
      "calories": 550,
      "recipe": "Detailed cooking instructions"
    },
    "dinner": {
      "name": "Meal name",
      "calories": 700,
      "recipe": "Detailed cooking instructions"
    },
    "snacks": {
      "name": "Snack name",
      "calories": 400,
      "recipe": "Preparation instructions"
    },
    "totalCalories": 2000
  },
  ... (continue for all ${numDays} days),
  "planSummary": {
    "totalDays": ${numDays},
    "avgDailyCalories": 2000,
    "totalCalories": ${numDays * int.parse(targetCalories)},
    "dietType": "${dietType}",
    "generatedOn": "${DateTime.now().toString().split(' ')[0]}"
  }
}

**Important Guidelines:**
1. Each meal should have realistic calorie counts that add up to the daily target
2. Provide detailed, actionable recipes with cooking instructions
3. Ensure meals are varied and nutritionally balanced
4. Consider the specified diet type and restrictions
5. Make recipes practical for home cooking
6. Include preparation time considerations
7. Return ONLY valid JSON, no additional text or formatting
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey}',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192,
          }
        }),
      );

      if (response.statusCode != 200) {
        Map<String, dynamic>? errorData;
        try {
          errorData = json.decode(response.body);
        } catch (e) {}
        
        if (errorData != null && errorData.containsKey('error')) {
          final error = errorData['error'];
          throw Exception('Gemini API Error: ${error['message'] ?? 'Unknown error'}');
        } else {
          throw Exception('Failed to generate meal plan: ${response.statusCode} - ${response.body}');
        }
      }

      final responseData = json.decode(response.body);
      
      if (responseData['candidates'] == null || 
          responseData['candidates'].isEmpty) {
        throw Exception('No meal plan generated by AI');
      }

      final generatedText = responseData['candidates'][0]['content']['parts'][0]['text'];
      
      String cleanedText = generatedText.trim();
      
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

      final mealPlanData = json.decode(cleanedText) as Map<String, dynamic>;
      
      if (!mealPlanData.containsKey('planSummary')) {
        throw Exception('Invalid meal plan structure: missing planSummary');
      }

      return mealPlanData;

    } catch (e) {
      print('Error generating meal plan with Gemini: $e');
      rethrow;
    }
  }

  Future<void> _loadRecentPlans() async {
    if (_auth.currentUser == null) return;

    setState(() {
      isLoadingRecentPlans = true;
    });

    try {
      final userId = _auth.currentUser!.uid;
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealplans')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      setState(() {
        recentPlans = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'date': data['date'] ?? '',
            'calories': data['calories'] ?? '',
            'dietType': data['dietType'] ?? '',
            'days': data['days'] ?? '',
            'plan': data['plan'] ?? {},
            'createdAt': data['createdAt'],
            'planHash': data['planHash'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recent plans: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        isLoadingRecentPlans = false;
      });
    }
  }

  Future<bool> _saveMealPlanToFirebase(Map<String, dynamic> plan) async {
    if (_auth.currentUser == null) return false;

    try {
      final userId = _auth.currentUser!.uid;
      final planParams = {
        'calories': caloriesController.text.trim(),
        'days': selectedDays,
        'dietType': selectedDietType,
        'cuisine': cuisineController.text.trim(),
        'healthConditions': healthConditionsController.text.trim(),
        'restrictions': restrictionsController.text.trim(),
        'preferences': preferencesController.text.trim(),
      };

      final planHash = _generatePlanHash(planParams);

      final existingPlans = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealplans')
          .where('planHash', isEqualTo: planHash)
          .get();

      if (existingPlans.docs.isNotEmpty) {
        final existingDoc = existingPlans.docs.first;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('mealplans')
            .doc(existingDoc.id)
            .update({
              'createdAt': FieldValue.serverTimestamp(),
              'date': DateTime.now().toString().split(' ')[0],
              'plan': plan,
            });
        return true;
      }

      final mealPlanData = {
        'title': '$selectedDays ${selectedDietType} Plan',
        'date': DateTime.now().toString().split(' ')[0],
        'calories': caloriesController.text.trim(),
        'dietType': selectedDietType,
        'days': selectedDays,
        'cuisine': cuisineController.text.trim(),
        'healthConditions': healthConditionsController.text.trim(),
        'restrictions': restrictionsController.text.trim(),
        'preferences': preferencesController.text.trim(),
        'plan': plan,
        'planHash': planHash,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealplans')
          .add(mealPlanData);

      return true;
    } catch (e) {
      print('Error saving meal plan to Firebase: $e');
      return false;
    }
  }

  Future<void> _deleteMealPlan(String planId) async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealplans')
          .doc(planId)
          .delete();

      setState(() {
        recentPlans.removeWhere((plan) => plan['id'] == planId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal plan deleted successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting meal plan: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  BoxDecoration getCardDecoration(bool isDarkTheme) {
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
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration getMealCardDecoration(bool isDarkTheme) {
    return BoxDecoration(
      color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
        width: 1,
      ),
    );
  }

  Future<void> generateMealPlan() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to generate meal plans'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final newPlan = await _generateMealPlanWithGemini();
      
      if (newPlan == null) {
        throw Exception('Failed to generate meal plan');
      }

      final saved = await _saveMealPlanToFirebase(newPlan);

      if (saved) {
        setState(() {
          mealPlan = newPlan;
        });

        await _loadRecentPlans();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI-powered meal plan generated and saved successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        throw Exception('Failed to save meal plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating meal plan: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadMealPlan() async {
    if (mealPlan == null) return;

    try {
      String content = _generateMealPlanContent();
      String planTitle = '${selectedDays}_${selectedDietType}_MealPlan';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading meal plan...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      Map<String, dynamic> result = await FileDownloadService.downloadMealPlan(
        content,
        planTitle,
      );

      await FileDownloadService.showDownloadResult(context, result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading meal plan: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  String _generateMealPlanContent() {
    if (mealPlan == null) return '';

    String content = 'AI-POWERED PERSONALIZED MEAL PLAN\n';
    content += '=' * 50 + '\n\n';
    content += 'Generated on: ${DateTime.now().toString().split(' ')[0]}\n';
    content += 'Daily Calorie Goal: ${caloriesController.text} kcal\n';
    content += 'Plan Duration: $selectedDays\n';
    content += 'Diet Type: $selectedDietType\n';
    
    if (cuisineController.text.isNotEmpty) {
      content += 'Cuisine Preference: ${cuisineController.text}\n';
    }
    if (healthConditionsController.text.isNotEmpty) {
      content += 'Health Conditions: ${healthConditionsController.text}\n';
    }
    if (restrictionsController.text.isNotEmpty) {
      content += 'Dietary Restrictions: ${restrictionsController.text}\n';
    }
    if (preferencesController.text.isNotEmpty) {
      content += 'Food Preferences: ${preferencesController.text}\n';
    }
    
    content += '\n';

    final summary = mealPlan!['planSummary'] as Map<String, dynamic>;
    content += 'PLAN SUMMARY\n';
    content += '-' * 20 + '\n';
    content += 'Average Daily Calories: ${summary['avgDailyCalories']} kcal\n';
    content += 'Total Plan Calories: ${summary['totalCalories']} kcal\n\n';

    mealPlan!.forEach((day, meals) {
      if (day == 'planSummary') return;

      content += '${day.toUpperCase()}\n';
      content += '=' * (day.length + 10) + '\n';

      final dayMeals = meals as Map<String, dynamic>;

      ['breakfast', 'lunch', 'dinner', 'snacks'].forEach((mealType) {
        if (dayMeals.containsKey(mealType)) {
          final meal = dayMeals[mealType] as Map<String, dynamic>;

          content += '\n${mealType.toUpperCase()}\n';
          content += '${meal['name']} (${meal['calories']} kcal)\n';
          content += 'Recipe: ${meal['recipe']}\n';
        }
      });

      if (dayMeals.containsKey('totalCalories')) {
        content += '\nDaily Total: ${dayMeals['totalCalories']} kcal\n';
      }
      content += '\n' + '-' * 50 + '\n\n';
    });

    return content;
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    required bool isDarkTheme,
    int maxLines = 1,
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
            color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            suffixIcon: suffixIcon,
            hintStyle: TextStyle(
              color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
            ),
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
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
            color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: TextStyle(
            color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
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
          dropdownColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(
                  color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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

  Widget buildMealCard(String mealType, Map<String, dynamic> mealData, bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: getMealCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${mealData['name']} (${mealData['calories']} kcal)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Recipe: ${mealData['recipe']}',
            style: TextStyle(
              fontSize: 13,
              color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecentPlansSection(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isRecentPlansExpanded = !isRecentPlansExpanded;
              });
            },
            child: Row(
              children: [
                Icon(
                  lucide.LucideIcons.history,
                  color: isDarkTheme ? Colors.white : Colors.black,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Meal Plans',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isRecentPlansExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDarkTheme ? Colors.white : Colors.black,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      isRecentPlansExpanded = !isRecentPlansExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (isRecentPlansExpanded) ...[
            SizedBox(height: 16),
            if (isLoadingRecentPlans)
              Center(
                child: CircularProgressIndicator(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              )
            else if (recentPlans.isNotEmpty) ...[
              ...recentPlans.take(5).map((plan) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
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
                              plan['title'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${plan['date']} • ${plan['calories']} kcal/day',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          lucide.LucideIcons.eye,
                          size: 20,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            mealPlan = plan['plan'];
                            isRecentPlansExpanded = false;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          lucide.LucideIcons.trash2,
                          size: 20,
                          color: AppColors.errorColor,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
                              title: Text(
                                'Delete Meal Plan',
                                style: TextStyle(
                                  color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete this meal plan?',
                                style: TextStyle(
                                  color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _deleteMealPlan(plan['id']);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.errorColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'No recent meal plans found. Generate your first AI-powered plan above!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget buildMealPlanDisplay(bool isDarkTheme) {
    if (mealPlan == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: getCardDecoration(isDarkTheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.utensilsCrossed,
                      color: Color(0xFF26A69A),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-Generated Meal Plan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: Icon(
                    lucide.LucideIcons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: downloadMealPlan,
                ),
              ),
            ],
          ),

          if (mealPlan!.containsKey('planSummary')) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkTheme ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Meal Plan Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${mealPlan!['planSummary']['totalDays']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Days',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: isDarkTheme ? Colors.grey[600]! : Colors.grey[400]!,
                      ),
                      Column(
                        children: [
                          Text(
                            '${mealPlan!['planSummary']['avgDailyCalories']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Avg. Calories',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20),

          ...mealPlan!.entries.where((entry) => entry.key != 'planSummary').map(
            (entry) {
              final day = entry.key;
              final meals = entry.value as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(20),
                decoration: getCardDecoration(isDarkTheme),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (meals.containsKey('totalCalories'))
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkTheme ? Colors.black : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${meals['totalCalories']} kcal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDarkTheme ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    ...['breakfast', 'lunch', 'dinner', 'snacks'].map((mealType) {
                      if (meals.containsKey(mealType)) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: buildMealCard(
                            mealType,
                            meals[mealType] as Map<String, dynamic>,
                            isDarkTheme,
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    }).toList(),
                  ],
                ),
              );
            },
          ).toList(),
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
          backgroundColor: isDarkTheme ? AppColors.darkBackground : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
            elevation: 1,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(
                  lucide.LucideIcons.utensilsCrossed,
                  color: Color(0xFF26A69A),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'AI Meal Planner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
                  decoration: getCardDecoration(isDarkTheme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            lucide.LucideIcons.utensilsCrossed,
                            color: Color(0xFF26A69A),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI Meal Planner',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Generate personalized meal plans using advanced AI. Get detailed recipes and nutrition tailored to your needs.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkTheme ? AppColors.textSecondary(true) : AppColors.textSecondary(false),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Form Fields
                      buildInputField(
                        label: 'Daily Calorie Goal (kcal)',
                        controller: caloriesController,
                        isDarkTheme: isDarkTheme,
                        placeholder: '2000',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: buildDropdownField(
                              isDarkTheme: isDarkTheme,
                              label: 'Number of Days',
                              value: selectedDays,
                              options: dayOptions,
                              onChanged: (value) {
                                setState(() {
                                  selectedDays = value!;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: buildDropdownField(
                              isDarkTheme: isDarkTheme,
                              label: 'Diet Type (Optional)',
                              value: selectedDietType,
                              options: dietOptions,
                              onChanged: (value) {
                                setState(() {
                                  selectedDietType = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      buildInputField(
                        isDarkTheme: isDarkTheme,
                        label: 'Cuisine Preference (Optional)',
                        controller: cuisineController,
                        placeholder: 'E.g., Indian, Italian, Mexican',
                      ),
                      SizedBox(height: 16),

                      buildInputField(
                        isDarkTheme: isDarkTheme,
                        label: 'Health Conditions or Diseases (Optional)',
                        controller: healthConditionsController,
                        placeholder:
                            'E.g., high blood pressure, diabetes, PCOS',
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),

                      buildInputField(
                        isDarkTheme: isDarkTheme,
                        label: 'Other Dietary Restrictions (Optional)',
                        controller: restrictionsController,
                        placeholder: 'E.g., gluten-free, allergies to nuts',
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),

                      buildInputField(
                        isDarkTheme: isDarkTheme,
                        label: 'Food Preferences/Dislikes (Optional)',
                        controller: preferencesController,
                        placeholder:
                            'E.g., loves chicken, dislikes broccoli, prefers spicy food',
                        maxLines: 3,
                      ),

                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : generateMealPlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
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
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('AI Generating Your Plan...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(lucide.LucideIcons.sparkles),
                                    SizedBox(width: 8),
                                    Text(
                                      'Generate AI Meal Plan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Plans Section
                SizedBox(height: 24),
                buildRecentPlansSection(isDarkTheme),

                // Meal Plan Display
                if (mealPlan != null) ...[
                  SizedBox(height: 24),
                  buildMealPlanDisplay(isDarkTheme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}