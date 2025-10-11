import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/home/homepage/desc%20and%20scan/gemini.dart';

class ImageAnalysisScreen extends StatefulWidget {
  final String analysisType; // 'scan' or 'describe'
  
  const ImageAnalysisScreen({
    Key? key,
    required this.analysisType,
  }) : super(key: key);

  @override
  State<ImageAnalysisScreen> createState() => _ImageAnalysisScreenState();
}

class _ImageAnalysisScreenState extends State<ImageAnalysisScreen>
    with TickerProviderStateMixin {
  File? _selectedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(40, 50, 49, 0.85),
            const Color.fromARGB(215, 14, 14, 14),
            Color.fromRGBO(33, 43, 42, 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
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
        gradient: LinearGradient(
          colors: [
            AppColors.lightSecondary.withOpacity(0.85),
            AppColors.lightSecondary.withOpacity(0.85),
            AppColors.lightSecondary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
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

  Future<void> _showImageSourceDialog(bool isDark) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.primary(isDark).withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Text(
            'Select Image Source',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.primary(isDark),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.primary(isDark),
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _analysisResult = null;
        });
        _slideAnimationController.forward();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final geminiService = Gemini();
      String result;

      if (widget.analysisType == 'scan') {
        result = await geminiService.analyzeNutritionFromImage(_selectedImage!);
      } else {
        result = await geminiService.describeFoodFromImage(_selectedImage!);
      }

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = 'Error analyzing image: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  String get _getTitle {
    return widget.analysisType == 'scan' 
        ? 'Nutrition Scanner' 
        : 'Food Descriptor';
  }

  String get _getSubtitle {
    return widget.analysisType == 'scan'
        ? 'Scan food items to get detailed nutrition information'
        : 'Describe your food to get comprehensive details';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary(isDark),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _getTitle,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundLinearGradient(isDark),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDark),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      decoration: _getCardDecoration(isDark),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            widget.analysisType == 'scan'
                                ? Icons.qr_code_scanner
                                : Icons.restaurant_menu,
                            size: 48,
                            color: AppColors.primary(isDark),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Image Selection Button
                    Container(
                      decoration: _getCardDecoration(isDark),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showImageSourceDialog(isDark),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: AppColors.primary(isDark),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Select Image',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Camera or Gallery',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Selected Image Display
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 24),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          decoration: _getCardDecoration(isDark),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isAnalyzing ? null : _analyzeImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary(isDark),
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isAnalyzing
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Analyzing...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          widget.analysisType == 'scan'
                                              ? 'Analyze Nutrition'
                                              : 'Describe Food',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Analysis Result
                    if (_analysisResult != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        decoration: _getCardDecoration(isDark),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: AppColors.primary(isDark),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analysis Result',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary(isDark).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _analysisResult!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}