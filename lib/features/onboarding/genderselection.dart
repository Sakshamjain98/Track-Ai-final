import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';

class GenderSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final Function(String) onDataUpdate;

  const GenderSelectionPage({
    Key? key,
    required this.onNext,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<GenderSelectionPage> createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage>
    with TickerProviderStateMixin {
  String? selectedGender;
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

  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
    widget.onDataUpdate(gender);
  }

  void _continue() {
    if (selectedGender != null) {
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
                      // Header with back button and progress

                      SizedBox(height: screenHeight * 0.04),

                      // Main content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitle(),
                              SizedBox(height: screenHeight * 0.01),
                              _buildSubtitle(),
                              SizedBox(height: screenHeight * 0.05),
                              _buildGenderOptions(),
                            ],
                          ),
                        ),
                      ),

                      // Bottom button
                      SizedBox(height: screenHeight * 0.02),
                      _buildNextButton(),
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


  Widget _buildTitle() {
    return const Text(
      'Choose your Gender',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.2,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'This will be used to calibrate your custom plan.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildGenderOptions() {
    return Column(
      children: [
        _buildGenderOption('Male'),
        const SizedBox(height: 16),
        _buildGenderOption('Female'),
        const SizedBox(height: 16),
        _buildGenderOption('Other'),
      ],
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () => _selectGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          gender,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.start,
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
        color: selectedGender == null ? Colors.grey[300] : Colors.black,
      ),
      child: ElevatedButton(
        onPressed: selectedGender != null ? _continue : null,
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
            color: selectedGender != null ? Colors.white : Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
