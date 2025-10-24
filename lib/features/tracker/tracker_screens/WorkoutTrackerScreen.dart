import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/tracker/service/tracker_service.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _locationController = TextEditingController();

  double _duration = 30.0;  // Changed to double for slider (in minutes)
  double _exertionLevel = 5.0;  // Changed to double for slider

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
    _detailsController.clear();
    _locationController.clear();

    for (var field in _customFields) {
      field['key']?.clear();
      field['value']?.clear();
    }

    setState(() {
      _duration = 30.0;
      _exertionLevel = 5.0;
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
        'details': _detailsController.text.trim(),
        'duration': _duration.round(),
        'exertionLevel': _exertionLevel.round(),
        'location': _locationController.text.trim(),
        'customData': customData,
        'trackerType': 'workout',
      };

      await TrackerService.saveTrackerEntry('workout', entryData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout entry saved successfully!'),
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
    _detailsController.dispose();
    _locationController.dispose();

    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
    }

    super.dispose();
  }

  String _getExertionLabel(int value) {
    if (value <= 2) return 'Very Light';
    if (value <= 4) return 'Light';
    if (value <= 6) return 'Moderate';
    if (value <= 8) return 'Hard';
    return 'Maximum';
  }

  Color _getExertionColor(int value) {
    if (value <= 2) return Colors.green[700]!;
    if (value <= 4) return Colors.lightGreen[700]!;
    if (value <= 6) return Colors.yellow[700]!;
    if (value <= 8) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}h ${mins.round()}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: Colors.black),
            ),
            title: Text(
              'Workout Tracker',
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
                      'Log your workout session details.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Workout Details
                    _buildTextField(
                      controller: _detailsController,
                      label: 'Workout Details',
                      hint: 'Describe exercises, sets, reps...',
                      icon: Icons.fitness_center,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe your workout';
                        }
                        return null;
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Duration Slider
                    _buildSliderSection(
                      icon: Icons.timer,
                      label: 'Workout Duration',
                      value: _duration,
                      displayValue: _formatDuration(_duration),
                      min: 5,
                      max: 180,
                      divisions: 35, // 5-minute increments
                      onChanged: (value) {
                        setState(() {
                          _duration = value;
                        });
                      },
                      showRangeLabels: true,
                      minLabel: '5 min',
                      maxLabel: '3 hours',
                    ),

                    const SizedBox(height: 32),

                    // Exertion Level Slider
                    _buildSliderSection(
                      icon: Icons.local_fire_department,
                      label: 'Exertion Level',
                      value: _exertionLevel,
                      displayValue: '${_exertionLevel.round()}/10',
                      statusLabel: _getExertionLabel(_exertionLevel.round()),
                      statusColor: _getExertionColor(_exertionLevel.round()),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _exertionLevel = value;
                        });
                      },
                      showIndicators: true,
                      indicators: [
                        _IndicatorData('Very Light', Colors.green[700]!),
                        _IndicatorData('Light', Colors.lightGreen[700]!),
                        _IndicatorData('Moderate', Colors.yellow[700]!),
                        _IndicatorData('Hard', Colors.orange[700]!),
                        _IndicatorData('Maximum', Colors.red[700]!),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Location
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'e.g., Gym, Park, Home',
                      icon: Icons.location_on,
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
                                    hint: 'e.g., Calories Burned',
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
                              hint: 'e.g., 350',
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
    String? statusLabel,
    Color? statusColor,
    required double min,
    required double max,
    required int divisions,
    required void Function(double) onChanged,
    bool showIndicators = false,
    List<_IndicatorData>? indicators,
    bool showRangeLabels = false,
    String? minLabel,
    String? maxLabel,
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

          if (statusLabel != null && statusColor != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

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

          if (showRangeLabels && minLabel != null && maxLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(minLabel, style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(maxLabel, style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          if (showIndicators && indicators != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: indicators.map((indicator) {
                  return _buildIndicatorLabel(indicator.label, indicator.color);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicatorLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
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

// Helper class for indicator data
class _IndicatorData {
  final String label;
  final Color color;

  _IndicatorData(this.label, this.color);
}
