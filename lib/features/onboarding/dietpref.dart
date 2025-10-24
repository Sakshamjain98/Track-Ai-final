import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class DietPreferencePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const DietPreferencePage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<DietPreferencePage> createState() => _DietPreferencePageState();
}

class _DietPreferencePageState extends State<DietPreferencePage>
    with TickerProviderStateMixin {
  String? selectedDiet;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> dietOptions = [
    {
      'title': 'Classic',
      'subtitle': 'Balanced diet with all food groups',
      'icon': FontAwesomeIcons.utensils,
      'value': 'classic',
      'color': AppColors.darkPrimary,
      'description': 'Includes all food groups for balanced nutrition',
    },
    {
      'title': 'Vegetarian',
      'subtitle': 'Plant-based with dairy and eggs',
      'icon': FontAwesomeIcons.leaf,
      'value': 'vegetarian',
      'color': const Color(0xFF27AE60),
      'description': 'No meat, but includes dairy products and eggs',
    },
    {
      'title': 'Vegan',
      'subtitle': 'Fully plant-based diet',
      'icon': FontAwesomeIcons.seedling,
      'value': 'vegan',
      'color': const Color(0xFF2ECC71),
      'description': 'Completely plant-based, no animal products',
    },
    {
      'title': 'Non-Vegetarian',
      'subtitle': 'Includes meat, fish, and poultry',
      'icon': FontAwesomeIcons.drumstickBite,
      'value': 'non_vegetarian',
      'color': const Color(0xFFE67E22),
      'description': 'All foods including meat and seafood',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDiet(String diet) {
    setState(() {
      selectedDiet = diet;
    });
    widget.onDataUpdate(diet);
  }

  void _continue() {
    if (selectedDiet != null) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Column(
                    children: [
                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(),
                              SizedBox(height: screenHeight * 0.01),
                              _buildSubtitle(),
                              SizedBox(height: screenHeight * 0.04),
                              _buildDietOptions(),
                            ],
                          ),
                        ),
                      ),

                      // Bottom buttons row
                      SizedBox(height: screenHeight * 0.02),
                      Row(
                        children: [
                          _buildBackButton(),
                          const SizedBox(width: 16),
                          Expanded(child: _buildNextButton()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'What diet do you follow?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Tell us about your dietary preferences for personalized meal recommendations.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildDietOptions() {
    return Column(
      children: dietOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        bool isSelected = selectedDiet == option['value'];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDietCard(
                    option['title'],
                    option['subtitle'],
                    option['icon'],
                    option['value'],
                    option['color'],
                    option['description'],
                    isSelected,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDietCard(
      String title,
      String subtitle,
      IconData icon,
      String value,
      Color iconColor,
      String description,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () => _selectDiet(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: selectedDiet == null ? Colors.grey[300] : Colors.black,
      ),
      child: ElevatedButton(
        onPressed: selectedDiet != null ? _continue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          'Next',
          style: TextStyle(
            color: selectedDiet != null ? Colors.white : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
