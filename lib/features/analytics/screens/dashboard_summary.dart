import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class DashboardSummaryPage extends StatefulWidget {
  const DashboardSummaryPage({Key? key}) : super(key: key);

  @override
  State<DashboardSummaryPage> createState() => _DashboardSummaryPageState();
}

class _DashboardSummaryPageState extends State<DashboardSummaryPage>
    with SingleTickerProviderStateMixin {
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
            fontSize: 12, // Reduced from 14
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
            fontSize: 12, // Reduced from 14
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
          ),
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(isDarkTheme),
                  fontSize: 12, // Reduced from 14
                ),
                overflow: TextOverflow.ellipsis, // Added to prevent overflow
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
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dashboard Summary',
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
                          _buildConfigureButton(context, provider, isDark),
                          const SizedBox(height: 20),
                          if (provider.selectedTrackers.isNotEmpty) ...[
                            _buildCustomDashboardSection(context, provider, isDark),
                            const SizedBox(height: 24),
                            _buildOverallSummaryCard(context, provider, isDark),
                            const SizedBox(height: 24),
                            _buildBMICalculator(context, provider, isDark),
                          ] else ...[
                            _buildEmptyState(context, isDark),
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

  Widget _buildConfigureButton(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: _getCardDecoration(isDark),
      child: InkWell(
        onTap: () => _showConfigureDashboard(context, provider, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                lucide.LucideIcons.slidersHorizontal,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Configure Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary(isDark),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: _getCardDecoration(isDark),
      child: Column(
        children: [
          Icon(
            lucide.LucideIcons.activity,
            color: AppColors.textSecondary(isDark).withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Trackers Selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your dashboard to see analytics from your selected trackers.',
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

  Widget _buildCustomDashboardSection(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              lucide.LucideIcons.layoutDashboard,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Custom Dashboard Trackers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Displaying charts for your selected trackers (up to 4). Log more data to see trends.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ),
            if (provider.selectedTrackers.length < 4)
              _buildDetailChip(
                '${4 - provider.selectedTrackers.length} more trackers!',
                Icons.add,
                isDark,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...provider.selectedTrackers.take(4).map((tracker) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTrackerChart(
              context,
              tracker,
              provider.trackerData[tracker] ?? [],
              isDark,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTrackerChart(
    BuildContext context,
    String trackerName,
    List<Map<String, dynamic>> data,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trackerName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getTrackerUnit(trackerName),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          if (data.isNotEmpty)
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.textSecondary(isDark).withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateChartData(data),
                      isCurved: true,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            strokeWidth: 2,
                            strokeColor: AppColors.cardBackground(isDark),
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                .withOpacity(0.3),
                            (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                .withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                'No data logged for this tracker yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _generateChartData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length && i < 7; i++) {
      final value = double.tryParse(data[i]['value']?.toString() ?? '0') ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  String _getTrackerUnit(String trackerName) {
    switch (trackerName) {
      case 'Sleep Tracker':
        return 'Trend over time. Unit: hours';
      case 'Mood Tracker':
        return 'Unit: 1-10 scale';
      case 'Weight Tracker':
        return 'Unit: kg';
      case 'Study Time Tracker':
        return 'Unit: hours';
      case 'Workout Tracker':
        return 'Unit: minutes';
      default:
        return 'Trend over time';
    }
  }

  Widget _buildOverallSummaryCard(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.fileText,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Overall Summary',
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
            'Key insights from your tracked activities over the past month.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.isLoadingSummary)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.black,
                strokeWidth: 3,
              ),
            )
          else if (provider.overallSummary.isNotEmpty)
            _buildSummaryContent(provider.overallSummary, isDark)
          else
            _buildDefaultSummary(isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(String summary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryInsight(
          'Positive Trend',
          'Your average mood has slightly improved by 5% compared to the previous month. Keep up the great work!',
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildSummaryInsight(
          'Area for Focus',
          'Sleep consistency varies, with an average deviation of 1.5 hours from your target. Consider setting a more regular sleep schedule.',
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          isDark,
        ),
        const SizedBox(height: 12),
        _buildSummaryInsight(
          'Activity Peak',
          'Your most active days are typically Saturdays, with an average of 45,000 steps.',
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          isDark,
        ),
      ],
    );
  }

  Widget _buildDefaultSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryInsight(
          'Getting Started',
          'Start logging data consistently to see personalized insights here.',
          isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          isDark,
        ),
      ],
    );
  }

  Widget _buildSummaryInsight(
    String title,
    String description,
    Color color,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(isDark),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBMICalculator(
      BuildContext context,
      AnalyticsProvider provider,
      bool isDark,
      ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 24 : 16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.activity,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'BMI Categories & Calculator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                lucide.LucideIcons.info,
                color: AppColors.textSecondary(isDark),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Body Mass Index (BMI) is a general indicator of body fatness.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildBMIScale(provider.currentBMI, isDark),
          const SizedBox(height: 20),
          _buildBMICalculatorForm(provider, isDark),
        ],
      ),
    );
  }


  Widget _buildBMIScale(double? currentBMI, bool isDark) {
    return Column(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
            ),
          ),
          child: currentBMI != null ? _buildBMIIndicator(currentBMI) : null,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _buildBMICategory('Underweight', isDark)),
            Flexible(child: _buildBMICategory('Healthy', isDark)),
            Flexible(child: _buildBMICategory('Overweight', isDark)),
            Flexible(child: _buildBMICategory('Obese', isDark)),
          ],
        ),
        if (currentBMI != null) ...[
          const SizedBox(height: 8),
          Text(
            'Your BMI: ${currentBMI.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBMIIndicator(double bmi) {
    double position = 0.0;
    Color indicatorColor = Colors.blue;

    if (bmi < 18.5) {
      position = (bmi / 18.5) * 0.25;
      indicatorColor = Colors.blue;
    } else if (bmi < 25) {
      position = 0.25 + ((bmi - 18.5) / 6.5) * 0.25;
      indicatorColor = Colors.green;
    } else if (bmi < 30) {
      position = 0.5 + ((bmi - 25) / 5) * 0.25;
      indicatorColor = Colors.orange;
    } else {
      position = 0.75 + ((bmi - 30) / 10) * 0.25;
      indicatorColor = Colors.red;
    }

    return Align(
      alignment: Alignment(position * 2 - 1, 0),
      child: Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: indicatorColor,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMICategory(String category, bool isDark) {
    return Text(
      category,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary(isDark),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBMICalculatorForm(AnalyticsProvider provider, bool isDark) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Row(
              children: [
                Icon(
                  lucide.LucideIcons.calculator,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calculate Your BMI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: _buildDropdownField(
                    label: 'Height Unit',
                    value: provider.heightUnit,
                    options: ['Centimeters (cm)', 'Feet & Inches (ft/in)'],
                    isDarkTheme: isDark,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setHeightUnit(newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: provider.heightUnit == 'Centimeters (cm)'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Height (cm)',
                              style: TextStyle(
                                fontSize: 12, // Reduced from 14
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: provider.heightCmController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'E.g., 170',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 12, // Reduced from 14
                                ),
                                filled: true,
                                fillColor: AppColors.inputFill(isDark),
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
                                    color: isDark ? Colors.white : Colors.black,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                              ),
                              style: TextStyle(
                                color: AppColors.textPrimary(isDark),
                                fontSize: 12, // Reduced from 14
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Feet',
                                    style: TextStyle(
                                      fontSize: 12, // Reduced from 14
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: provider.heightFeetController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '5',
                                      hintStyle: TextStyle(
                                        color: AppColors.textSecondary(isDark),
                                        fontSize: 12, // Reduced from 14
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputFill(isDark),
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
                                          color: isDark ? Colors.white : Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textPrimary(isDark),
                                      fontSize: 12, // Reduced from 14
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Inches',
                                    style: TextStyle(
                                      fontSize: 12, // Reduced from 14
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: provider.heightInchesController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '6',
                                      hintStyle: TextStyle(
                                        color: AppColors.textSecondary(isDark),
                                        fontSize: 12, // Reduced from 14
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputFill(isDark),
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
                                          color: isDark ? Colors.white : Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textPrimary(isDark),
                                      fontSize: 12, // Reduced from 14
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: _buildDropdownField(
                    label: 'Weight Unit',
                    value: provider.weightUnit,
                    options: ['Kilograms (kg)', 'Pounds (lbs)'],
                    isDarkTheme: isDark,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        provider.setWeightUnit(newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Weight (${provider.weightUnit == 'Kilograms (kg)' ? 'kg' : 'lbs'})',
                        style: TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: provider.weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: provider.weightUnit == 'Kilograms (kg)' ? 'E.g., 65' : 'E.g., 143',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 12, // Reduced from 14
                          ),
                          filled: true,
                          fillColor: AppColors.inputFill(isDark),
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
                              color: isDark ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced padding
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontSize: 12, // Reduced from 14
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await provider.calculateBMI();
                  if (result != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'BMI calculated: ${result.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        backgroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please enter valid height and weight values',
                          style: TextStyle(fontSize: 14),
                        ),
                        backgroundColor: AppColors.errorColor,
                      ),
                    );
                  }
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      lucide.LucideIcons.calculator,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text('Calculate My BMI', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfigureDashboard(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            gradient: AppColors.cardLinearGradient(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Configure Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const Spacer(),
                    _buildDetailChip(
                      '${provider.selectedTrackers.length} selected',
                      Icons.check_circle,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        if (provider.selectedTrackers.isNotEmpty) {
                          provider.loadTrackerData();
                          provider.generateOverallSummary();
                        }
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.availableTrackers.length,
                  itemBuilder: (context, index) {
                    final tracker = provider.availableTrackers[index];
                    final isSelected = provider.selectedTrackers.contains(tracker);
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
                          provider.toggleTrackerSelection(tracker);
                          setState(() {});
                        },
                        activeColor: AppColors.black,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.trailing,
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}