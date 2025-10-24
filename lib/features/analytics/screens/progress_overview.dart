import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class ProgressOverviewPage extends StatefulWidget {
  const ProgressOverviewPage({Key? key}) : super(key: key);

  @override
  State<ProgressOverviewPage> createState() => _ProgressOverviewPageState();
}

class _ProgressOverviewPageState extends State<ProgressOverviewPage> {
  String _selectedNutritionTimeframe = 'This Week';
  Map<String, dynamic> _nutritionData = {};
  bool _isLoadingNutrition = false;
  List<String> selectedTrackers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNutritionData();
      context.read<AnalyticsProvider>().loadProgressData();
    });
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoadingNutrition = true);
    try {
      final provider = context.read<AnalyticsProvider>();
      final data = await provider.getNutritionData(_selectedNutritionTimeframe);
      if (mounted) {
        setState(() {
          _nutritionData = data ?? {};
          _isLoadingNutrition = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nutritionData = {};
          _isLoadingNutrition = false;
        });
      }
    }
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
          color: AppColors.textSecondary(isDarkTheme).withOpacity(0.8),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary(isDarkTheme).withOpacity(0.15),
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
          color: AppColors.textSecondary(isDarkTheme).withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Progress Overview
              _buildSectionHeader('Progress Overview', isDark, lucide.LucideIcons.trendingUp),
              const SizedBox(height: 12),

              _buildNutritionCard(provider, isDark),
              const SizedBox(height: 16),

              _buildTimeframeSelector(provider, isDark),
              const SizedBox(height: 16),

              if (provider.selectedTrackers.isNotEmpty) ...[
                ...provider.selectedTrackers.map((tracker) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTrackerProgressCard(tracker, provider, isDark),
                  );
                }).toList(),
              ],

              const SizedBox(height: 32),

              // SECTION 2: Correlation Insights
              _buildSectionHeader('Correlation Insights', isDark, lucide.LucideIcons.activity),
              const SizedBox(height: 12),

              _buildTrackerSelectionCard(provider, isDark),
              const SizedBox(height: 16),

              if (selectedTrackers.length >= 2) ...[
                _buildAnalyzeButton(provider, isDark),
                const SizedBox(height: 16),
              ],

              if (provider.isLoadingCorrelations) ...[
                _buildLoadingCard(isDark),
                const SizedBox(height: 16),
              ],

              if (provider.correlationResults.isNotEmpty && !provider.isLoadingCorrelations) ...[
                _buildCorrelationResults(provider, isDark),
              ],

              if (selectedTrackers.length < 2 && provider.correlationResults.isEmpty) ...[
                _buildInstructionCard(isDark),
              ],

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF26A69A),
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
      ],
    );
  }

  // Nutrition Card from Progress Overview
  Widget _buildNutritionCard(AnalyticsProvider provider, bool isDark) {
    final totalCalories = _nutritionData['totalCalories']?.toDouble() ?? 0;
    final dailyAverage = _nutritionData['dailyAverage']?.toDouble() ?? 0;
    final dailyCalories = _nutritionData['dailyCalories'] ?? <String, double>{};
    final entries = _nutritionData['entries'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  lucide.LucideIcons.utensils,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Calorie intake for:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeFrameChip(
                'This Week',
                _selectedNutritionTimeframe == 'This Week',
                isDark,
                    () {
                  setState(() => _selectedNutritionTimeframe = 'This Week');
                  _loadNutritionData();
                },
              ),
              const SizedBox(width: 8),
              _buildTimeFrameChip(
                'Last Week',
                _selectedNutritionTimeframe == 'Last Week',
                isDark,
                    () {
                  setState(() => _selectedNutritionTimeframe = 'Last Week');
                  _loadNutritionData();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingNutrition
              ? _buildNutritionLoading(isDark)
              : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalCalories.toInt().toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Total calories',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dailyAverage.toInt().toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Daily avg.',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildWeeklyChart(dailyCalories, isDark),
              const SizedBox(height: 20),
              if (entries == 0) _buildNoNutritionData(isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameChip(
      String label,
      bool isSelected,
      bool isDark,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary(isDark)
              : AppColors.cardBackground(isDark),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textSecondary(isDark).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : AppColors.textSecondary(isDark),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNutritionLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, double> dailyCalories, bool isDark) {
    final now = DateTime.now();
    final startOfWeek = _selectedNutritionTimeframe == 'This Week'
        ? now.subtract(Duration(days: now.weekday - 1))
        : now.subtract(Duration(days: now.weekday + 6));

    final days = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      return date.toIso8601String().split('T')[0];
    });

    final values = days.map((date) => dailyCalories[date] ?? 0.0).toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMaxValue = maxValue == 0 ? 1.0 : maxValue * 1.2;

    return Container(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.asMap().entries.map((entry) {
          final index = entry.key;
          final value = values[index];
          final height = chartMaxValue > 0 ? (value / chartMaxValue) * 50 : 0;

          return Flexible(
            child: _buildDayColumn(
              ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
              value,
              height.clamp(0, 50).toDouble(),
              isDark,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayColumn(String day, double value, double height, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: value > 0
                ? AppColors.textPrimary(isDark)
                : AppColors.textSecondary(isDark).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary(isDark),
          ),
        ),
        Text(
          value > 0 ? value.toInt().toString() : '0',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDark),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNoNutritionData(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary(isDark).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No nutrition data found.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log your meals to see nutrition insights here.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(AnalyticsProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _getCardDecoration(isDark),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedTimeframe,
          isExpanded: true,
          icon: Icon(
            lucide.LucideIcons.chevronDown,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: AppColors.cardBackground(isDark),
          items: provider.timeframes.map((String timeframe) {
            return DropdownMenuItem<String>(
              value: timeframe,
              child: Text(
                timeframe,
                style: const TextStyle(
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              provider.setSelectedTimeframe(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTrackerProgressCard(
      String tracker,
      AnalyticsProvider provider,
      bool isDark,
      ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: provider.getEnhancedProgressData(tracker),
      builder: (context, snapshot) {
        final progressData = snapshot.data ?? provider.progressData[tracker] ?? {};
        final thisWeekData = progressData['thisWeek'] ?? [];
        final lastWeekData = progressData['lastWeek'] ?? [];
        final average = (progressData['average'] ?? 0.0).toDouble();
        final total = progressData['total'] ?? 0;
        final insights = progressData['insights'] ?? '';
        final trend = progressData['trend'] ?? 'stable';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _getCardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary(isDark).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTrackerIcon(tracker),
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            tracker,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trend != 'stable') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary(isDark).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trend == 'improving' ? '↗ Improving' : '↘ Declining',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildProgressStat(
                      'This Week',
                      thisWeekData.length.toString(),
                      'entries',
                      isDark,
                    ),
                  ),
                  Flexible(
                    child: _buildProgressStat(
                      'Last Week',
                      lastWeekData.length.toString(),
                      'entries',
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildProgressStat(
                      'Total',
                      total.toString(),
                      'entries',
                      isDark,
                    ),
                  ),
                  Flexible(
                    child: _buildProgressStat(
                      'Average',
                      average.toStringAsFixed(1),
                      _getTrackerUnit(tracker),
                      isDark,
                    ),
                  ),
                ],
              ),
              if (thisWeekData.isNotEmpty || lastWeekData.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildProgressChart(thisWeekData, lastWeekData, isDark),
              ],
              if (insights.isNotEmpty && snapshot.connectionState == ConnectionState.done) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary(isDark).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textSecondary(isDark).withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        lucide.LucideIcons.lightbulb,
                        size: 16,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insights,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressStat(
      String label,
      String value,
      String unit,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary(isDark),
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressChart(
      List<dynamic> thisWeekData,
      List<dynamic> lastWeekData,
      bool isDark,
      ) {
    final maxY = [thisWeekData.length, lastWeekData.length, 10].reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 100,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text(
                        'Last Week',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary(isDark),
                        ),
                      );
                    case 1:
                      return Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary(isDark),
                        ),
                      );
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: lastWeekData.length.toDouble(),
                  color: AppColors.textSecondary(isDark).withOpacity(0.5),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: thisWeekData.length.toDouble(),
                  color: AppColors.textPrimary(isDark),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // CORRELATION SECTION WIDGETS
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
      padding: const EdgeInsets.all(12),
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
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns chip to top
            children: [
              Expanded(
                child: Text(
                  '${correlation['tracker1']} ↔ ${correlation['tracker2']}',
                  softWrap: true, // <-- FIX: Allows text to wrap
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Adds spacing
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
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

  IconData _getTrackerIcon(String tracker) {
    switch (tracker) {
      case 'Sleep Tracker':
        return lucide.LucideIcons.moon;
      case 'Mood Tracker':
        return lucide.LucideIcons.smile;
      case 'Meditation Tracker':
        return lucide.LucideIcons.zap;
      case 'Expense Tracker':
        return lucide.LucideIcons.dollarSign;
      case 'Savings Tracker':
        return lucide.LucideIcons.piggyBank;
      case 'Alcohol Tracker':
        return lucide.LucideIcons.wine;
      case 'Study Time Tracker':
        return lucide.LucideIcons.bookOpen;
      case 'Mental Well-being Tracker':
        return lucide.LucideIcons.brain;
      case 'Workout Tracker':
        return lucide.LucideIcons.dumbbell;
      case 'Weight Tracker':
        return lucide.LucideIcons.scale;
      case 'Menstrual Cycle':
        return lucide.LucideIcons.calendar;
      default:
        return lucide.LucideIcons.activity;
    }
  }

  String _getTrackerUnit(String tracker) {
    switch (tracker) {
      case 'Sleep Tracker':
        return 'hours';
      case 'Mood Tracker':
        return '/10';
      case 'Weight Tracker':
        return 'kg';
      case 'Study Time Tracker':
        return 'hours';
      case 'Workout Tracker':
        return 'mins';
      default:
        return 'value';
    }
  }
}
