import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class GoalSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const GoalSelectionPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionPage>
    with TickerProviderStateMixin {
  String? selectedGoal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> goalOptions = [
    {
      'title': 'Lose Weight',
      'subtitle': 'Burn fat and get leaner',
      'icon': FontAwesomeIcons.weightScale,
      'value': 'lose_weight',
    },
    {
      'title': 'Maintain Weight',
      'subtitle': 'Stay at your current weight',
      'icon': FontAwesomeIcons.balanceScale,
      'value': 'maintain_weight',
    },
    {
      'title': 'Gain Weight',
      'subtitle': 'Build muscle and bulk up',
      'icon': FontAwesomeIcons.dumbbell,
      'value': 'gain_weight',
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

  void _selectGoal(String goal) {
    setState(() {
      selectedGoal = goal;
    });
    widget.onDataUpdate(goal);
  }

  void _continue() {
    if (selectedGoal != null) {
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            // THIS IS THE CHANGE to align children left
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _buildTitle(),
                              const SizedBox(height: 24),
                              _buildSubtitle(),
                              const SizedBox(height: 48),
                              _buildGoalOptions(),
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

  Widget _buildTitle() {
    // This widget was already correct with textAlign.start
    return const Text(
      'What\'s your goal?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildSubtitle() {
    // I simplified this Row to ensure it fills the width
    return Row(
      children: [
        Flexible(
          child: Text(
            'Choose your primary fitness goal to get personalized recommendations.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary(true),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalOptions() {
    return Column(
      children: goalOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        bool isSelected = selectedGoal == option['value'];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildGoalCard(
                    option['title'],
                    option['subtitle'],
                    option['icon'],
                    option['value'],
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

  Widget _buildGoalCard(
      String title,
      String subtitle,
      IconData icon,
      String value,
      bool isSelected,
      ) {
    return GestureDetector(
      onTap: () => _selectGoal(value),
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
                color: isSelected ? Colors.white : AppColors.primary(true),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
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
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
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
        color: selectedGoal == null ? Colors.grey[300] : Colors.black,
      ),
      child: ElevatedButton(
        onPressed: selectedGoal != null ? _continue : null,
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
            color: selectedGoal == null ? Colors.grey[600] : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}