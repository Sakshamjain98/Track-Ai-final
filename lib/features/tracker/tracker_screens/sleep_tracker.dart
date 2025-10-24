import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dreamNotesController = TextEditingController();
  final _interruptionsController = TextEditingController();

  // Changed to state variables for sliders
  double _sleepHours = 7.0;  // Default 7 hours
  double _sleepQuality = 5.0;  // Default quality of 5/10

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
    _dreamNotesController.clear();
    _interruptionsController.clear();

    for (var field in _customFields) {
      field['key']?.clear();
      field['value']?.clear();
    }

    setState(() {
      _sleepHours = 7.0;
      _sleepQuality = 5.0;
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
        'value': _sleepHours,
        'quality': _sleepQuality.round(),
        'dreamNotes': _dreamNotesController.text.trim(),
        'interruptions': _interruptionsController.text.trim(),
        'customData': customData,
        'trackerType': 'sleep',
      };

      await TrackerService.saveTrackerEntry('sleep', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sleep entry saved successfully!'),
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
    _dreamNotesController.dispose();
    _interruptionsController.dispose();

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
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
            ),
            title: Text(
              'Log Sleep Tracker',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track your sleep duration and quality.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sleep Duration Slider
                    _buildSliderSection(
                      icon: Icons.bedtime,
                      label: 'Sleep Duration',
                      value: _sleepHours,
                      displayValue: '${_sleepHours.toStringAsFixed(1)} hours',
                      min: 0,
                      max: 12,
                      divisions: 48, // 0.25 hour increments
                      onChanged: (value) {
                        setState(() {
                          _sleepHours = value;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Sleep Quality Slider
                    _buildSliderSection(
                      icon: Icons.star,
                      label: 'Sleep Quality',
                      value: _sleepQuality,
                      displayValue: '${_sleepQuality.round()}/10',
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _sleepQuality = value;
                        });
                      },
                      showQualityIndicators: true,
                    ),

                    const SizedBox(height: 32),

                    // Dream Notes
                    _buildTextField(
                      controller: _dreamNotesController,
                      label: 'Dream Notes',
                      hint: 'Optional: Describe your dreams',
                      icon: Icons.bubble_chart,
                      maxLines: 3,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // Interruptions
                    _buildTextField(
                      controller: _interruptionsController,
                      label: 'Interruptions',
                      hint: 'Optional: Note any sleep interruptions',
                      icon: Icons.notification_important,
                      maxLines: 2,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Custom Data Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 20, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              'Custom Data',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addCustomField,
                          icon: Icon(Icons.add, color: Colors.black, size: 18),
                          label: Text(
                            'Add Field',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Custom Fields
                    ..._customFields.asMap().entries.map((entry) {
                      final index = entry.key;
                      final field = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: field['key']!,
                                    label: 'Field Name',
                                    hint: 'e.g., Sleep Position',
                                    isDark: isDark,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeCustomField(index),
                                  icon: Icon(Icons.delete, color: Colors.red[700]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: field['value']!,
                              label: 'Field Value',
                              hint: 'e.g., Side sleeper',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[400]!, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
                              side: BorderSide(color: Colors.grey[400]!, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Entry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliderSection({
    required IconData icon,
    required String label,
    required double value,
    required String displayValue,
    required double min,
    required double max,
    required int divisions,
    required void Function(double) onChanged,
    bool showQualityIndicators = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.black,
              overlayColor: Colors.black.withOpacity(0.1),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
              trackHeight: 6,
              valueIndicatorColor: Colors.black,
              valueIndicatorTextStyle: TextStyle(color: Colors.white, fontSize: 14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: displayValue,
              onChanged: onChanged,
            ),
          ),

          if (showQualityIndicators)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQualityLabel('Poor', Colors.red[700]!),
                  _buildQualityLabel('Fair', Colors.orange[700]!),
                  _buildQualityLabel('Good', Colors.yellow[700]!),
                  _buildQualityLabel('Great', Colors.green[700]!),
                  _buildQualityLabel('Perfect', Colors.blue[700]!),
                ],
              ),
            ),

          if (!showQualityIndicators)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${min.toInt()}h', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  Text('${max.toInt()}h', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQualityLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.black),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.black38),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[700]!, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
