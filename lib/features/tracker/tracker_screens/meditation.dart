import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class MeditationTrackerScreen extends StatefulWidget {
  const MeditationTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MeditationTrackerScreen> createState() => _MeditationTrackerScreenState();
}

class _MeditationTrackerScreenState extends State<MeditationTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _typeController = TextEditingController();
  final _afterEffectController = TextEditingController();
  
  final List<Map<String, TextEditingController>> _customFields = [];
  
  bool _isLoading = false;
  int _selectedDifficulty = 3;

  final List<String> meditationTypes = [
    'Mindfulness',
    'Focused Breathing',
    'Body Scan',
    'Loving Kindness',
    'Walking Meditation',
    'Transcendental',
    'Zen',
    'Guided Meditation',
    'Other'
  ];

  String? _selectedType;

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
    _valueController.clear();
    _typeController.clear();
    _afterEffectController.clear();
    
    for (var field in _customFields) {
      field['key']?.clear();
      field['value']?.clear();
    }
    
    setState(() {
      _customFields.clear();
      _selectedDifficulty = 3;
      _selectedType = null;
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
        'value': double.parse(_valueController.text),
        'type': _selectedType ?? _typeController.text.trim(),
        'afterEffect': _afterEffectController.text.trim(),
        'difficulty': _selectedDifficulty,
        'customData': customData,
        'trackerType': 'meditation',
      };

      await TrackerService.saveTrackerEntry('meditation', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meditation entry saved successfully!'),
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
    _valueController.dispose();
    _typeController.dispose();
    _afterEffectController.dispose();
    
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
            backgroundColor: AppColors.cardBackground(isDark), // Light grey AppBar
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            title: Text(
              'Log Meditation Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark), // Solid background for clean theme
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the details for your meditation tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Value (minutes)
                    _buildTextField(
                      controller: _valueController,
                      label: 'Value (minutes)',
                      hint: 'Enter meditation duration in minutes',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter meditation duration';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Type Dropdown
                    Text(
                      'Type',
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
                        color: AppColors.cardBackground(isDark), // Light grey card
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.borderColor(isDark),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        items: meditationTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue;
                          });
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select meditation type',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        isExpanded: true,
                        validator: (value) {
                          if (value == null && _typeController.text.isEmpty) {
                            return 'Please select or enter a meditation type';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Or enter custom type:',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _typeController,
                      label: '',
                      hint: 'Enter custom meditation type',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Difficulty (1-5 scale)
                    Text(
                      'Difficulty (1-5 scale)',
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
                        color: AppColors.cardBackground(isDark), // Light grey card
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderColor(isDark),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select difficulty (1-5)',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Difficulty Scale Slider
                          Slider(
                            value: _selectedDifficulty.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            activeColor: AppColors.black, // Black slider
                            inactiveColor: AppColors.textSecondary(isDark).withOpacity(0.3),
                            onChanged: (value) {
                              setState(() {
                                _selectedDifficulty = value.round();
                              });
                              HapticFeedback.selectionClick();
                            },
                          ),
                          // Difficulty Scale Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(5, (index) {
                              final number = index + 1;
                              final isSelected = number == _selectedDifficulty;
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? AppColors.black // Black for selected
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? AppColors.black
                                        : AppColors.textSecondary(isDark),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$number',
                                    style: TextStyle(
                                      color: isSelected 
                                          ? AppColors.white // White text for selected
                                          : AppColors.textSecondary(isDark),
                                      fontSize: 12,
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
                              'Selected: $_selectedDifficulty',
                              style: TextStyle(
                                color: AppColors.black, // Black text
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // After Effect
                    _buildTextField(
                      controller: _afterEffectController,
                      label: 'After Effect',
                      hint: 'How did you feel after meditation?',
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
                            color: AppColors.black, // Black icon
                            size: 16,
                          ),
                          label: Text(
                            'Add Custom Field',
                            style: TextStyle(
                              color: AppColors.black, // Black text
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
                          color: AppColors.cardBackground(isDark), // Light grey card
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
                                    hint: 'e.g., Position',
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
                              hint: 'e.g., Sitting',
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
                              side: BorderSide(
                                color: AppColors.black, // Black border
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: AppColors.white, // White background
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.black, // Black text
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
                              side: BorderSide(
                                color: AppColors.black, // Black border
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: AppColors.white, // White background
                            ),
                            child: Text(
                              'Clear Form',
                              style: TextStyle(
                                color: AppColors.black, // Black text
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
                              backgroundColor: AppColors.black, // Black button
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
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  )
                                : const Text(
                                    'Save Entry',
                                    style: TextStyle(
                                      color: AppColors.white, // White text
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
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
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
            fillColor: AppColors.cardBackground(isDark), // Light grey input
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDark),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDark),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.black, // Black border when focused
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}