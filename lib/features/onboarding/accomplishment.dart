import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class AccomplishmentPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const AccomplishmentPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<AccomplishmentPage> createState() => _AccomplishmentPageState();
}

class _AccomplishmentPageState extends State<AccomplishmentPage>
    with TickerProviderStateMixin {
  String? selectedAccomplishment;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> accomplishmentOptions = [
    {
      'title': 'Eat and live healthier',
      'subtitle': 'Improve your overall lifestyle and nutrition',
      'icon': FontAwesomeIcons.appleAlt,
      'value': 'eat_healthier',
    },
    {
      'title': 'Boost my energy and mood',
      'subtitle': 'Feel more energetic and positive throughout the day',
      'icon': FontAwesomeIcons.bolt,
      'value': 'boost_energy',
    },
    {
      'title': 'Stay motivated and consistent',
      'subtitle': 'Build lasting habits and maintain momentum',
      'icon': FontAwesomeIcons.fire,
      'value': 'stay_motivated',
    },
    {
      'title': 'Feel better about my body',
      'subtitle': 'Improve body confidence and self-image',
      'icon': FontAwesomeIcons.heart,
      'value': 'feel_better',
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

  void _selectAccomplishment(String accomplishment) {
    setState(() {
      selectedAccomplishment = accomplishment;
    });
    widget.onDataUpdate(accomplishment);
  }

  void _continue() {
    if (selectedAccomplishment != null) {
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
                              _buildAccomplishmentOptions(),
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
          color: AppColors.cardBackground(true).withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.darkGrey, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'What would you like to accomplish?',
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
      'This helps us create a personalized plan to achieve your specific goals.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildAccomplishmentOptions() {
    return Column(
      children: accomplishmentOptions.map((option) {
        bool isSelected = selectedAccomplishment == option['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAccomplishmentCard(
            option['title'],
            option['subtitle'],
            option['icon'],
            option['value'],
            isSelected,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccomplishmentCard(
      String title,
      String subtitle,
      IconData icon,
      String value,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () => _selectAccomplishment(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 1,
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
        color: selectedAccomplishment == null ? Colors.grey[300] : Colors.black,
      ),
      child: ElevatedButton(
        onPressed: selectedAccomplishment != null ? _continue : null,
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
            color: selectedAccomplishment != null
                ? Colors.white
                : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
