import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/home/homepage/desc%20and%20scan/gemini.dart';

class FoodDescriptionScreen extends StatefulWidget {
  const FoodDescriptionScreen({Key? key}) : super(key: key);

  @override
  State<FoodDescriptionScreen> createState() => _FoodDescriptionScreenState();
}

class _FoodDescriptionScreenState extends State<FoodDescriptionScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  bool _isNotFood = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();
  final Gemini _gemini = Gemini();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

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
          _analysisResult = null;
          _isNotFood = false;
        });

        HapticFeedback.lightImpact();
        await _analyzeFood();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _gemini.describeFoodFromImage(_selectedImage!);

      // Check if it's not food
      final isNotFood = result.contains('NOT FOOD DETECTED');

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        _isNotFood = isNotFood;
      });

      _fadeController.forward();
      _slideController.forward();

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorSnackBar('Analysis failed: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _isNotFood = false;
    });
    _slideController.reset();
    _fadeController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark)),
        ),
        title: Text(
          'Describe Food',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedImage != null || _analysisResult != null)
            IconButton(
              onPressed: _resetAnalysis,
              icon: Icon(Icons.refresh, color: AppColors.darkPrimary),
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundLinearGradient(isDark),
        ),
        child: _selectedImage == null
            ? _buildImageSelector(isDark)
            : _buildAnalysisView(isDark),
      ),
    );
  }

  Widget _buildImageSelector(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.darkPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkPrimary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 60,
                color: AppColors.darkPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Describe Your Food',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Take a photo or select from gallery to get detailed food description and insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onPressed: () => _pickImage(ImageSource.camera),
                  isDark: isDark,
                ),
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: () => _pickImage(ImageSource.gallery),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDark,
    double? width,
  }) {
    return Container(
      width: width ?? 120,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildAnalysisView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 24),

          // Analysis Results
          if (_isAnalyzing) ...[
            _buildLoadingWidget(isDark),
          ] else if (_analysisResult != null) ...[
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _isNotFood
                    ? _buildNotFoodWidget(isDark)
                    : _buildFormattedAnalysis(_analysisResult!, isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPrimary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoodWidget(bool isDark) {
    final errorMessage = _extractErrorMessage(_analysisResult!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Not Food Detected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Try Again',
            onPressed: _resetAnalysis,
            isDark: isDark,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  String _extractErrorMessage(String analysis) {
    final lines = analysis.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('Error Message')) {
        if (i + 1 < lines.length) {
          return lines[i + 1].trim();
        }
      }
    }
    return 'I can only analyze food items. Please upload an image of food for analysis.';
  }

  Widget _buildFormattedAnalysis(String analysis, bool isDark) {
    final sections = _parseAnalysis(analysis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Food Name and Health Score
        if (sections['name'] != null || sections['healthScore'] != null)
          _buildHeaderSection(sections, isDark),

        const SizedBox(height: 16),

        // Description
        if (sections['description'] != null && sections['description']!.isNotEmpty)
          _buildDescriptionSection(sections['description']!, isDark),

        const SizedBox(height: 16),

        // Ingredients
        if (sections['ingredients'] != null && sections['ingredients']!.isNotEmpty)
          _buildIngredientsSection(sections['ingredients']!, isDark),

        const SizedBox(height: 16),

        // Origin
        if (sections['origin'] != null && sections['origin']!.isNotEmpty)
          _buildOriginSection(sections['origin']!, isDark),

        const SizedBox(height: 16),

        // Who Should Prefer This
        if (sections['whoShouldEat'] != null && sections['whoShouldEat']!.isNotEmpty)
          _buildWhoShouldPreferSection(sections['whoShouldEat']!, isDark),

        const SizedBox(height: 16),

        // Who Should Avoid This
        if (sections['whoShouldAvoid'] != null && sections['whoShouldAvoid']!.isNotEmpty)
          _buildWhoShouldAvoidSection(sections['whoShouldAvoid']!, isDark),

        const SizedBox(height: 16),

        // Allergen Information
        if (sections['allergens'] != null && sections['allergens']!.isNotEmpty)
          _buildAllergenSection(sections['allergens']!, isDark),

        const SizedBox(height: 16),

        // Quick Note
        if (sections['quickNote'] != null && sections['quickNote']!.isNotEmpty)
          _buildQuickNoteSection(sections['quickNote']!, isDark),

        const SizedBox(height: 24), // Extra space at bottom
      ],
    );
  }

  Map<String, String> _parseAnalysis(String analysis) {
    final Map<String, String> sections = {};
    
    // Debug print to see the raw analysis
    print('Raw analysis: $analysis');

    // Split the analysis into lines for easier parsing
    final lines = analysis.split('\n');
    
    // Simple line-by-line parsing
    String currentSection = '';
    StringBuffer currentContent = StringBuffer();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Check if this line is a section header
      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        // Save previous section if it exists
        if (currentSection.isNotEmpty && currentContent.toString().trim().isNotEmpty) {
          sections[currentSection] = currentContent.toString().trim();
        }
        
        // Start new section
        final sectionTitle = line.replaceAll('*', '').trim();
        currentContent.clear();
        
        // Map section titles to keys
        if (sectionTitle.contains('Health Score')) {
          currentSection = 'healthScore';
        } else if (sectionTitle.contains('Description')) {
          currentSection = 'description';
        } else if (sectionTitle.contains('Primary Ingredients')) {
          currentSection = 'ingredients';
        } else if (sectionTitle.contains('Origin')) {
          currentSection = 'origin';
        } else if (sectionTitle.contains('Who Should Prefer')) {
          currentSection = 'whoShouldEat';
        } else if (sectionTitle.contains('Who Should Avoid')) {
          currentSection = 'whoShouldAvoid';
        } else if (sectionTitle.contains('Allergen')) {
          currentSection = 'allergens';
        } else if (sectionTitle.contains('Quick Note')) {
          currentSection = 'quickNote';
        } else if (!sectionTitle.contains('Health Score') && sections['name'] == null) {
          // First non-health score section is likely the food name
          sections['name'] = sectionTitle;
          currentSection = '';
        }
      } else if (currentSection.isNotEmpty) {
        // Add content to current section
        if (line.isNotEmpty) {
          if (currentContent.isNotEmpty) {
            currentContent.writeln();
          }
          currentContent.write(line);
        }
      } else if (currentSection == 'healthScore' && line.contains('/10')) {
        // Extract health score
        final scoreMatch = RegExp(r'(\d+/10)').firstMatch(line);
        if (scoreMatch != null) {
          sections['healthScore'] = scoreMatch.group(1) ?? '';
        }
      }
    }
    
    // Don't forget the last section
    if (currentSection.isNotEmpty && currentContent.toString().trim().isNotEmpty) {
      sections[currentSection] = currentContent.toString().trim();
    }
    
    // Special handling for health score if not found yet
    if (sections['healthScore'] == null) {
      for (final line in lines) {
        if (line.contains('/10')) {
          final scoreMatch = RegExp(r'(\d+/10)').firstMatch(line);
          if (scoreMatch != null) {
            sections['healthScore'] = scoreMatch.group(1) ?? '';
            break;
          }
        }
      }
    }

    // Debug print to see parsed sections
    print('Parsed sections: $sections');

    return sections;
  }

  Widget _buildHeaderSection(Map<String, String> sections, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.darkPrimary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Identified as',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sections['name'] ?? 'Unknown Food',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description, bool isDark) {
    return _buildInfoCard(
      title: 'Description',
      icon: Icons.description,
      content: description,
      isDark: isDark,
    );
  }

  Widget _buildIngredientsSection(String ingredients, bool isDark) {
    final ingredientList = ingredients
        .split('*')
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim())
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: AppColors.darkPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Primary Ingredients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredientList
                .map(
                  (ingredient) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.darkPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginSection(String origin, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.public, color: AppColors.darkPrimary, size: 20),
          const SizedBox(width: 12),
          Text(
            'Origin',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const Spacer(),
          Text(
            origin.trim(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoShouldPreferSection(String content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Who Should Prefer This',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoints(content, isDark, Colors.green),
        ],
      ),
    );
  }

  Widget _buildWhoShouldAvoidSection(String content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Who Should Avoid This',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBulletPoints(content, isDark, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildAllergenSection(String content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Allergen Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.trim(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary(isDark),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoints(String content, bool isDark, MaterialColor color) {
    // Split by bullet points (•) or newlines
    List<String> points = content
        .split(RegExp(r'[•\n]'))
        .where((point) => point.trim().isNotEmpty)
        .map((point) => point.trim())
        .toList();

    // If no bullet points found, try splitting by periods followed by capital letters
    if (points.length <= 1) {
      points = content
          .split(RegExp(r'\.(?=\s*[A-Z])'))
          .where((point) => point.trim().isNotEmpty)
          .map((point) => point.trim())
          .toList();
    }

    // Ensure we have at least some points
    if (points.isEmpty) {
      points = [content.trim()];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary(isDark),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQuickNoteSection(String note, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.darkPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            note.trim(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary(isDark),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.darkPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.trim(),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary(isDark),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}