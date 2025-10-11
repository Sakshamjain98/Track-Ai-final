import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class CorrelationLabsPage extends StatefulWidget {
  const CorrelationLabsPage({Key? key}) : super(key: key);

  @override
  State<CorrelationLabsPage> createState() => _CorrelationLabsPageState();
}

class _CorrelationLabsPageState extends State<CorrelationLabsPage>
    with SingleTickerProviderStateMixin {
  List<String> selectedTrackers = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      setState(() {
        selectedTrackers = [];
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(40, 50, 49, 0.85),
            const Color.fromARGB(215, 14, 14, 14),
            const Color.fromRGBO(33, 43, 42, 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary(isDarkTheme).withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(isDarkTheme).withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cardBackground(isDarkTheme).withOpacity(0.95),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.90),
            AppColors.cardBackground(isDarkTheme).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary(isDarkTheme).withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(isDarkTheme).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required bool isDarkTheme,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkTheme),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          style: TextStyle(
            color: AppColors.textPrimary(isDarkTheme),
            fontSize: 14,
          ),
          dropdownColor: isDarkTheme ? AppColors.darkCardBackground : Colors.grey[50],
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkTheme ? AppColors.inputFill(true) : AppColors.inputFill(false),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: AppColors.borderColor(isDarkTheme),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkTheme ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailChip(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.background(isDark),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardLinearGradient(isDark),
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Icon(
                  lucide.LucideIcons.activity,
                  color: const Color(0xFF000000),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Correlation Lab',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundLinearGradient(isDark),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<AnalyticsProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(isDark, provider),
                          const SizedBox(height: 20),
                          _buildTimeframeSelector(provider, isDark),
                          const SizedBox(height: 20),
                          _buildTrackerSelectionCard(provider, isDark),
                          const SizedBox(height: 20),
                          if (selectedTrackers.length >= 2) ...[
                            _buildAnalyzeButton(provider, isDark),
                            const SizedBox(height: 20),
                          ],
                          if (provider.isLoadingCorrelations) ...[
                            _buildLoadingCard(isDark),
                            const SizedBox(height: 20),
                          ],
                          if (provider.correlationResults.isNotEmpty &&
                              !provider.isLoadingCorrelations) ...[
                            _buildCorrelationResults(provider, isDark),
                            const SizedBox(height: 20),
                          ],
                          if (selectedTrackers.length < 2) ...[
                            _buildInstructionCard(isDark),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 100),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(bool isDark, AnalyticsProvider provider) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.activity,
                color: const Color(0xFF000000),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Correlation Lab',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Discover hidden relationships between your tracked activities. Select at least 2 trackers to analyze patterns and get AI-powered insights about how different aspects of your life influence each other.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(AnalyticsProvider provider, bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: _buildDropdownField(
        label: 'Analysis Timeframe',
        value: provider.selectedTimeframe,
        options: provider.timeframes,
        isDarkTheme: isDark,
        onChanged: (String? newValue) {
          if (newValue != null) {
            provider.setSelectedTimeframe(newValue);
          }
        },
      ),
    );
  }

  Widget _buildInstructionCard(bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            lucide.LucideIcons.info,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary.withOpacity(0.5)
                : AppColors.lightTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select at least 2 trackers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose multiple trackers above to discover meaningful correlations and patterns in your data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerSelectionCard(AnalyticsProvider provider, bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Select Trackers to Compare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              _buildDetailChip(
                '${selectedTrackers.length} selected',
                selectedTrackers.length >= 2 ? Icons.check_circle : Icons.warning,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum 2 trackers required for correlation analysis',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          ...provider.availableTrackers.map((tracker) {
            final isSelected = selectedTrackers.contains(tracker);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.black.withOpacity(0.1)
                    : AppColors.inputFill(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.black
                      : AppColors.borderColor(isDark),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  tracker,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedTrackers.add(tracker);
                    } else {
                      selectedTrackers.remove(tracker);
                    }
                  });
                },
                activeColor: AppColors.black,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.trailing,
                dense: true,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(AnalyticsProvider provider, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isLoadingCorrelations
            ? null
            : () async {
                for (String tracker in List.from(provider.selectedTrackers)) {
                  provider.toggleTrackerSelection(tracker);
                }
                for (String tracker in selectedTrackers) {
                  provider.toggleTrackerSelection(tracker);
                }
                await provider.analyzeCorrelations();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: AppColors.black.withOpacity(0.4),
        ),
        child: provider.isLoadingCorrelations
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Analyzing Correlations...', style: TextStyle(fontSize: 16)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text('Analyze Correlations', style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing Your Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is discovering patterns and correlations in your tracked data...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationResults(AnalyticsProvider provider, bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.activity,
                color: const Color(0xFF26A69A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Correlation Analysis Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your ${provider.selectedTimeframe.toLowerCase()} data',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.correlationResults.isNotEmpty) ...[
            ...provider.correlationResults.map((correlation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCorrelationItem(correlation, isDark),
              );
            }).toList(),
          ] else ...[
            _buildNoCorrelationsFound(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildCorrelationItem(Map<String, dynamic> correlation, bool isDark) {
    final double correlationValue = correlation['correlation'] ?? 0.0;
    final String strength = correlation['strength'] ?? 'Very Weak';
    final String insight = correlation['insight'] ?? 'No specific insight available.';
    final int dataPoints = correlation['dataPoints'] ?? 0;

    Color strengthColor;
    IconData strengthIcon;

    switch (strength) {
      case 'Strong':
        strengthColor = AppColors.successColor;
        strengthIcon = Icons.trending_up;
        break;
      case 'Moderate':
        strengthColor = AppColors.warningColor;
        strengthIcon = Icons.trending_flat;
        break;
      case 'Weak':
        strengthColor = AppColors.black;
        strengthIcon = Icons.trending_down;
        break;
      default:
        strengthColor = AppColors.textSecondary(isDark);
        strengthIcon = Icons.remove;
    }

    final bool isPositive = correlationValue > 0;
    final String directionText = isPositive ? 'Positive' : 'Negative';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strengthColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${correlation['tracker1']} ↔ ${correlation['tracker2']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              _buildDetailChip(
                strength,
                strengthIcon,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Correlation: ${correlationValue.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              _buildDetailChip(
                directionText,
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                isDark,
              ),
              const Spacer(),
              Text(
                '$dataPoints data points',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      lucide.LucideIcons.activity,
                      color: const Color(0xFF26A69A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(isDark),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (correlation['trend'] != null)
                  Text(
                    'Trend: ${correlation['trend']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCorrelationsFound(bool isDark) {
    return Container(
      decoration: _getCardDecoration(isDark),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            lucide.LucideIcons.searchX,
            size: 64,
            color: isDark
                ? AppColors.darkTextSecondary.withOpacity(0.5)
                : AppColors.lightTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Significant Correlations Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This could mean:\n• Your data points are independent\n• You need more data for meaningful analysis\n• Try selecting different trackers or a longer timeframe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}