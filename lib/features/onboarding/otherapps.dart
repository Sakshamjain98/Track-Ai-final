import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackai/core/constants/appcolors.dart';

class OtherAppsPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(String) onDataUpdate;

  const OtherAppsPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<OtherAppsPage> createState() => _OtherAppsPageState();
}

class _OtherAppsPageState extends State<OtherAppsPage>
    with TickerProviderStateMixin {
  String? selectedOption;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  void _selectOption(String option) {
    setState(() {
      selectedOption = option;
    });
    widget.onDataUpdate(option);
  }

  void _continue() {
    if (selectedOption != null) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              _buildTitle(),
                              const SizedBox(height: 24),
                              _buildSubtitle(),
                              const SizedBox(height: 48),
                              _buildOptions(),
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
    return const Text(
      'Have you tried other apps?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildSubtitle() {
    return Row(
      // mainAxisSize: MainAxisSize.min, // <-- REMOVED this line
      children: [
        // const SizedBox(width: 8), // <-- REMOVED this line
        Flexible(
          child: Text(
            'This helps us understand your experience level and provide better guidance.',
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

  Widget _buildOptions() {
    return Column(
      children: [
        _buildOption('Yes'),
        const SizedBox(height: 12),
        _buildOption('No'),
      ],
    );
  }

  Widget _buildOption(String option) {
    final isSelected = selectedOption == option;

    return GestureDetector(
      onTap: () => _selectOption(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
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
    return GestureDetector(
      onTap: selectedOption != null ? _continue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: selectedOption == null
              ? Colors
              .white // ✅ white background when disabled
              : Colors.black, // ✅ black background when enabled
          border: Border.all(
            color: selectedOption == null ? Colors.grey[300]! : Colors.black,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // <-- CHANGED to center
          children: [
            Text(
              'Next',
              style: TextStyle(
                color: selectedOption != null
                    ? Colors
                    .white // ✅ white text when enabled
                    : Colors.black, // ✅ black text when disabled
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: selectedOption != null
                  ? Colors
                  .white // ✅ white arrow when enabled
                  : Colors.black, // ✅ black arrow when disabled
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}