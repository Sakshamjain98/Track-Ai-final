import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/core/utils/snackbar_helper.dart';
import '../services/recipe_service.dart';
import 'dart:io';

class AdminRecipeUploadScreen extends StatefulWidget {
  const AdminRecipeUploadScreen({Key? key}) : super(key: key);

  @override
  State<AdminRecipeUploadScreen> createState() => _AdminRecipeUploadScreenState();
}

class _AdminRecipeUploadScreenState extends State<AdminRecipeUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();

  String _selectedDifficulty = 'Easy';
  // 1. New State Variable for Category
  String _selectedCategory = 'Main Course';
  XFile? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  // 2. List of Categories
  final List<String> _categories = [
    'Appetizers',
    'Main Course',
    'Desserts',
    'Breakfast',
    'Salads',
    'Soups',
    'Beverages',
    'Snacks',
  ];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        SnackBarHelper.showSuccess(context, '✅ Image selected: ${image.name}');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      SnackBarHelper.showError(context, 'Please select a food category.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      setState(() => _uploadProgress = 0.2);

      final ingredients = _ingredientsController.text
          .split('\n')
          .where((ingredient) => ingredient.trim().isNotEmpty)
          .toList();

      final instructions = _instructionsController.text
          .split('\n')
          .where((instruction) => instruction.trim().isNotEmpty)
          .toList();

      setState(() => _uploadProgress = 0.4);

      // Create recipe
      final recipeId = await RecipeService.createRecipe(
        title: _titleController.text,
        description: _descriptionController.text,
        ingredients: ingredients,
        instructions: instructions,
        difficulty: _selectedDifficulty,
        prepTime: int.tryParse(_prepTimeController.text) ?? 0,
        cookTime: int.tryParse(_cookTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        imageFile: _selectedImage,
        // 4. Pass the selected category to the service
        category: _selectedCategory,
      );

      setState(() => _uploadProgress = 1.0);

      SnackBarHelper.showSuccess(context, '🎉 Recipe uploaded successfully!');
      _clearForm();
    } catch (e) {
      SnackBarHelper.showError(context, e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _ingredientsController.clear();
    _instructionsController.clear();
    _prepTimeController.clear();
    _cookTimeController.clear();
    _servingsController.clear();
    setState(() {
      _selectedImage = null;
      _selectedDifficulty = 'Easy';
      // 5. Reset the selected category
      _selectedCategory = 'Main Course';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        // final screenHeight = MediaQuery.of(context).size.height; // Not strictly needed

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDarkTheme),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary(isDarkTheme), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange, Colors.orange.shade600]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.upload, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Upload Recipe',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDarkTheme),
                        fontSize: screenWidth < 400 ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 400 ? 8 : 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green, Colors.green.shade600]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public,
                        size: screenWidth < 400 ? 14 : 16,
                        color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Public',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth < 400 ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDarkTheme),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Compact Header Card
                    _buildHeaderCard(isDarkTheme, screenWidth),
                    const SizedBox(height: 16),

                    // Upload Progress (compact)
                    if (_isUploading) _buildUploadProgress(isDarkTheme, screenWidth),

                    // Image Upload Section (optimized height)
                    _buildImageUpload(isDarkTheme, screenWidth),
                    const SizedBox(height: 16),

                    // Basic Info (compact)
                    _buildBasicInfo(isDarkTheme, screenWidth),
                    const SizedBox(height: 16),

                    // *** 3. NEW CATEGORY SELECTION SECTION ***
                    _buildCategorySelection(isDarkTheme, screenWidth),
                    const SizedBox(height: 16),
                    // ***************************************

                    // Recipe Details (streamlined)
                    _buildRecipeDetails(isDarkTheme, screenWidth),
                    const SizedBox(height: 16),

                    // Ingredients & Instructions (optimized)
                    _buildIngredientsInstructions(isDarkTheme, screenWidth),
                    const SizedBox(height: 24),

                    // Upload Button (normal height)
                    _buildUploadButton(isDarkTheme, screenWidth),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // *** NEW WIDGET FOR CATEGORY SELECTION ***
  Widget _buildCategorySelection(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food Category',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: screenWidth < 400 ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Use a Wrap for a responsive layout of chips
          Wrap(
            spacing: 8.0, // horizontal spacing between chips
            runSpacing: 8.0, // vertical spacing between lines of chips
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  }
                },
                selectedColor: Colors.blue.withOpacity(0.8),
                backgroundColor: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary(isDarkTheme),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: screenWidth < 400 ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.blue.shade700 : AppColors.borderColor(isDarkTheme),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  // *********************************************

  Widget _buildHeaderCard(bool isDarkTheme, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green, Colors.green.shade600]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Recipe Admin Pannel',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: screenWidth < 400 ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Upload directly!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: screenWidth < 400 ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 400 ? 6 : 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CDN',
              style: TextStyle(
                color: Colors.blue,
                fontSize: screenWidth < 400 ? 9 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(bool isDarkTheme, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploading Recipe...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: screenWidth < 400 ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Image → Cloudinary | Data → Firestore',
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.8),
                        fontSize: screenWidth < 400 ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.orange.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.orange),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUpload(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recipe Image',
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: screenWidth < 400 ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '→ Cloudinary CDN',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: screenWidth < 400 ? 9 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: screenWidth < 400 ? 140 : 160, // Responsive height
              decoration: BoxDecoration(
                color: _selectedImage != null ? Colors.transparent : Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_photo_alternate,
                        size: screenWidth < 400 ? 32 : 40,
                        color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add recipe image',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDarkTheme),
                      fontSize: screenWidth < 400 ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'click now!',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: screenWidth < 400 ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: screenWidth < 400 ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Recipe Title',
              hintText: 'Enter recipe name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
            validator: (value) => value?.trim().isEmpty == true ? 'Title required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Brief recipe description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
            maxLines: 3,
            validator: (value) => value?.trim().isEmpty == true ? 'Description required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeDetails(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipe Details',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: screenWidth < 400 ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Difficulty Selection
          Text(
            'Difficulty Level',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: screenWidth < 400 ? 13 : 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _difficulties.map((difficulty) {
              final isSelected = _selectedDifficulty == difficulty;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = difficulty),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(
                      vertical: screenWidth < 400 ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [Colors.orange, Colors.orange.shade600])
                          : null,
                      color: !isSelected ? Colors.grey.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary(isDarkTheme),
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth < 400 ? 13 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Time & Servings in responsive grid
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prepTimeController,
                  decoration: InputDecoration(
                    labelText: 'Prep (min)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _cookTimeController,
                  decoration: InputDecoration(
                    labelText: 'Cook (min)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _servingsController,
                  decoration: InputDecoration(
                    labelText: 'Servings',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.trim().isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsInstructions(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients & Instructions',
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: screenWidth < 400 ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ingredientsController,
            decoration: InputDecoration(
              labelText: 'Ingredients',
              hintText: 'One ingredient per line\n2 cups flour\n1 tsp salt',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
            maxLines: screenWidth < 400 ? 4 : 5, // Responsive lines
            validator: (value) => value?.trim().isEmpty == true ? 'Ingredients required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              labelText: 'Instructions',
              hintText: 'One step per line\nPreheat oven to 350°F\nMix ingredients',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: screenWidth < 400 ? 14 : 16),
            maxLines: screenWidth < 400 ? 5 : 6, // Responsive lines
            validator: (value) => value?.trim().isEmpty == true ? 'Instructions required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(bool isDarkTheme, double screenWidth) {
    return Container(
      width: double.infinity,
      height: 50, // Normal button height
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading ? null : _uploadRecipe,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isUploading
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Uploading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth < 400 ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.publish, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Share Recipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth < 400 ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}