import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

// Expense Tracker Screen
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;

  String? _selectedPaymentMethod;
  String? _selectedNecessity;

  final List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Digital Wallet',
    'Bank Transfer',
    'Other',
  ];
  final List<String> necessityLevels = [
    'Essential',
    'Important',
    'Optional',
    'Luxury',
  ];
  final List<String> categories = [
    'Food',
    'Transportation',
    'Housing',
    'Healthcare',
    'Entertainment',
    'Shopping',
    'Bills',
    'Other',
  ];

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
        'category': _categoryController.text.trim(),
        'paymentMethod': _selectedPaymentMethod ?? '',
        'necessity': _selectedNecessity ?? '',
        'customData': customData,
        'trackerType': 'expense',
      };

      await TrackerService.saveTrackerEntry('expense', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense entry saved successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
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
              'Log Expense Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark), // Solid background
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the details for your expense tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _valueController,
                      label: 'Value (currency)',
                      hint: 'Enter amount spent',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter amount';
                        if (double.tryParse(value) == null)
                          return 'Please enter a valid number';
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Category',
                      value: _categoryController.text.isEmpty
                          ? null
                          : _categoryController.text,
                      items: categories,
                      onChanged: (value) {
                        setState(() {
                          _categoryController.text = value ?? '';
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Payment Method',
                      value: _selectedPaymentMethod,
                      hint: 'Select payment method',
                      items: paymentMethods,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Necessity',
                      value: _selectedNecessity,
                      hint: 'Select necessity',
                      items: necessityLevels,
                      onChanged: (value) {
                        setState(() {
                          _selectedNecessity = value;
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
            color: AppColors.cardBackground(isDark), // Light grey dropdown
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderColor(isDark),
            ),
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
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.black, // Black dropdown icon
            ),
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
              onPressed: _addCustomField,
              icon: Icon(Icons.add, color: AppColors.black, size: 16), // Black icon
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
                        hint: 'e.g., Store',
                        isDark: isDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeCustomField(index),
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: field['value']!,
                  label: 'Field Value',
                  hint: 'e.g., Target',
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
              side: BorderSide(color: AppColors.black), // Black border
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
            onPressed: () {
              _valueController.clear();
              _categoryController.clear();
              setState(() {
                _selectedPaymentMethod = null;
                _selectedNecessity = null;
                for (var field in _customFields) {
                  field['key']?.clear();
                  field['value']?.clear();
                }
                _customFields.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black), // Black border
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
    );
  }
}

// Savings Tracker Screen
class SavingsTrackerScreen extends StatefulWidget {
  const SavingsTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SavingsTrackerScreen> createState() => _SavingsTrackerScreenState();
}

class _SavingsTrackerScreenState extends State<SavingsTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _sourceController = TextEditingController();
  final _goalController = TextEditingController();
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  bool _isRecurring = false;

  final List<String> sources = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Bonus',
    'Side Hustle',
    'Other',
  ];

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
        'source': _sourceController.text.trim(),
        'towardsGoal': _goalController.text.trim(),
        'recurring': _isRecurring,
        'customData': customData,
        'trackerType': 'savings',
      };

      await TrackerService.saveTrackerEntry('savings', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Savings entry saved successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
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
              'Log Savings Tracker',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark), // Solid background
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the details for your savings tracker entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _valueController,
                      label: 'Value (currency)',
                      hint: 'Enter amount saved',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter amount';
                        if (double.tryParse(value) == null)
                          return 'Please enter a valid number';
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Source',
                      value: _sourceController.text.isEmpty
                          ? null
                          : _sourceController.text,
                      items: sources,
                      onChanged: (value) {
                        setState(() {
                          _sourceController.text = value ?? '';
                        });
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _goalController,
                      label: 'Towards Goal',
                      hint:
                          'What are you saving for? (e.g., Emergency fund, Vacation)',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground(isDark), // Light grey card
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.borderColor(isDark),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isRecurring,
                            onChanged: (value) {
                              setState(() {
                                _isRecurring = value ?? false;
                              });
                            },
                            activeColor: AppColors.black, // Black checkbox
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
            color: AppColors.cardBackground(isDark), // Light grey dropdown
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderColor(isDark),
            ),
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
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.black, // Black dropdown icon
            ),
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
              onPressed: _addCustomField,
              icon: Icon(Icons.add, color: AppColors.black, size: 16), // Black icon
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
                        hint: 'e.g., Method',
                        isDark: isDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeCustomField(index),
                      icon: Icon(Icons.delete, color: AppColors.errorColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: field['value']!,
                  label: 'Field Value',
                  hint: 'e.g., Auto Transfer',
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
              side: BorderSide(color: AppColors.black), // Black border
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
            onPressed: () {
              _valueController.clear();
              _sourceController.clear();
              _goalController.clear();
              setState(() {
                _isRecurring = false;
                for (var field in _customFields) {
                  field['key']?.clear();
                  field['value']?.clear();
                }
                _customFields.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black), // Black border
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
    );
  }
}

// Menstrual Tracker Screen
class MenstrualTrackerScreen extends StatefulWidget {
  const MenstrualTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MenstrualTrackerScreen> createState() => _MenstrualTrackerScreenState();
}

class _MenstrualTrackerScreenState extends State<MenstrualTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cycleLengthController = TextEditingController(text: '28');
  final _periodLengthController = TextEditingController(text: '5');
  final List<Map<String, TextEditingController>> _customFields = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.black, // Black for date picker
              onPrimary: AppColors.white,
              surface: AppColors.cardBackground(isDark),
              onSurface: AppColors.textPrimary(isDark),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
        'lastPeriodDate': _selectedDate.toIso8601String(),
        'typicalCycleLength': int.parse(_cycleLengthController.text),
        'periodLength': int.parse(_periodLengthController.text),
        'customData': customData,
        'trackerType': 'menstrual',
      };

      await TrackerService.saveTrackerEntry('menstrual', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Menstrual cycle entry saved successfully!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context);
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
              'Log Menstrual Cycle',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: AppColors.background(isDark), // Solid background
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the details for your menstrual cycle entry.',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Picker
                    Text(
                      'Last Period Date',
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
                        color: AppColors.cardBackground(isDark), // Light grey card
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.borderColor(isDark),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _selectDate(context, isDark),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.black, // Black icon
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDark),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cycleLengthController,
                      label: 'Typical Cycle Length (days)',
                      hint: 'Average days between periods',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter cycle length';
                        final length = int.tryParse(value);
                        if (length == null || length < 21 || length > 35)
                          return 'Please enter a valid cycle length (21-35 days)';
                        return null;
                      },
                      isDark: isDark,
                      isRequired: true,
                    ),

                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _periodLengthController,
                      label: 'Period Length (days)',
                      hint: 'How many days does your period typically last',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter period length';
                        final length = int.tryParse(value);
                        if (length == null || length < 1 || length > 10)
                          return 'Please enter a valid period length (1-10 days)';
                        return null;
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
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(color: AppColors.errorColor, fontSize: 16),
              ),
          ],
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
                  _customFields.add({
                    'key': TextEditingController(),
                    'value': TextEditingController(),
                  });
                });
              },
              icon: Icon(Icons.add, color: AppColors.black, size: 16), // Black icon
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
                        hint: 'e.g., Symptoms',
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
                  hint: 'e.g., Cramps, headache',
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
              side: BorderSide(color: AppColors.black), // Black border
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
            onPressed: () {
              _cycleLengthController.text = '28';
              _periodLengthController.text = '5';
              setState(() {
                _selectedDate = DateTime.now();
                for (var field in _customFields) {
                  field['key']?.clear();
                  field['value']?.clear();
                }
                _customFields.clear();
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.black), // Black border
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
    );
  }
}

