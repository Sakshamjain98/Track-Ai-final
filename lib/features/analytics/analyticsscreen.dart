import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/analytics/screens/correlation_labs.dart';
import 'package:trackai/features/analytics/screens/dashboard_summary.dart';
import 'package:trackai/features/analytics/screens/period_cycle.dart';
import 'package:trackai/features/analytics/screens/progress_overview.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.loadDashboardConfig();
      provider.loadBMIData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnalyticsProvider, ThemeProvider>(
      builder: (context, analyticsProvider, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardLinearGradient(isDark),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, analyticsProvider, isDark),
                  Expanded(
                    child: _buildCurrentPage(context, analyticsProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardLinearGradient(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.black,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnalyticsTypeDropdown(context, provider, isDark),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTypeDropdown(
    BuildContext context,
    AnalyticsProvider provider,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.black,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedAnalyticsType,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.black,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.inputFill(isDark),
          items: provider.analyticsTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                children: [
                  Icon(
                    _getIconForAnalyticsType(type),
                    color: AppColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setSelectedAnalyticsType(newValue);
            }
          },
        ),
      ),
    );
  }

  IconData _getIconForAnalyticsType(String type) {
    switch (type) {
      case 'Dashboard & Summary':
        return Icons.dashboard;
      case 'Correlation Labs':
        return Icons.scatter_plot;
      case 'Progress Overview':
        return Icons.trending_up;
      case 'Period Cycle':
        return Icons.calendar_today;
      default:
        return Icons.analytics;
    }
  }

  Widget _buildCurrentPage(BuildContext context, AnalyticsProvider provider) {
    switch (provider.selectedAnalyticsType) {
      case 'Dashboard & Summary':
        return const DashboardSummaryPage();
      case 'Correlation Labs':
        return const CorrelationLabsPage();
      case 'Progress Overview':
        return const ProgressOverviewPage();
      case 'Period Cycle':
        return const PeriodCyclePage();
      default:
        return const DashboardSummaryPage();
    }
  }
}