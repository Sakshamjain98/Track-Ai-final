import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';

class DateOfBirthPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(DateTime) onDataUpdate;

  const DateOfBirthPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
  }) : super(key: key);

  @override
  State<DateOfBirthPage> createState() => _DateOfBirthPageState();
}

class _DateOfBirthPageState extends State<DateOfBirthPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime? selectedDate;
  final DateTime minDate = DateTime(1920);
  final DateTime maxDate = DateTime.now().subtract(
    const Duration(days: 365 * 13),
  ); // Minimum 13 years old

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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(1995),
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.darkPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              background: Colors.white,
              onBackground: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      widget.onDataUpdate(picked);
    }
  }

  void _continue() {
    if (selectedDate != null) {
      widget.onNext();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              const SizedBox(height: 40),
                              _buildTitle(),
                              const SizedBox(height: 24),
                              _buildSubtitle(),
                              const SizedBox(height: 40),
                              _buildDateSelector(),
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
          color: Colors.white, // ✅ white background
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black, // ✅ black arrow
          size: 20,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'When were you born?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black, // ✅ black text
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.start,
    );
  }



  Widget _buildSubtitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.info_outline, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'This helps us provide age-appropriate recommendations.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }


  Widget _buildDateSelector() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: selectedDate != null
                    ? Colors.black
                    : Colors.white, // ✅ white to black
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedDate != null
                      ? Colors.black
                      : Colors.grey[300]!,
                  width: selectedDate != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: selectedDate != null ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!)
                        : 'Select your date of birth',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null
                          ? Colors.white
                          : Colors.black, // ✅ black to white
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_calculateAge(selectedDate!)} years old',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (selectedDate == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap to open calendar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600], // ✅ darker grey for visibility
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(

            child: Row(
              children: [
                Icon(Icons.security, color: AppColors.primary(true), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your personal information is securely stored and never shared',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary(true),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: selectedDate == null
            ? Colors
                  .white // ✅ white when disabled
            : Colors.black, // ✅ black when enabled
        border: Border.all(
          color: selectedDate == null ? Colors.grey[300]! : Colors.black,
          width: 1,
        ),
      ),
      child: ElevatedButton(
        onPressed: selectedDate != null ? _continue : null,
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
            color: selectedDate != null
                ? Colors
                      .white // ✅ white text when enabled
                : Colors.black, // ✅ black text when disabled
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
