import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class GoalPacePage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const GoalPacePage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<GoalPacePage> createState() => _GoalPacePageState();
}

class _GoalPacePageState extends State<GoalPacePage>
    with TickerProviderStateMixin {
  String? selectedPace;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> paceOptions = [
    {
      'title': 'Slow & Steady',
      'subtitle': 'Take your time, build lasting habits',
      'icon': FontAwesomeIcons.soap, // Using soap as sloth alternative
      'value': 'slow',
      'duration': '6-12 months',
      'color': const Color(0xFF95A5A6),
    },
    {
      'title': 'Balanced Approach',
      'subtitle': 'Steady progress with flexibility',
      'icon': FontAwesomeIcons.scaleBalanced,
      'value': 'moderate',
      'duration': '3-6 months',
      'color': AppColors.darkPrimary,
    },
    {
      'title': 'Fast Track',
      'subtitle': 'Intensive, quick results',
      'icon': FontAwesomeIcons.bolt,
      'value': 'fast',
      'duration': '1-3 months',
      'color': AppColors.darkPrimary,
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

  void _selectPace(String pace) {
    setState(() {
      selectedPace = pace;
    });
    widget.onDataUpdate(pace);
  }

  void _continue() {
    if (selectedPace != null) {
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
                              _buildPaceOptions(),
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
        FontAwesomeIcons.tachometerAlt,
        color: AppColors.primary(true),
        size: 28,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'How do you want to reach your goal?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white, // ✅ changed to white
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline, color: AppColors.darkPrimary, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Choose your preferred pace to achieve your fitness goals.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(true),
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }


  Widget _buildPaceOptions() {
    return Column(
      children: paceOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        bool isSelected = selectedPace == option['value'];

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 150)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildPaceCard(
                    option['title'],
                    option['subtitle'],
                    option['icon'],
                    option['value'],
                    option['duration'],
                    option['color'],
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

  Widget _buildPaceCard(
    String title,
    String subtitle,
    IconData icon,
    String value,
    String duration,
    Color iconColor,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _selectPace(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(
            true,
          ).withOpacity(0.9), // ✅ dark background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkPrimary : AppColors.darkGrey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.darkPrimary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? iconColor.withOpacity(0.2)
                        : AppColors.darkGrey.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? iconColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? iconColor : Colors.white70,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(true),
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
                    color: AppColors.darkPrimary,
                    size: 28,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: iconColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: iconColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Timeline: $duration',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        color: selectedPace == null
            ? AppColors.darkGrey
            : AppColors.darkPrimary,
      ),
      child: ElevatedButton(
        onPressed: selectedPace != null ? _continue : null,
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
            color: selectedPace != null ? Colors.white : Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
