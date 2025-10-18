import 'package:flutter/material.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/onboarding/service/observices.dart';

class SetYourTargetPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final bool isMetric;
  final String goal;

  const SetYourTargetPage({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.onDataUpdate,
    required this.isMetric,
    required this.goal,
  }) : super(key: key);

  @override
  State<SetYourTargetPage> createState() => _SetYourTargetPageState();
}

class _SetYourTargetPageState extends State<SetYourTargetPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _timeframeController = TextEditingController();

  String selectedUnit = 'kg';
  bool _isNextEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedUnit = widget.isMetric ? 'kg' : 'lbs';
    _amountController.addListener(_validateInputs);
    _timeframeController.addListener(_validateInputs);
  }

  void _validateInputs() {
    setState(() {
      _isNextEnabled =
          _amountController.text.isNotEmpty &&
              _timeframeController.text.isNotEmpty &&
              double.tryParse(_amountController.text) != null &&
              int.tryParse(_timeframeController.text) != null;
    });
  }

  void _handleNext() async {
    if (_isNextEnabled && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        double amount = double.parse(_amountController.text);
        double amountKg;
        double amountLbs;

        if (selectedUnit == 'kg') {
          amountKg = amount;
          amountLbs = amount * 2.20462;
        } else {
          amountLbs = amount;
          amountKg = amount / 2.20462;
        }

        final targetData = {
          'targetAmountKg': amountKg,
          'targetAmountLbs': amountLbs,
          'targetUnit': selectedUnit,
          'targetTimeframe': int.parse(_timeframeController.text),
        };

        // Save target data to Firebase
        await OnboardingService.updateOnboardingData(targetData);

        // Update parent widget with the data
        widget.onDataUpdate(targetData);

        // Navigate to next page
        widget.onNext();
      } catch (e) {
        print('Error saving target data: $e');
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save data. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Set Your Target',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // Subtitle
                      Text(
                        'Specifics help us create a precise plan and give you feedback on a healthy rate of change.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // Amount to Gain/Lose
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.goal == 'gain_weight'
                                ? 'Amount to Gain'
                                : 'Amount to Lose',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedUnit,
                                      isExpanded: true,
                                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      dropdownColor: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      items: ['kg', 'lbs'].map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedUnit = newValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Timeframe
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Timeframe (in weeks)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _timeframeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  GestureDetector(
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: (_isNextEnabled && !_isLoading)
                            ? Colors.black
                            : Colors.grey[300],
                      ),
                      child: ElevatedButton(
                        onPressed: (_isNextEnabled && !_isLoading)
                            ? _handleNext
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          'Next',
                          style: TextStyle(
                            color: (_isNextEnabled && !_isLoading)
                                ? Colors.white
                                : Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
