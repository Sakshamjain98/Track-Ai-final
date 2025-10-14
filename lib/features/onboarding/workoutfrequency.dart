import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class WorkoutFrequencyPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const WorkoutFrequencyPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<WorkoutFrequencyPage> createState() => _WorkoutFrequencyPageState();
}

class _WorkoutFrequencyPageState extends State<WorkoutFrequencyPage>
    with TickerProviderStateMixin {
  String? selectedFrequency;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> frequencyOptions = [
    {
      'title': '0-2 times',
      'subtitle': 'Workout now and then',
      'icon': FontAwesomeIcons.leaf,
      'value': 'beginner',
    },
    {
      'title': '3-5 times',
      'subtitle': 'A few times a week',
      'icon': FontAwesomeIcons.dumbbell,
      'value': 'intermediate',
    },
    {
      'title': '6+ times',
      'subtitle': 'Dedicated athlete',
      'icon': FontAwesomeIcons.medal,
      'value': 'advanced',
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

  void _selectFrequency(String frequency) {
    setState(() {
      selectedFrequency = frequency;
    });
    widget.onDataUpdate(frequency);
  }

  void _continue() {
    if (selectedFrequency != null) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              _buildIcon(),
                              const SizedBox(height: 40),
                              _buildTitle(),
                              const SizedBox(height: 24),
                              _buildSubtitle(),
                              const SizedBox(height: 48),
                              _buildFrequencyOptions(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),

                      // Bottom buttons row
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
          color: Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary(true).withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary(true), width: 0.5),
      ),
      child: Icon(
        FontAwesomeIcons.heartPulse,
        color: AppColors.primary(true),
        size: 28,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Describe your activity level',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, color: AppColors.primary(true), size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'This helps us create a personalized fitness plan for you.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary(true),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }


  Widget _buildFrequencyOptions() {
    return Column(
      children: frequencyOptions.map((option) {
        bool isSelected = selectedFrequency == option['value'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFrequencyCard(
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

  Widget _buildFrequencyCard(
    String title,
    String subtitle,
    IconData icon,
    String value,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _selectFrequency(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: selectedFrequency == null ? Colors.grey[300] : Colors.black,
      ),
      child: ElevatedButton(
        onPressed: selectedFrequency != null ? _continue : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          'Next',
          style: TextStyle(
            color: selectedFrequency != null ? Colors.white : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
