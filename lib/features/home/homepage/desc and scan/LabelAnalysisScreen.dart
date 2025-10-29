import 'dart:convert';
import 'dart:io';
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
              onPressed: () {
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
                  protein: (nutrients['protein'] ?? 0).toInt(),
                  carbs: (nutrients['carbohydrates'] ?? 0).toInt(),
                  fat: (nutrients['fat'] ?? 0).toInt(),
                  fiber: (nutrients['fiber'] ?? 0).toInt(),
                  timestamp: DateTime.now(),
                  imagePath: _selectedImage?.path, // Get the path from the selected image
                );

                // 3. Add to the log
                logProvider.addEntry(entry);

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
                  'Log 1 Serving',
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
          _buildOtherNutrients(data['vitamins'], data['minerals']),

          // Ingredient Insights
          if (data['ingredientInsights'] != null)
            _buildIngredientInsights(data['ingredientInsights']),

          // ✅ ADDED: "Analyze Another" button at the end
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 24),
            child: ElevatedButton(
              onPressed: _resetAnalysis,
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
            'Calories per Serving',
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
              color: kPrimaryTeal, // Kept teal for highlight
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
                '${nutrients['protein'] ?? 0}g',
                lucide.LucideIcons.zap,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMacroTile(
                'Carbs',
                '${nutrients['carbohydrates'] ?? 0}g',
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
                '${nutrients['fat'] ?? 0}g',
                lucide.LucideIcons.droplet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMacroTile(
                'Fiber',
                '${nutrients['fiber'] ?? 0}g',
                Icons.eco,
                const Color(0xFFE37F4A),
              ),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildNutrientBreakdownList(Map<String, dynamic> nutrients) {
    return _buildTitledSection(
      title: 'Nutrient Breakdown (Per Serving)',
      child: Column(
        children: [
          _buildNutrientRow('Total Fat', '${nutrients['fat'] ?? 0}g', '0% DV'),
          _buildNutrientRow('Cholesterol', '${nutrients['cholesterol'] ?? 0}mg', '0% DV'),
          _buildNutrientRow('Sodium', '${nutrients['sodium'] ?? 0}mg', '0% DV'),
          _buildNutrientRow('Total Carbohydrate', '${nutrients['carbohydrates'] ?? 0}g', '0% DV'),
          _buildNutrientRow('Protein', '${nutrients['protein'] ?? 0}g', '0% DV'),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, String dv) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      // ✅ CHANGED: Use card decoration
      decoration: _getCardDecoration(),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              // ✅ CHANGED: Light theme text
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
                  // ✅ CHANGED: Light theme text
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dv,
                style: TextStyle(
                  // ✅ CHANGED: Light theme text
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherNutrients(List<dynamic>? vitamins, List<dynamic>? minerals) {
    vitamins = vitamins ?? []; // Default to empty list
    minerals = minerals ?? []; // Default to empty list

    List<Widget> nutrientWidgets = [];

    // Add vitamins if they exist
    if (vitamins.isNotEmpty) {
      nutrientWidgets.add(
        const Text(
          'Vitamins',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
      nutrientWidgets.add(const SizedBox(height: 8));
      nutrientWidgets.addAll(
        vitamins.map((v) => _buildNutrientListItem(v.toString())).toList(),
      );
    }

    // Add minerals if they exist
    if (minerals.isNotEmpty) {
      // Add space between the two lists
      if (nutrientWidgets.isNotEmpty) {
        nutrientWidgets.add(const SizedBox(height: 16));
      }

      nutrientWidgets.add(
        const Text(
          'Minerals',
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
      nutrientWidgets.add(const SizedBox(height: 8));
      nutrientWidgets.addAll(
        minerals.map((m) => _buildNutrientListItem(m.toString())).toList(),
      );
    }

    // Show a message if both lists are empty
    if (nutrientWidgets.isEmpty) {
      nutrientWidgets.add(
        Text(
          'No additional vitamin or mineral data available.',
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      );
    }

    // Return the section wrapped in the card
    return _buildTitledSection(
      title: 'Other Nutrients',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _getCardDecoration(),
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: nutrientWidgets,
        ),
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