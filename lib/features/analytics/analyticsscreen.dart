import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/analytics/analytics_provider.dart' hide AnalyticsProvider;
import 'package:trackai/core/themes/theme_provider.dart';
import 'package:trackai/features/analytics/screens/dashboard_summary.dart';
import 'package:trackai/features/analytics/screens/progress_overview.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedView = 'Progress Overview';

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                  _buildHeader(isDark),
                  Expanded(
                    child: _buildCurrentPage(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardLinearGradient(isDark),
      ),
      child: _buildDropdown(isDark),
    );
  }

  Widget _buildDropdown(bool isDark) {
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
          value: _selectedView,
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
          items: [
            DropdownMenuItem<String>(
              value: 'Dashboard',
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard,
                    color: AppColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('Dashboard'),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'Progress Overview',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('Progress Overview'),
                ],
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedView = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedView) {
      case 'Dashboard':
        return const DashboardSummaryPage();
      case 'Progress Overview':
        return const ProgressOverviewPage();
      default:
        return const DashboardSummaryPage();
    }
  }
}
