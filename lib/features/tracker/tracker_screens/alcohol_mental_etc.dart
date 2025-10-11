import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class AlcoholTrackerScreen extends StatefulWidget {
  const AlcoholTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AlcoholTrackerScreen> createState() => _AlcoholTrackerScreenState();
}

class _AlcoholTrackerScreenState extends State<AlcoholTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _occasionController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  int _selectedCraving = 3;
  String? _selectedDrinkType;

  final List<String> drinkTypes = ['Beer', 'Wine', 'Cocktail', 'Whiskey', 'Vodka', 'Rum', 'Champagne', 'Other'];

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
        'value': double.parse(_valueController.text),
        'drinkType': _selectedDrinkType ?? '',
        'occasion': _occasionController.text.trim(),
        'craving': _selectedCraving,
        'customData': customData,
        'trackerType': 'alcohol',
      };

      await TrackerService.saveTrackerEntry('alcohol', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Alcohol entry saved successfully!'), backgroundColor: AppColors.successColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e'), backgroundColor: AppColors.errorColor),
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
              icon: Icon(Icons.arrow_back, color: AppColors.black),
            ),
            title: Text(
              'Log Alcohol Tracker',
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
                      'Enter the details for your alcohol tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _valueController,
                      label: 'Value (drinks)',
                      hint: 'Number of drinks consumed',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter number of drinks';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Drink Type',
                      value: _selectedDrinkType,
                      hint: 'Select drink type',
                      items: drinkTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedDrinkType = value;
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _occasionController,
                      label: 'Occasion',
                      hint: 'What was the occasion? (e.g., dinner, party, relaxing)',
                      maxLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildCravingScale(isDark),
                    const SizedBox(height: 24),
                    _buildCustomDataSection(isDark),
                    const SizedBox(height: 32),
                    _buildActionButtons(isDark),
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
    String? Function(String?)? validator,
    int maxLines = 1,
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

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    String? value,
    String? hint,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor(isDark)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint ?? 'Select $label',
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              border: InputBorder.none,
            ),
            dropdownColor: AppColors.cardBackground(isDark),
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildCravingScale(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Craving (1-5)',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(isDark)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your craving level',
                style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final number = index + 1;
                  final isSelected = number == _selectedCraving;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCraving = number;
                      });
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            color: isSelected ? AppColors.white : AppColors.textSecondary(isDark),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Low',
                    style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                  ),
                  Text(
                    'High',
                    style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDataSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () {
                setState(() {
                  _customFields.add({'key': TextEditingController(), 'value': TextEditingController()});
                });
              },
              icon: Icon(Icons.add, color: AppColors.black, size: 16),
              label: Text(
                'Add Custom Field',
                style: TextStyle(color: AppColors.black, fontSize: 14),
              ),
            ),
          ],
        ),
        ..._customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor(isDark)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: field['key']!,
                        label: 'Field Name',
                        hint: 'e.g., Location',
                        isDark: isDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          field['key']?.dispose();
                          field['value']?.dispose();
                          _customFields.removeAt(index);
                        });
                      },
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: field['value']!,
                  label: 'Field Value',
                  hint: 'e.g., Home',
                  isDark: isDark,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: AppColors.white,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _valueController.clear();
              _occasionController.clear();
              setState(() {
                _selectedDrinkType = null;
                _selectedCraving = 3;
                for (var field in _customFields) {
                  field['key']?.clear();
                  field['value']?.clear();
                }
                _customFields.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: AppColors.white,
            ),
            child: Text(
              'Clear Form',
              style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Text(
                    'Save Entry',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class StudyTrackerScreen extends StatefulWidget {
  const StudyTrackerScreen({Key? key}) : super(key: key);

  @override
  State<StudyTrackerScreen> createState() => _StudyTrackerScreenState();
}

class _StudyTrackerScreenState extends State<StudyTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  int _selectedFocus = 5;

  final List<String> locations = ['Home', 'Library', 'Coffee Shop', 'School', 'Office', 'Other'];

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
        'value': double.parse(_valueController.text),
        'subjectTopic': _subjectController.text.trim(),
        'focusLevel': _selectedFocus,
        'location': _locationController.text.trim(),
        'customData': customData,
        'trackerType': 'study',
      };

      await TrackerService.saveTrackerEntry('study', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Study entry saved successfully!'), backgroundColor: AppColors.successColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e'), backgroundColor: AppColors.errorColor),
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
              icon: Icon(Icons.arrow_back, color: AppColors.black),
            ),
            title: Text(
              'Log Study Time Tracker',
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
                      'Enter the details for your study time tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _valueController,
                      label: 'Value (hours)',
                      hint: 'Study duration in hours',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter study duration';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _subjectController,
                      label: 'Subject/Topic',
                      hint: 'What did you study? (e.g., Mathematics, History)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildFocusScale(isDark),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Location',
                      value: _locationController.text.isEmpty ? null : _locationController.text,
                      items: locations,
                      onChanged: (value) {
                        setState(() {
                          _locationController.text = value ?? '';
                        });
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    _buildCustomDataSection(isDark),
                    const SizedBox(height: 32),
                    _buildActionButtons(isDark),
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

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
    String? value,
    String? hint,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor(isDark)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint ?? 'Select $label',
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              border: InputBorder.none,
            ),
            dropdownColor: AppColors.cardBackground(isDark),
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusScale(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus Level (1-10)',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(isDark)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your focus',
                style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _selectedFocus.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.black,
                inactiveColor: AppColors.borderColor(isDark),
                onChanged: (value) {
                  setState(() {
                    _selectedFocus = value.round();
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (index) {
                  final number = index + 1;
                  final isSelected = number == _selectedFocus;
                  return Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.black : AppColors.borderColor(isDark),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.textSecondary(isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Selected: $_selectedFocus',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDataSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () {
                setState(() {
                  _customFields.add({'key': TextEditingController(), 'value': TextEditingController()});
                });
              },
              icon: Icon(Icons.add, color: AppColors.black, size: 16),
              label: Text(
                'Add Custom Field',
                style: TextStyle(color: AppColors.black, fontSize: 14),
              ),
            ),
          ],
        ),
        ..._customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor(isDark)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: field['key']!,
                        label: 'Field Name',
                        hint: 'e.g., Resources',
                        isDark: isDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          field['key']?.dispose();
                          field['value']?.dispose();
                          _customFields.removeAt(index);
                        });
                      },
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: field['value']!,
                  label: 'Field Value',
                  hint: 'e.g., Textbook, Online course',
                  isDark: isDark,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: AppColors.white,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _valueController.clear();
              _subjectController.clear();
              _locationController.clear();
              setState(() {
                _selectedFocus = 5;
                for (var field in _customFields) {
                  field['key']?.clear();
                  field['value']?.clear();
                }
                _customFields.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: AppColors.white,
            ),
            child: Text(
              'Clear Form',
              style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Text(
                    'Save Entry',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class MentalWellbeingTrackerScreen extends StatelessWidget {
  const MentalWellbeingTrackerScreen({Key? key}) : super(key: key);

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
              icon: Icon(Icons.arrow_back, color: AppColors.black),
            ),
            title: Text(
              'Mental Wellbeing Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark),
            child: Center(
              child: Text(
                'Mental Wellbeing Tracker - Coming Soon',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WorkoutTrackerScreen extends StatelessWidget {
  const WorkoutTrackerScreen({Key? key}) : super(key: key);

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
              icon: Icon(Icons.arrow_back, color: AppColors.black),
            ),
            title: Text(
              'Workout Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark),
            child: Center(
              child: Text(
                'Workout Tracker - Coming Soon',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WeightTrackerScreen extends StatelessWidget {
  const WeightTrackerScreen({Key? key}) : super(key: key);

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
              icon: Icon(Icons.arrow_back, color: AppColors.black),
            ),
            title: Text(
              'Weight Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark),
            child: Center(
              child: Text(
                'Weight Tracker - Coming Soon',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}