import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class EditLogEntryScreen extends StatefulWidget {
  final String trackerId;
  final String trackerTitle;
  final Color trackerColor;
  final IconData trackerIcon;
  final Map<String, dynamic> logData;
  final VoidCallback onLogUpdated;

  const EditLogEntryScreen({
    Key? key,
    required this.trackerId,
    required this.trackerTitle,
    required this.trackerColor,
    required this.trackerIcon,
    required this.logData,
    required this.onLogUpdated,
  }) : super(key: key);

  @override
  State<EditLogEntryScreen> createState() => _EditLogEntryScreenState();
}

class _EditLogEntryScreenState extends State<EditLogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, dynamic> _formData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = {};
    _formData = Map.from(widget.logData);

    // Initialize controllers based on tracker type
    switch (widget.trackerId) {
      case 'sleep':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['quality'] = TextEditingController(text: widget.logData['quality']?.toString() ?? '');
        _controllers['dreamNotes'] = TextEditingController(text: widget.logData['dreamNotes']?.toString() ?? '');
        _controllers['interruptions'] = TextEditingController(text: widget.logData['interruptions']?.toString() ?? '');
        break;
      
      case 'mood':
        _controllers['emotions'] = TextEditingController(text: widget.logData['emotions']?.toString() ?? '');
        _controllers['context'] = TextEditingController(text: widget.logData['context']?.toString() ?? '');
        _controllers['peakMoodTime'] = TextEditingController(text: widget.logData['peakMoodTime']?.toString() ?? '');
        _formData['value'] = widget.logData['value'] ?? 5;
        break;
      
      case 'meditation':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['type'] = TextEditingController(text: widget.logData['type']?.toString() ?? '');
        _controllers['afterEffect'] = TextEditingController(text: widget.logData['afterEffect']?.toString() ?? '');
        _formData['difficulty'] = widget.logData['difficulty'] ?? 3;
        break;
      
      case 'expense':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['category'] = TextEditingController(text: widget.logData['category']?.toString() ?? '');
        _formData['paymentMethod'] = widget.logData['paymentMethod'];
        _formData['necessity'] = widget.logData['necessity'];
        break;
      
      case 'savings':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['source'] = TextEditingController(text: widget.logData['source']?.toString() ?? '');
        _controllers['towardsGoal'] = TextEditingController(text: widget.logData['towardsGoal']?.toString() ?? '');
        _formData['recurring'] = widget.logData['recurring'] ?? false;
        break;
      
      case 'alcohol':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['occasion'] = TextEditingController(text: widget.logData['occasion']?.toString() ?? '');
        _formData['drinkType'] = widget.logData['drinkType'];
        _formData['craving'] = widget.logData['craving'] ?? 3;
        break;
      
      case 'study':
        _controllers['value'] = TextEditingController(text: widget.logData['value']?.toString() ?? '');
        _controllers['subjectTopic'] = TextEditingController(text: widget.logData['subjectTopic']?.toString() ?? '');
        _controllers['location'] = TextEditingController(text: widget.logData['location']?.toString() ?? '');
        _formData['focusLevel'] = widget.logData['focusLevel'] ?? 5;
        break;
      
      case 'menstrual':
        _controllers['cycleLengthController'] = TextEditingController(text: widget.logData['typicalCycleLength']?.toString() ?? '28');
        _controllers['periodLengthController'] = TextEditingController(text: widget.logData['periodLength']?.toString() ?? '5');
        _formData['lastPeriodDate'] = widget.logData['lastPeriodDate'] != null 
            ? DateTime.parse(widget.logData['lastPeriodDate']) 
            : DateTime.now();
        break;
    }

    // Initialize custom data controllers
    final customData = widget.logData['customData'] as Map<String, dynamic>?;
    if (customData != null) {
      _formData['customFields'] = <Map<String, TextEditingController>>[];
      customData.forEach((key, value) {
        final fieldControllers = {
          'key': TextEditingController(text: key),
          'value': TextEditingController(text: value.toString()),
        };
        (_formData['customFields'] as List).add(fieldControllers);
      });
    } else {
      _formData['customFields'] = <Map<String, TextEditingController>>[];
    }
  }

  Future<void> _updateEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Build updated entry data
      final updatedData = <String, dynamic>{};
      
      // Copy basic fields from controllers
      _controllers.forEach((key, controller) {
        if (key != 'cycleLengthController' && key != 'periodLengthController') {
          final value = controller.text.trim();
          if (value.isNotEmpty) {
            // Try to parse as number if it looks like one
            if (key == 'value' || key == 'quality') {
              updatedData[key] = double.tryParse(value) ?? value;
            } else {
              updatedData[key] = value;
            }
          }
        }
      });

      // Handle special cases for different tracker types
      switch (widget.trackerId) {
        case 'mood':
          updatedData['value'] = _formData['value'];
          break;
        case 'meditation':
          updatedData['difficulty'] = _formData['difficulty'];
          break;
        case 'expense':
          updatedData['paymentMethod'] = _formData['paymentMethod'];
          updatedData['necessity'] = _formData['necessity'];
          break;
        case 'savings':
          updatedData['recurring'] = _formData['recurring'];
          break;
        case 'alcohol':
          updatedData['drinkType'] = _formData['drinkType'];
          updatedData['craving'] = _formData['craving'];
          break;
        case 'study':
          updatedData['focusLevel'] = _formData['focusLevel'];
          break;
        case 'menstrual':
          updatedData['typicalCycleLength'] = int.tryParse(_controllers['cycleLengthController']?.text ?? '28') ?? 28;
          updatedData['periodLength'] = int.tryParse(_controllers['periodLengthController']?.text ?? '5') ?? 5;
          updatedData['lastPeriodDate'] = (_formData['lastPeriodDate'] as DateTime).toIso8601String();
          break;
      }

      // Handle custom data
      final customData = <String, dynamic>{};
      final customFields = _formData['customFields'] as List<Map<String, TextEditingController>>;
      for (var field in customFields) {
        final key = field['key']?.text ?? '';
        final value = field['value']?.text ?? '';
        if (key.isNotEmpty && value.isNotEmpty) {
          customData[key] = value;
        }
      }
      updatedData['customData'] = customData;
      updatedData['trackerType'] = widget.trackerId;

      await TrackerService.updateTrackerEntry(widget.trackerId, widget.logData['id'], updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entry updated successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        widget.onLogUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating entry: $e'),
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

  Widget _buildTextField({
    required String key,
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
          controller: _controllers[key],
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
              borderSide: BorderSide(
                color: widget.trackerColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.trackerColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.trackerColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.trackerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ($min-$max)',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: widget.trackerColor,
            inactiveColor: AppColors.textSecondary(isDark).withOpacity(0.3),
            onChanged: (newValue) {
              onChanged(newValue.round());
              HapticFeedback.selectionClick();
            },
          ),
          Center(
            child: Text(
              'Selected: $value',
              style: TextStyle(
                color: widget.trackerColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            filled: true,
            fillColor: AppColors.cardBackground(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.trackerColor.withOpacity(0.3),
              ),
            ),
          ),
          dropdownColor: AppColors.cardBackground(isDark),
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          items: items.map((item) => 
            DropdownMenuItem(value: item, child: Text(item))
          ).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime selectedDate,
    required Function(DateTime) onChanged,
    required bool isDark,
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
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(isDark),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.trackerColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: widget.trackerColor,
                        onPrimary: Colors.white,
                        surface: AppColors.cardBackground(isDark),
                        onSurface: AppColors.textPrimary(isDark),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: widget.trackerColor),
                const SizedBox(width: 12),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDataSection(bool isDark) {
    final customFields = _formData['customFields'] as List<Map<String, TextEditingController>>;
    
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
                  customFields.add({
                    'key': TextEditingController(),
                    'value': TextEditingController(),
                  });
                });
              },
              icon: Icon(Icons.add, color: widget.trackerColor, size: 16),
              label: Text(
                'Add Field',
                style: TextStyle(color: widget.trackerColor, fontSize: 14),
              ),
            ),
          ],
        ),
        ...customFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.trackerColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: field['key'],
                        style: TextStyle(color: AppColors.textPrimary(isDark)),
                        decoration: InputDecoration(
                          labelText: 'Field Name',
                          labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                          hintText: 'e.g., Location',
                          hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                          filled: true,
                          fillColor: AppColors.cardBackground(isDark),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.trackerColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          field['key']?.dispose();
                          field['value']?.dispose();
                          customFields.removeAt(index);
                        });
                      },
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: field['value'],
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                  decoration: InputDecoration(
                    labelText: 'Field Value',
                    labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                    hintText: 'e.g., Home',
                    hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
                    filled: true,
                    fillColor: AppColors.cardBackground(isDark),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.trackerColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrackerSpecificFields(bool isDark) {
    switch (widget.trackerId) {
      case 'sleep':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Sleep Duration (hours)',
              hint: 'Enter sleep duration',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sleep duration';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'quality',
              label: 'Quality (1-10)',
              hint: 'Rate your sleep quality',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please rate your sleep quality';
                }
                final quality = int.tryParse(value);
                if (quality == null || quality < 1 || quality > 10) {
                  return 'Please enter a number between 1-10';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'dreamNotes',
              label: 'Dream Notes',
              hint: 'Optional: Describe your dreams',
              maxLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'interruptions',
              label: 'Interruptions',
              hint: 'Optional: Note any sleep interruptions',
              maxLines: 2,
              isDark: isDark,
            ),
          ],
        );

      case 'mood':
        return Column(
          children: [
            _buildSlider(
              label: 'Mood Scale',
              value: _formData['value'],
              min: 1,
              max: 10,
              onChanged: (value) {
                setState(() {
                  _formData['value'] = value;
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'emotions',
              label: 'Emotions',
              hint: 'Describe your emotions',
              maxLines: 2,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'context',
              label: 'Context',
              hint: 'What was happening?',
              maxLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'peakMoodTime',
              label: 'Peak Mood Time',
              hint: 'When did you feel best today?',
              isDark: isDark,
            ),
          ],
        );

      case 'meditation':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Duration (minutes)',
              hint: 'Enter meditation duration',
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
            _buildTextField(
              key: 'type',
              label: 'Type',
              hint: 'Meditation type',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Difficulty',
              value: _formData['difficulty'],
              min: 1,
              max: 5,
              onChanged: (value) {
                setState(() {
                  _formData['difficulty'] = value;
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'afterEffect',
              label: 'After Effect',
              hint: 'How did you feel after meditation?',
              maxLines: 3,
              isDark: isDark,
            ),
          ],
        );

      case 'expense':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Amount',
              hint: 'Enter amount spent',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'category',
              label: 'Category',
              hint: 'Expense category',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Payment Method',
              items: ['Cash', 'Credit Card', 'Debit Card', 'Digital Wallet', 'Bank Transfer', 'Other'],
              value: _formData['paymentMethod'],
              onChanged: (value) {
                setState(() {
                  _formData['paymentMethod'] = value;
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Necessity',
              items: ['Essential', 'Important', 'Optional', 'Luxury'],
              value: _formData['necessity'],
              onChanged: (value) {
                setState(() {
                  _formData['necessity'] = value;
                });
              },
              isDark: isDark,
            ),
          ],
        );

      case 'savings':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Amount Saved',
              hint: 'Enter amount saved',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'source',
              label: 'Source',
              hint: 'Source of savings',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'towardsGoal',
              label: 'Towards Goal',
              hint: 'What are you saving for?',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.trackerColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _formData['recurring'],
                    onChanged: (value) {
                      setState(() {
                        _formData['recurring'] = value ?? false;
                      });
                    },
                    activeColor: widget.trackerColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Is this a recurring saving?',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'alcohol':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Number of Drinks',
              hint: 'Enter number of drinks',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of drinks';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'Drink Type',
              items: ['Beer', 'Wine', 'Cocktail', 'Whiskey', 'Vodka', 'Rum', 'Champagne', 'Other'],
              value: _formData['drinkType'],
              onChanged: (value) {
                setState(() {
                  _formData['drinkType'] = value;
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'occasion',
              label: 'Occasion',
              hint: 'What was the occasion?',
              maxLines: 2,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Craving Level',
              value: _formData['craving'],
              min: 1,
              max: 5,
              onChanged: (value) {
                setState(() {
                  _formData['craving'] = value;
                });
              },
              isDark: isDark,
            ),
          ],
        );

      case 'study':
        return Column(
          children: [
            _buildTextField(
              key: 'value',
              label: 'Study Duration (hours)',
              hint: 'Enter study duration',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter study duration';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'subjectTopic',
              label: 'Subject/Topic',
              hint: 'What did you study?',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'location',
              label: 'Location',
              hint: 'Where did you study?',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label: 'Focus Level',
              value: _formData['focusLevel'],
              min: 1,
              max: 10,
              onChanged: (value) {
                setState(() {
                  _formData['focusLevel'] = value;
                });
              },
              isDark: isDark,
            ),
          ],
        );

      case 'menstrual':
        return Column(
          children: [
            _buildDatePicker(
              label: 'Last Period Date',
              selectedDate: _formData['lastPeriodDate'],
              onChanged: (date) {
                setState(() {
                  _formData['lastPeriodDate'] = date;
                });
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'cycleLengthController',
              label: 'Typical Cycle Length (days)',
              hint: 'Average days between periods',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cycle length';
                }
                final length = int.tryParse(value);
                if (length == null || length < 21 || length > 35) {
                  return 'Please enter a valid cycle length (21-35 days)';
                }
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              key: 'periodLengthController',
              label: 'Period Length (days)',
              hint: 'How many days does your period last',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter period length';
                }
                final length = int.tryParse(value);
                if (length == null || length < 1 || length > 10) {
                  return 'Please enter a valid period length (1-10 days)';
                }
                return null;
              },
              isDark: isDark,
            ),
          ],
        );

      default:
        return Container();
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
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Entry',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.trackerTitle,
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundLinearGradient(isDark),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDark),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.trackerColor.withOpacity(0.1),
                            widget.trackerColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.trackerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.trackerIcon,
                            color: widget.trackerColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editing ${widget.trackerTitle} Entry',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDark),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Make changes to your entry below',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildTrackerSpecificFields(isDark),
                    const SizedBox(height: 24),
                    _buildCustomDataSection(isDark),
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
                                color: AppColors.textSecondary(isDark),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.trackerColor,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Update Entry',
                                    style: TextStyle(
                                      color: Colors.white,
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

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    
    // Dispose custom field controllers
    final customFields = _formData['customFields'] as List<Map<String, TextEditingController>>;
    for (var field in customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }
    
    super.dispose();
  }
}