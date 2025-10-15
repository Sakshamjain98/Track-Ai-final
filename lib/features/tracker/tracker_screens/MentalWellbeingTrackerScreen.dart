import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class MentalWellbeingTrackerScreen extends StatefulWidget {
  const MentalWellbeingTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MentalWellbeingTrackerScreen> createState() => _MentalWellbeingTrackerScreenState();
}

class _MentalWellbeingTrackerScreenState extends State<MentalWellbeingTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _triggersController = TextEditingController();
  final _copingController = TextEditingController();

  int _wellbeingValue = 3;
  int _stressLevel = 5;

  final List<Map<String, TextEditingController>> _customFields = [];

  bool _isLoading = false;

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields.removeAt(index);
    });
  }

  void _clearForm() {
    _triggersController.clear();
    _copingController.clear();
    setState(() {
      _wellbeingValue = 3;
      _stressLevel = 5;
    });

    for (var field in _customFields) {
      field['key']?.clear();
      field['value']?.clear();
    }

    setState(() {
      _customFields.clear();
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customData = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }

      final entryData = {
        'wellbeingValue': _wellbeingValue,
        'stressLevel': _stressLevel,
        'triggers': _triggersController.text.trim(),
        'copingMechanisms': _copingController.text.trim(),
        'customData': customData,
        'trackerType': 'mentalwellbeing',
      };

      await TrackerService.saveTrackerEntry('mentalwellbeing', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mental well-being entry saved successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: AppColors.errorColor,
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

  @override
  void dispose() {
    _triggersController.dispose();
    _copingController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.cardBackground(isDark),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            title: Text(
              'Log Mental Well-being Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the details for your mental well-being tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Well-being Value (1-5 scale)
                    _buildDropdownField(
                      label: 'Value (1-5 scale)',
                      value: _wellbeingValue,
                      items: List.generate(5, (index) => index + 1),
                      onChanged: (value) => setState(() => _wellbeingValue = value!),
                      isDark: isDark,
                      hint: 'Select well-being (1-5)',
                    ),

                    const SizedBox(height: 16),

                    // Stress Level (1-10)
                    _buildDropdownField(
                      label: 'Stress (1-10)',
                      value: _stressLevel,
                      items: List.generate(10, (index) => index + 1),
                      onChanged: (value) => setState(() => _stressLevel = value!),
                      isDark: isDark,
                      hint: 'Rate your stress level',
                    ),

                    const SizedBox(height: 16),

                    // Triggers
                    _buildTextField(
                      controller: _triggersController,
                      label: 'Triggers',
                      hint: 'Any specific triggers?',
                      maxLines: 3,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Coping Mechanisms
                    _buildTextField(
                      controller: _copingController,
                      label: 'Coping Mechanisms',
                      hint: 'What helped you cope?',
                      maxLines: 3,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Custom Data Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Custom Data',
                          style: TextStyle(
                            color: AppColors.textPrimary(isDark),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addCustomField,
                          icon: Icon(
                            Icons.add,
                            color: AppColors.black,
                            size: 16,
                          ),
                          label: Text(
                            'Add Custom Field',
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Custom Fields
                    ..._customFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final field = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderColor(isDark),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: field['key']!,
                                    label: 'Field Name',
                                    hint: 'e.g., Mood',
                                    isDark: isDark,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeCustomField(index),
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.errorColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: field['value']!,
                              label: 'Field Value',
                              hint: 'e.g., Anxious',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: AppColors.white,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: AppColors.white,
                            ),
                            child: Text(
                              'Clear Form',
                              style: TextStyle(
                                color: AppColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                                : const Text(
                              'Save Entry',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
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
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int value,
    required List<int> items,
    required void Function(int?) onChanged,
    required bool isDark,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.black, width: 2),
            ),
          ),
          dropdownColor: AppColors.cardBackground(isDark),
        ),
      ],
    );
  }
}
