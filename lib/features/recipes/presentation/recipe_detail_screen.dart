import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import '../services/recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipe;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final recipeData = await RecipeService.getRecipeById(widget.recipeId);
      if (recipeData != null) {
        // Increment view count
        RecipeService.incrementViews(widget.recipeId);
      }
      setState(() {
        recipe = recipeData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          body: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          )
              : error != null
              ? _buildErrorState(isDarkTheme)
              : recipe == null
              ? _buildNotFoundState(isDarkTheme)
              : _buildRecipeDetail(isDarkTheme),
        );
      },
    );
  }

  Widget _buildRecipeDetail(bool isDarkTheme) {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.background(isDarkTheme),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(isDarkTheme).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDarkTheme),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: recipe!['imageUrl'] != null
                ? Image.network(
              recipe!['imageUrl'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.orange.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.orange.withOpacity(0.5),
                    ),
                  ),
                );
              },
            )
                : Container(
              color: Colors.orange.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.orange.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),

        // Recipe Content
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background(isDarkTheme),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Stats
                  _buildTitleSection(isDarkTheme),
                  const SizedBox(height: 24),

                  // Quick Info
                  _buildQuickInfoSection(isDarkTheme),
                  const SizedBox(height: 32),

                  // Description
                  if (recipe!['description'] != null && recipe!['description'].isNotEmpty)
                    _buildDescriptionSection(isDarkTheme),

                  // Ingredients
                  _buildIngredientsSection(isDarkTheme),
                  const SizedBox(height: 32),

                  // Instructions
                  _buildInstructionsSection(isDarkTheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(bool isDarkTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe!['title'] ?? 'Untitled Recipe',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDifficultyColor(recipe!['difficulty']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getDifficultyColor(recipe!['difficulty']).withOpacity(0.3),
                ),
              ),
              child: Text(
                recipe!['difficulty'] ?? 'Easy',
                style: TextStyle(
                  color: _getDifficultyColor(recipe!['difficulty']),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.visibility_outlined,
              size: 16,
              color: AppColors.textSecondary(isDarkTheme),
            ),
            const SizedBox(width: 4),
            Text(
              '${recipe!['views'] ?? 0} views',
              style: TextStyle(
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickInfoSection(bool isDarkTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Prep Time',
            '${recipe!['prepTime'] ?? 0} min',
            Icons.schedule,
            Colors.blue,
            isDarkTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Cook Time',
            '${recipe!['cookTime'] ?? 0} min',
            Icons.whatshot,
            Colors.orange,
            isDarkTheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Servings',
            '${recipe!['servings'] ?? 1}',
            Icons.people,
            Colors.green,
            isDarkTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, bool isDarkTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(isDarkTheme),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDarkTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground(isDarkTheme),
                AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            recipe!['description'],
            style: TextStyle(
              color: AppColors.textSecondary(isDarkTheme),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIngredientsSection(bool isDarkTheme) {
    final ingredients = recipe!['ingredients'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cardBackground(isDarkTheme),
                AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: ingredients.asMap().entries.map((entry) {
              final index = entry.key;
              final ingredient = entry.value.toString();

              return Padding(
                padding: EdgeInsets.only(bottom: index < ingredients.length - 1 ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection(bool isDarkTheme) {
    final instructions = recipe!['instructions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value.toString();

            return Container(
              margin: EdgeInsets.only(bottom: index < instructions.length - 1 ? 16 : 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBackground(isDarkTheme),
                    AppColors.cardBackground(isDarkTheme).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      instruction,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDarkTheme),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
        return Colors.green;
    }
  }

  Widget _buildErrorState(bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Recipe',
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'Something went wrong',
              style: TextStyle(
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary(isDarkTheme),
            ),
            const SizedBox(height: 24),
            Text(
              'Recipe Not Found',
              style: TextStyle(
                color: AppColors.textPrimary(isDarkTheme),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This recipe might have been removed or doesn\'t exist.',
              style: TextStyle(
                color: AppColors.textSecondary(isDarkTheme),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
