import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;
// Make sure these import paths are correct for your project
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/home/homepage/desc%20and%20scan/gemini.dart';
import 'package:provider/provider.dart';
import '../../../../core/routes/routes.dart';
import '../log/daily_log_provider.dart';
import '../log/food_log_entry.dart';

// A constant for the teal color
const Color kPrimaryTeal = Color(0xFF4DD0E1);

class LabelAnalysisScreen extends StatefulWidget {
  final File? imageFile;
  const LabelAnalysisScreen({Key? key,this.imageFile,}) : super(key: key);

  @override
  State<LabelAnalysisScreen> createState() => _LabelAnalysisScreenState();
}

class _LabelAnalysisScreenState extends State<LabelAnalysisScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isValidLabel = true;
  String? _errorMessage;

  // State variable to control the display of the initial camera interface
  bool _showCameraInterface = true;
  void initState() {
    super.initState();

    // Add this logic:
    if (widget.imageFile != null) {
      setState(() {
        _selectedImage = widget.imageFile;
        _showCameraInterface = false; // Bypass the selector
      });

      // Call analysis after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzeLabel();
      });
    }
  }
  final ImagePicker _picker = ImagePicker();
  final Gemini _gemini = Gemini();

  // AI Data Structure for Label
  Map<String, dynamic>? _labelData;

  // --- Style Helper (Copied from food_desc.dart) ---

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // --- Image & Analysis Logic ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _labelData = null;
          _isValidLabel = true;
          _errorMessage = null;
          _showCameraInterface = false;
        });

        HapticFeedback.lightImpact();
        await _analyzeLabel();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeLabel() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _gemini.analyzeNutritionLabel(_selectedImage!);

      try {
        final jsonData = json.decode(result);

        if (jsonData['isValidLabel'] == false) {
          setState(() {
            _isAnalyzing = false;
            _isValidLabel = false;
            _errorMessage = jsonData['errorMessage'] ?? 'No valid nutrition label detected.';
            _labelData = null;
          });
        } else {
          _parseLabelResponse(jsonData);
          setState(() {
            _isAnalyzing = false;
            _isValidLabel = true;
          });
        }
        HapticFeedback.mediumImpact();

      } catch (parseError) {
        _showErrorSnackBar('Failed to parse analysis result.');
        setState(() {
          _isAnalyzing = false;
          _isValidLabel = false;
          _errorMessage = 'An error occurred during analysis. Please try again.';
        });
      }

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _isValidLabel = false;
        _errorMessage = 'Analysis failed: $e';
      });
      _showErrorSnackBar('Analysis failed: $e');
    }
  }

  void _parseLabelResponse(Map<String, dynamic> jsonData) {
    // Ensure nutrientBreakdown and its nested fields have default zero/empty values
    final Map<String, dynamic> nutrientBreakdown =
        (jsonData['nutrientBreakdown'] as Map<String, dynamic>?) ?? {};
    jsonData['vitaminsInsight'] = jsonData['vitaminsInsight'] ?? '';
    jsonData['mineralsInsight'] = jsonData['mineralsInsight'] ?? '';

    // Helper to get a nutrient map with defaults if it's missing or not a map
    Map<String, dynamic> _getNutrientData(String key) {
      final data = nutrientBreakdown[key];
      if (data is Map<String, dynamic>) {
        return {
          "amount": data['amount'] ?? "0g",
          "dv": data['dv'] ?? "0% DV",
          "insight": data['insight'] ?? "No specific insight available for this nutrient."
        };
      }
      // Return a default structure if not found or not a map
      return {
        "amount": "0g",
        "dv": "0% DV",
        "insight": "No specific insight available for this nutrient."
      };
    }

    // Populate nutrientBreakdown with defaults if any specific nutrient is missing
    jsonData['nutrientBreakdown'] = {
      'totalFat': _getNutrientData('totalFat'),
      'saturatedFat': _getNutrientData('saturatedFat'),
      'transFat': _getNutrientData('transFat'),
      'cholesterol': _getNutrientData('cholesterol'),
      'sodium': _getNutrientData('sodium'),
      'totalCarbohydrate': _getNutrientData('totalCarbohydrate'),
      'dietaryFiber': _getNutrientData('dietaryFiber'),
      'totalSugars': _getNutrientData('totalSugars'),
      'addedSugars': _getNutrientData('addedSugars'),
      'protein': _getNutrientData('protein'),
    };

    // Set default calories to 0 if missing
    jsonData['calories'] = jsonData['calories'] ?? 0;

    // Ensure vitamins and minerals are lists (empty if null) and have default insights
    jsonData['vitamins'] = (jsonData['vitamins'] as List?)?.map((v) {
      if (v is Map<String, dynamic>) {
        return {
          "name": v['name'] ?? 'Unknown',
          "amount": v['amount'] ?? '0',
          "dv": v['dv'] ?? '0% DV',
          "insight": v['insight'] ?? 'No specific insight available for this vitamin.'
        };
      }
      return {}; // Return empty map if unexpected format
    }).toList() ?? [];

    jsonData['minerals'] = (jsonData['minerals'] as List?)?.map((m) {
      if (m is Map<String, dynamic>) {
        return {
          "name": m['name'] ?? 'Unknown',
          "amount": m['amount'] ?? '0',
          "dv": m['dv'] ?? '0% DV',
          "insight": m['insight'] ?? 'No specific insight available for this mineral.'
        };
      }
      return {}; // Return empty map if unexpected format
    }).toList() ?? [];

    setState(() {
      _labelData = jsonData;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _labelData = null;
      _isValidLabel = true;
      _errorMessage = null;
      _showCameraInterface = true;
      _isAnalyzing = false;
    });
  }

  // --- UI Building Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ CHANGED: Light theme background
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        // ✅ CHANGED: Light theme AppBar
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          // ✅ CHANGED: Light theme icon
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Food Label Analysis',
          style: TextStyle(
            // ✅ CHANGED: Light theme text
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),


      ),
      body: _showCameraInterface
          ? _buildImageSelector()
          : _buildAnalysisView(),
    );
  }

  // --- IMAGE SELECTOR UI (Adapted from food_desc.dart) ---
  Widget _buildImageSelector() {
    return Column(
      children: [
        // Camera Preview Section
        Expanded(
          flex: 7,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ready to Scan Label',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point camera at a nutrition label',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons Section
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              // ✅ CHANGED: Light theme background
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              // ✅ ADDED: Shadow from food_desc.dart
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Scan Label Button
                  Expanded(
                    child: _buildHorizontalActionButton(
                      icon: Icons.qr_code_scanner,
                      title: 'Scan Label',
                      onTap: () => _pickImage(ImageSource.camera),
                      // ✅ CHANGED: Light theme icon/text color
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Choose from Gallery Button
                  Expanded(
                    child: _buildHorizontalActionButton(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                      // ✅ CHANGED: Light theme icon/text color
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Helper for action buttons (Matched to food_desc.dart)
  Widget _buildHorizontalActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, // Solid white background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!, // Subtle grey border
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30), // Icon uses passed color
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color, // Text uses passed color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ANALYSIS VIEW (Shows loading, error, or results) ---

  // ✅ UPDATED: Removed Stack, uses simple if/else
  Widget _buildAnalysisView() {
    if (_isAnalyzing) {
      return _buildLoadingWidget();
    } else if (!_isValidLabel) {
      return _buildErrorWidget(); // Show "Not a valid label" error
    } else if (_labelData != null) {
      return _buildLabelResults(); // Show the parsed label data
    } else {
      // Fallback for any other state
      return _buildLoadingWidget();
    }
  }

  // ✅ UPDATED: Light theme loading widget
  Widget _buildLoadingWidget() {
    // Center widget removed
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Keep column tight
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyzing your label...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  // ✅ UPDATED: Light theme error widget
  Widget _buildErrorWidget() {
    // Center widget removed
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Keep column tight
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Not a Valid Label',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'No valid nutrition label detected.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home); // Navigate home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
  // --- NEW LABEL RESULTS UI (Matches Screenshots) ---

  Widget _buildLabelResults() {
    final data = _labelData!;
    final nutrients = data['nutrientBreakdown'] ?? {};

    return SingleChildScrollView(
      // ✅ UPDATED: Removed bottom padding
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            data['productName'] ?? 'Food Label Analysis',
            style: const TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Per Serving: ${data['servingSize'] ?? 'N/A'} | Servings: ${data['servingsPerContainer'] ?? 'N/A'}',
            style: TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Calories
          _buildCalorieDisplay(data['calories'] ?? 0),
          const SizedBox(height: 24),

          // Macro Grid
          _buildMacroGrid(nutrients),
          const SizedBox(height: 24),

          // Log 1 Serving Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // --- START OF NEW LOGIC ---
                if (_labelData == null) return;

                // 1. Get the provider
                final logProvider = context.read<DailyLogProvider>();
                final nutrients = _labelData!['nutrientBreakdown'] ?? {};

                // 2. Create the log entry
                final entry = FoodLogEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _labelData!['productName'] ?? 'Scanned Label',
                  calories: _labelData!['calories'] ?? 0,
                  protein: _parseAmount(nutrients['protein']),       // <-- FIX
                  carbs: _parseAmount(nutrients['totalCarbohydrate']), // <-- FIX
                  fat: _parseAmount(nutrients['totalFat']),           // <-- FIX
                  fiber: _parseAmount(nutrients['dietaryFiber']),       // <-- FIX
                  timestamp: DateTime.now(),
                  imagePath: _selectedImage?.path,
                );

                // 3. Add to the log
              await  logProvider.addEntry(entry);
// --- 4. NEW: Save to Firestore for Analytics ---
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                    // ...
                        .collection('entries')
                        .add({ // <-- START OF FIX
                      'id': entry.id,
                      'name': entry.name,
                      'calories': entry.calories,
                      'protein': entry.protein,
                      'carbs': entry.carbs,
                      'fat': entry.fat,
                      'fiber': entry.fiber,
                      'timestamp': Timestamp.fromDate(entry.timestamp), // Manually create Timestamp
                      'healthScore': entry.healthScore,
                      'healthDescription': entry.healthDescription,
                      'imagePath': entry.imagePath,
                    }); // <-- END OF FIX
                  }
// ...
                } catch (e) {
                  print("Error saving log to Firestore: $e");
                  // Optionally show a silent error
                }
                // --- END OF NEW LOGIC ---
                // 4. Show success and go back
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${entry.name} logged!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
                // --- END OF NEW LOGIC ---
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                  'Log this Serving',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                // ✅ CHANGED: Consistent button style
                backgroundColor: Colors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Summary
          if (data['quickSummary'] != null)
            _buildQuickSummary(data['quickSummary']),

          // Nutrient Breakdown
          _buildNutrientBreakdownList(nutrients),

          // Other Nutrients
          // Other Nutrients
          _buildOtherNutrients(
            data['vitamins'],
            data['minerals'],
            data['vitaminsInsight'],
            data['mineralsInsight'],
          ),        // Ingredient Insights
          if (data['ingredientInsights'] != null)
            _buildIngredientInsights(data['ingredientInsights']),

          // ✅ ADDED: "Analyze Another" button at the end
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            child: ElevatedButton(
              onPressed:  ( ){
    Navigator.pushNamed(context, AppRoutes.home); // Navigate home
    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Analyze Another Label',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDisplay(int calories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      // ✅ CHANGED: Use card decoration
      decoration: _getCardDecoration(),
      child: Column(
        children: [
          Text(
            'Total Calories ',
            style: TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$calories',
            style: const TextStyle(
              color: Colors.black, // Kept teal for highlight
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMacroGrid(Map<String, dynamic> nutrients) {
    // This new layout uses Rows and Expanded widgets to prevent overflow
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMacroTile(
                'Protein',
                nutrients['protein']?['amount'] ?? '0g', // <-- FIX
                lucide.LucideIcons.zap,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMacroTile(
                'Carbs',
                nutrients['totalCarbohydrate']?['amount'] ?? '0g', // <-- FIX
                lucide.LucideIcons.wheat,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // Space between the rows
        Row(
          children: [
            Expanded(
              child: _buildMacroTile(
                'Fat',
                nutrients['totalFat']?['amount'] ?? '0g', // <-- FIX
                lucide.LucideIcons.droplet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMacroTile(
                'Fiber',
                nutrients['dietaryFiber']?['amount'] ?? '0g', // <-- FIX
                Icons.eco,
                const Color(0xFFE37F4A),
              ),
            ),
          ],
        ),
      ],
    );
  }
  // Add this function anywhere inside your _LabelAnalysisScreenState
  int _parseAmount(Map<String, dynamic>? nutrientData) {
    if (nutrientData == null) return 0;
    String amountStr = nutrientData['amount'] ?? '0';
    // Remove non-numeric characters (like 'g' or 'mg')
    amountStr = amountStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(amountStr)?.toInt() ?? 0;
  }
  Widget _buildMacroTile(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      // ✅ CHANGED: Use card decoration
      decoration: _getCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      // ✅ CHANGED: Use card decoration
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ✅ CHANGED: Light theme icon
              Icon(Icons.star_outline, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Quick Summary',
                style: TextStyle(
                  // ✅ CHANGED: Light theme text
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.black,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildExpandableNutrientCard({
    required String label,
    required String amount,
    required String dv,
    required String insight,
    List<Widget>? subNutrients, // For things like Saturated Fat under Total Fat
  }) {
    return Card(
      elevation: 0, // Remove default Card elevation
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      color: Colors.grey[100], // Match light theme
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            Text(
              amount,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              dv,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          // Main insight for the parent nutrient
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (subNutrients != null && subNutrients.isNotEmpty) const SizedBox(height: 16), // Space before sub-nutrients
          ],
          // Sub-nutrients (e.g., Saturated Fat under Total Fat)
          if (subNutrients != null && subNutrients.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subNutrients.map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0), // Add spacing for sub-items
                child: sub,
              )).toList(),
            ),
        ],
      ),
    );
  }
  Widget _buildNutrientBreakdownList(Map<String, dynamic> nutrients) {
    return _buildTitledSection(
      title: 'Nutrient Breakdown (Per Serving)',
      child: Column(
        children: [
          // Use _buildExpandableNutrientCard for each major nutrient
          _buildExpandableNutrientCard(
            label: 'Total Fat',
            amount: nutrients['totalFat']?['amount'] ?? '0g',
            dv: nutrients['totalFat']?['dv'] ?? '0% DV',
            insight: nutrients['totalFat']?['insight'] ?? '',
            subNutrients: [
              _buildNutrientRow('Saturated Fat', nutrients['saturatedFat']?['amount'] ?? '0g', nutrients['saturatedFat']?['dv'] ?? '0% DV', insight: nutrients['saturatedFat']?['insight']),
              _buildNutrientRow('Trans Fat', nutrients['transFat']?['amount'] ?? '0g', nutrients['transFat']?['dv'] ?? '0% DV', insight: nutrients['transFat']?['insight']),
            ],
          ),
          _buildExpandableNutrientCard(
            label: 'Cholesterol',
            amount: nutrients['cholesterol']?['amount'] ?? '0mg',
            dv: nutrients['cholesterol']?['dv'] ?? '0% DV',
            insight: nutrients['cholesterol']?['insight'] ?? '',
          ),
          _buildExpandableNutrientCard(
            label: 'Sodium',
            amount: nutrients['sodium']?['amount'] ?? '0mg',
            dv: nutrients['sodium']?['dv'] ?? '0% DV',
            insight: nutrients['sodium']?['insight'] ?? '',
          ),
          _buildExpandableNutrientCard(
            label: 'Total Carbohydrate',
            amount: nutrients['totalCarbohydrate']?['amount'] ?? '0g',
            dv: nutrients['totalCarbohydrate']?['dv'] ?? '0% DV',
            insight: nutrients['totalCarbohydrate']?['insight'] ?? '',
            subNutrients: [
              _buildNutrientRow('Dietary Fiber', nutrients['dietaryFiber']?['amount'] ?? '0g', nutrients['dietaryFiber']?['dv'] ?? '0% DV', insight: nutrients['dietaryFiber']?['insight']),
              _buildNutrientRow('Total Sugars', nutrients['totalSugars']?['amount'] ?? '0g', nutrients['totalSugars']?['dv'] ?? '0% DV', insight: nutrients['totalSugars']?['insight']),
              _buildNutrientRow('Includes Added Sugars', nutrients['addedSugars']?['amount'] ?? '0g', nutrients['addedSugars']?['dv'] ?? '0% DV', insight: nutrients['addedSugars']?['insight']),
            ],
          ),
          _buildExpandableNutrientCard(
            label: 'Protein',
            amount: nutrients['protein']?['amount'] ?? '0g',
            dv: nutrients['protein']?['dv'] ?? '0% DV',
            insight: nutrients['protein']?['insight'] ?? '',
          ),
        ],
      ),
    );
  }
  Widget _buildNutrientRow(String label, String value, String dv, {String? insight}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: _getCardDecoration(),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column( // Now a column to hold insight
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dv,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (insight != null && insight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherNutrients(
      List<dynamic>? vitamins,
      List<dynamic>? minerals,
      String? vitaminsInsight,
      String? mineralsInsight,
      ) {
    vitamins = vitamins ?? [];
    minerals = minerals ?? [];
    vitaminsInsight = vitaminsInsight ?? '';
    mineralsInsight = mineralsInsight ?? '';

    // If we have data, build the expandable cards
    return _buildTitledSection(
      title: 'Other Nutrients',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Vitamins Section ---
          if (vitamins.isNotEmpty)
            _buildCategoryExpansionCard(
              title: 'Vitamins',
              insight: vitaminsInsight,
              children: vitamins.map((n) {
                final nutrient = n as Map<String, dynamic>? ?? {};
                // Use _buildNutrientRow for the inner items
                return _buildNutrientRow(
                  nutrient['name'] ?? 'Unknown',
                  nutrient['amount'] ?? '0',
                  nutrient['dv'] ?? '0% DV',
                  insight: nutrient['insight'],
                );
              }).toList(),
            ),

          if (vitamins.isNotEmpty && minerals.isNotEmpty)
            const SizedBox(height: 8), // Space between categories

          // --- Minerals Section ---
          if (minerals.isNotEmpty)
            _buildCategoryExpansionCard(
              title: 'Minerals',
              insight: mineralsInsight,
              children: minerals.map((n) {
                final nutrient = n as Map<String, dynamic>? ?? {};
                // Use _buildNutrientRow for the inner items
                return _buildNutrientRow(
                  nutrient['name'] ?? 'Unknown',
                  nutrient['amount'] ?? '0',
                  nutrient['dv'] ?? '0% DV',
                  insight: nutrient['insight'],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  Widget _buildCategoryExpansionCard({
    required String title,
    required String insight,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      color: Colors.grey[100], // Use the new white background
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add padding
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16, // Make category title slightly larger
            fontWeight: FontWeight.w600, // Make it bold
          ),
        ),
        // This removes the default up/down arrow to match your screenshot
        trailing: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          // 1. The General Insight
          if (insight.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. The List of Individual Nutrients
          Column(
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: child, // child is already a _buildNutrientRow
            )).toList(),
          ),
        ],
      ),
    );
  }

  // --- ADD THESE THREE NEW WIDGETS ---

  // 1. The tappable button
  Widget _buildNutrientDialogButton({required String title, required List<dynamic> nutrients}) {
    return GestureDetector(
      onTap: () {
        if (nutrients.isNotEmpty) {
          _showNutrientDialog(title, nutrients);
        } else {
          _showErrorSnackBar('No $title data detected on this label.');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _getCardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _showNutrientDialog(String title, List<dynamic> nutrients) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: nutrients.length,
              itemBuilder: (context, index) {
                final nutrient = nutrients[index] as Map<String, dynamic>? ?? {};
                final String name = nutrient['name'] ?? 'Unknown';
                final String amount = nutrient['amount'] ?? '0';
                final String dv = nutrient['dv'] ?? '0% DV';
                final String insight = nutrient['insight'] ?? ''; // <-- Get the insight here
                return _buildDialogNutrientItem(name, amount, dv, insight: insight); // <-- Pass the insight
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildDialogNutrientItem(String name, String amount, String dv, {String? insight}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.grey[100], // Inner card color
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!)
      ),
      child: Column( // Changed to Column to hold insight
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dv,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (insight != null && insight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrientListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.grey[800], // Darker dot
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildIngredientInsights(String insights) {
    return _buildTitledSection(
      title: 'Ingredient Insights',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        // ✅ CHANGED: Use card decoration
        decoration: _getCardDecoration(),
        child: Text(
          insights,
          style: const TextStyle(
            // ✅ CHANGED: Light theme text
            color: Colors.black,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // Helper for section titles
  Widget _buildTitledSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Text(
            title,
            style: const TextStyle(
              // ✅ CHANGED: Light theme text
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

// ✅ REMOVED: _buildBottomButtons() is no longer needed.
}