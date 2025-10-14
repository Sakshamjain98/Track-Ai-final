import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipeLibraryScreen extends StatelessWidget {
  const RecipeLibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          body: SafeArea(
            child: Column(
              children: [
                // Enhanced Header with responsive design
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardLinearGradient(isDarkTheme),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Back button with enhanced styling
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.textSecondary(isDarkTheme).withOpacity(0.2),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppColors.textPrimary(isDarkTheme),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Title section with flexible sizing
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Recipe Library',
                                    style: TextStyle(
                                      color: AppColors.textPrimary(isDarkTheme),
                                      fontSize: screenWidth < 400 ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Discover delicious recipes from our community',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDarkTheme),
                                      fontSize: screenWidth < 400 ? 12 : 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // CDN Badge with responsive sizing
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 400 ? 6 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_done,
                                  size: screenWidth < 400 ? 12 : 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'CDN',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: screenWidth < 400 ? 9 : 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Enhanced Recipes Grid with responsive layout
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: RecipeService.getRecipesStream(),
                    builder: (context, snapshot) {
                      print('📱 StreamBuilder state: ${snapshot.connectionState}');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.orange),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Loading Recipes...',
                                style: TextStyle(
                                  color: AppColors.textPrimary(isDarkTheme),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fetching delicious recipes from Cloudinary',
                                style: TextStyle(
                                  color: AppColors.textSecondary(isDarkTheme),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('❌ StreamBuilder error: ${snapshot.error}');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(Icons.error_outline, size: 48, color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Oops! Something went wrong',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDarkTheme),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Unable to load recipes right now',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RecipeLibraryScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.refresh),
                                  label: Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final recipes = snapshot.data ?? [];
                      print('📊 Loaded ${recipes.length} recipes');

                      if (recipes.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 48,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No Recipes Yet',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDarkTheme),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to share a delicious recipe\nwith our community!',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDarkTheme),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(Icons.add),
                                  label: Text('Upload Recipe'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Responsive grid layout
                      return GridView.builder(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth < 600 ? 2 : 3,
                          crossAxisSpacing: screenWidth * 0.03,
                          mainAxisSpacing: screenWidth * 0.03,
                          childAspectRatio: screenWidth < 400 ? 0.75 : 0.8,
                        ),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return _buildEnhancedRecipeCard(context, recipe, isDarkTheme, screenWidth);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedRecipeCard(BuildContext context, Map<String, dynamic> recipe, bool isDarkTheme, double screenWidth) {
    final String? imageUrl = recipe['cardImageUrl'] ?? recipe['imageUrl'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipe['id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cardBackground(isDarkTheme),
              AppColors.cardBackground(isDarkTheme).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(isDarkTheme ? 0.02 : 0.7),
              blurRadius: 10,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: AlwaysStoppedAnimation(Colors.orange),
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Image error: $error');
                          return _buildImagePlaceholder();
                        },
                      ),
                    )
                        : _buildImagePlaceholder(),
                  ),

                  // Enhanced CDN Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            'CDN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 400 ? 7 : 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Difficulty Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(recipe['difficulty']).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _getDifficultyColor(recipe['difficulty']).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        recipe['difficulty'] ?? 'Easy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth < 400 ? 9 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with better overflow handling
                    Flexible(
                      child: Text(
                        recipe['title'] ?? 'Untitled Recipe',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: screenWidth < 400 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Enhanced Stats Row
                    Row(
                      children: [
                        // Time Info
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.access_time,
                                  size: screenWidth < 400 ? 12 : 14,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${(recipe['prepTime'] ?? 0) + (recipe['cookTime'] ?? 0)}m',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDarkTheme),
                                    fontSize: screenWidth < 400 ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Servings Info
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.people,
                                  size: screenWidth < 400 ? 12 : 14,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${recipe['servings'] ?? 1}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDarkTheme),
                                    fontSize: screenWidth < 400 ? 11 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Views count if available
                        if (recipe['views'] != null && recipe['views'] > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${recipe['views']}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: screenWidth < 400 ? 10 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_menu, size: 32, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
