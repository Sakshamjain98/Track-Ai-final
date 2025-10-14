import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/features/analytics/analytics_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart' as lucide;

class PeriodCycleScreen extends StatefulWidget {
  const PeriodCycleScreen({Key? key}) : super(key: key);

  @override
  State<PeriodCycleScreen> createState() => _PeriodCycleScreenState();
}

class _PeriodCycleScreenState extends State<PeriodCycleScreen>
    with SingleTickerProviderStateMixin {

  PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.loadPeriodData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Pink theme colors
  Color _getPinkAccent(bool isDark) => isDark
      ? const Color(0xFFF472B6)
      : const Color(0xFFEC4899);

  Color _getPinkBackground(bool isDark) => isDark
      ? const Color(0xFF1F1B24)
      : const Color(0xFFFDF2F8);

  BoxDecoration _getCardDecoration(bool isDarkTheme) {
    if (isDarkTheme) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D1B2D).withOpacity(0.95),
            const Color(0xFF1F1B24).withOpacity(0.90),
            const Color(0xFF2D1B2D).withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPinkAccent(isDarkTheme).withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPinkAccent(isDarkTheme).withOpacity(0.15),
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
            Colors.white.withOpacity(0.95),
            const Color(0xFFFDF2F8).withOpacity(0.90),
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPinkAccent(isDarkTheme).withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPinkAccent(isDarkTheme).withOpacity(0.1),
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

        return Scaffold(
          backgroundColor: _getPinkBackground(isDark),
          body: SafeArea(
            child: Column(
              children: [
                // Pink Header
                _buildPinkHeader(isDark),

                // Page Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      children: [
                        // Page 1: Log & Track
                        _buildMainPage(provider, isDark),

                        // Page 2: Education - Hormones
                        _buildEducationPage1(isDark),

                        // Page 3: Education - Phases
                        _buildEducationPage2(isDark),
                      ],
                    ),
                  ),
                ),

                // Pink Navigation
                _buildPinkNavigation(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinkHeader(bool isDark) {
    final pages = ['Track & Log', 'Your Insights', 'Learn More'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF4C1D4C),
            const Color(0xFF2D1B2D),
          ]
              : [
            const Color(0xFFFC7FB3),
            const Color(0xFFF472B6),
            const Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPinkAccent(isDark).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.favorite, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Period Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              pages[_currentPageIndex],
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainPage(AnalyticsProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildLogYourCycleCard(provider, isDark),
          const SizedBox(height: 20),
          if (provider.periodData.isNotEmpty &&
              provider.periodData['recentEntries'] != null &&
              provider.periodData['recentEntries'].isNotEmpty) ...[
            _buildCycleInsights(provider, isDark),
            const SizedBox(height: 20),
            _buildDynamicCycleChart(provider, isDark),
            const SizedBox(height: 20),
            _buildRecentEntries(provider, isDark),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEducationPage1(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildUnderstandingHormones(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEducationPage2(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildCyclePhases(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPinkNavigation(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF2D1B2D).withOpacity(0.95),
            const Color(0xFF1F1B24).withOpacity(0.9),
          ]
              : [
            Colors.white.withOpacity(0.95),
            const Color(0xFFFDF2F8).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPinkAccent(isDark).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: _getPinkAccent(isDark).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: _currentPageIndex > 0
                  ? LinearGradient(
                colors: [
                  _getPinkAccent(isDark),
                  _getPinkAccent(isDark).withOpacity(0.8),
                ],
              )
                  : null,
              color: _currentPageIndex == 0 ? Colors.grey.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentPageIndex > 0 ? _previousPage : null,
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: _currentPageIndex > 0 ? Colors.white : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Previous',
                      style: TextStyle(
                        color: _currentPageIndex > 0 ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Page Indicators
          Row(
            children: List.generate(3, (index) {
              final isActive = index == _currentPageIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                    colors: [
                      _getPinkAccent(isDark),
                      _getPinkAccent(isDark).withOpacity(0.8),
                    ],
                  )
                      : null,
                  color: !isActive ? Colors.grey.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next Button
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: _currentPageIndex < 2
                  ? LinearGradient(
                colors: [
                  _getPinkAccent(isDark),
                  _getPinkAccent(isDark).withOpacity(0.8),
                ],
              )
                  : null,
              color: _currentPageIndex == 2 ? Colors.grey.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _currentPageIndex < 2 ? _nextPage : null,
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: _currentPageIndex < 2 ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: _currentPageIndex < 2 ? Colors.white : Colors.grey,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPageIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ALL YOUR EXISTING FUNCTIONS WITH PINK ACCENTS - NO LOGIC CHANGES
  Widget _buildLogYourCycleCard(AnalyticsProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.calendar,
                color: _getPinkAccent(isDark),
                size: 20,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Log Your Period',
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
          const SizedBox(height: 8),
          Text(
            'Track your menstrual cycle to predict dates, identify patterns, and understand your body better.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary(isDark),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Date selector
          Row(
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period Start Date',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _selectDate(context, provider),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground(isDark),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPinkAccent(isDark).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              lucide.LucideIcons.calendar,
                              size: 16,
                              color: _getPinkAccent(isDark),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                provider.selectedPeriodDate != null
                                    ? '${provider.selectedPeriodDate!.day}/${provider.selectedPeriodDate!.month}/${provider.selectedPeriodDate!.year}'
                                    : 'Select Date',
                                style: TextStyle(
                                  color: provider.selectedPeriodDate != null
                                      ? AppColors.textPrimary(isDark)
                                      : AppColors.textSecondary(isDark),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Symptoms selector
          Text(
            'Symptoms (Optional)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          ClipRect(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: provider.periodSymptoms.map((symptom) {
                final isSelected = provider.selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () => provider.toggleSymptom(symptom),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [
                          _getPinkAccent(isDark),
                          _getPinkAccent(isDark).withOpacity(0.8),
                        ],
                      )
                          : null,
                      color: !isSelected ? AppColors.cardBackground(isDark) : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _getPinkAccent(isDark)
                            : AppColors.textSecondary(isDark).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      symptom,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary(isDark),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoggingPeriod || provider.selectedPeriodDate == null
                  ? null
                  : () async {
                try {
                  await provider.logPeriodEntry();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Period entry logged successfully!'),
                        backgroundColor: _getPinkAccent(isDark),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging entry: ${e.toString()}'),
                        backgroundColor: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPinkAccent(isDark),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: provider.isLoggingPeriod ? 0 : 2,
              ),
              child: provider.isLoggingPeriod
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logging...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              )
                  : Text(
                'Log Period Entry',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, AnalyticsProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedPeriodDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select period start date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _getPinkAccent(isDark),
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != provider.selectedPeriodDate) {
      provider.setSelectedPeriodDate(picked);
    }
  }

  Widget _buildCycleInsights(AnalyticsProvider provider, bool isDark) {
    if (provider.isLoadingPeriodData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _getCardDecoration(isDark),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: _getPinkAccent(isDark),
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Analyzing your cycle data...',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final averageLength = provider.periodData['averageCycleLength'] ?? 28.0;
    final nextPeriod = provider.periodData['nextPredictedPeriod'];
    final cycles = provider.periodData['cycles'] ?? [];
    final recentEntries = provider.periodData['recentEntries'] ?? [];

    return FutureBuilder<String>(
      future: _getEnhancedInsights(provider, cycles, recentEntries, averageLength),
      builder: (context, snapshot) {
        final insights = snapshot.data ?? 'Generating personalized insights...';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _getCardDecoration(isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    lucide.LucideIcons.chartBar,
                    color: _getPinkAccent(isDark),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Your Cycle Insights',
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildInsightCard(
                      'Average Cycle',
                      '${averageLength.toStringAsFixed(0)} days',
                      lucide.LucideIcons.activity,
                      _getPinkAccent(isDark),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: _buildInsightCard(
                      'Next Period',
                      nextPeriod != null
                          ? '${(nextPeriod as DateTime).day}/${nextPeriod.month}'
                          : 'Need more data',
                      lucide.LucideIcons.calendar,
                      _getPinkAccent(isDark),
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPinkAccent(isDark).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPinkAccent(isDark).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      lucide.LucideIcons.lightbulb,
                      color: _getPinkAccent(isDark),
                      size: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalized Insights',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getPinkAccent(isDark)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analyzing your cycle patterns...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(isDark),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              insights,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(isDark),
                                height: 1.4,
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
        );
      },
    );
  }

  // ALL YOUR OTHER EXISTING FUNCTIONS - KEEPING EXACT SAME LOGIC
  // Just updating colors to use _getPinkAccent(isDark) instead of default colors

  Future<String> _getEnhancedInsights(
      AnalyticsProvider provider,
      List<dynamic> cycles,
      List<dynamic> recentEntries,
      double averageLength,
      ) async {
    if (provider.periodData['insights'] != null &&
        provider.periodData['insights'] is String &&
        provider.periodData['insights'] != 'Generating personalized insights...') {
      return provider.periodData['insights'];
    }

    final symptomCounts = <String, int>{};
    final cycleDays = <int>[];
    final dates = <DateTime>[];

    for (var entry in recentEntries) {
      final symptoms = List<String>.from(entry['symptoms'] ?? []);
      for (var symptom in symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }

      final date = DateTime.tryParse(entry['timestamp'] ?? '');
      if (date != null) dates.add(date);
    }

    for (var cycle in cycles) {
      if (cycle['cycleDay'] != null) {
        cycleDays.add(cycle['cycleDay'] as int);
      }
    }

    final mostCommonSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final insights = StringBuffer();

    if (recentEntries.length >= 2) {
      if (dates.length >= 2) {
        dates.sort();
        final daysBetween = dates.last.difference(dates.first).inDays;
        insights.writeln('**CYCLE HEALTH ASSESSMENT**');
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle falls within the healthy range (21-35 days), indicating balanced hormonal function.');
        insights.writeln('With ${recentEntries.length} entries over ${daysBetween} days, you\'re building valuable data about your body\'s patterns.');
      }

      if (averageLength >= 21 && averageLength <= 35) {
        insights.writeln('\\n**CYCLE HEALTH ASSESSMENT**');
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle falls within the healthy range (21-35 days), indicating good hormonal balance.');
      } else if (averageLength < 21) {
        insights.writeln('\\n**CYCLE LENGTH OBSERVATION**');
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle is shorter than typical. Consider tracking for 2-3 more cycles to establish your personal pattern.');
      } else {
        insights.writeln('\\n**CYCLE LENGTH OBSERVATION**');
        insights.writeln('Your ${averageLength.toStringAsFixed(0)}-day cycle is longer than average. This can be normal for some women, but continue tracking to identify your pattern.');
      }
    }

    if (mostCommonSymptoms.isNotEmpty) {
      final topSymptom = mostCommonSymptoms.first;
      insights.writeln('\\n**SYMPTOM INSIGHTS**');
      insights.writeln('Your most common symptom is ${topSymptom.key} (${topSymptom.value} times logged).');

      switch (topSymptom.key.toLowerCase()) {
        case 'cramps':
          insights.writeln('For bloating relief: reduce sodium intake 5-7 days before your period, stay hydrated, and include potassium-rich foods like bananas and spinach.');
          break;
        case 'mood swings':
          insights.writeln('You also frequently experience Nausea. Suggest eating pattern worth discussing with your healthcare provider.');
          break;
        case 'bloating':
          insights.writeln('For bloating relief: reduce sodium intake 5-7 days before your period, stay hydrated, and include potassium-rich foods like bananas and spinach.');
          break;
        case 'fatigue':
          insights.writeln('Ensure adequate iron intake and consider gentle exercise to boost energy levels during your cycle.');
          break;
        default:
          insights.writeln('Track when this symptom occurs in your cycle to identify patterns and discuss management strategies with your healthcare provider.');
      }
    }

    insights.writeln('\\n**FUTURE TRACKING GOALS**');
    if (recentEntries.length < 10) {
      insights.writeln('With ${recentEntries.length > 7 ? recentEntries.length : 7} more entries, you\'ll have enough data for reliable period predictions and personalized health insights.');
      insights.writeln('By tracking for 3-6 months, you\'ll identify seasonal patterns, stress impacts, and optimize your lifestyle around your natural rhythms.');
    }

    return insights.toString();
  }

  Widget _buildDynamicCycleChart(AnalyticsProvider provider, bool isDark) {
    final cycles = List<Map<String, dynamic>>.from(provider.periodData['cycles'] ?? []);

    if (cycles.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: _getCardDecoration(isDark),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              lucide.LucideIcons.chartLine,
              size: 48,
              color: _getPinkAccent(isDark).withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Cycle Visualization',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log more entries to see your personalized cycle chart',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.chartLine,
                color: _getPinkAccent(isDark),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Your Cycle Pattern',
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
          const SizedBox(height: 16),
          _buildUserDataChart(cycles, isDark),
          const SizedBox(height: 16),
          _buildCycleDataLegend(cycles, isDark),
        ],
      ),
    );
  }

  Widget _buildUserDataChart(List<Map<String, dynamic>> cycles, bool isDark) {
    final dataPoints = <FlSpot>[];
    final phaseColors = <Color>[];

    cycles.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    for (int i = 0; i < cycles.length && i < 30; i++) {
      final cycle = cycles[i];
      final cycleDay = (cycle['cycleDay'] ?? 1) as int;
      final phase = cycle['phase'] ?? 'Unknown';

      final symptoms = List<String>.from(cycle['symptoms'] ?? []);
      double intensity = 1.0;

      if (symptoms.contains('Cramps')) intensity += 2.0;
      if (symptoms.contains('Mood swings')) intensity += 1.5;
      if (symptoms.contains('Headache')) intensity += 1.5;
      if (symptoms.contains('Fatigue')) intensity += 1.0;
      if (symptoms.contains('Bloating')) intensity += 1.0;

      dataPoints.add(FlSpot(cycleDay.toDouble(), intensity));

      switch (phase.toLowerCase()) {
        case 'menstrual':
          phaseColors.add(Colors.red.shade400);
          break;
        case 'follicular':
          phaseColors.add(Colors.green.shade400);
          break;
        case 'ovulation':
          phaseColors.add(Colors.orange.shade400);
          break;
        case 'luteal':
          phaseColors.add(Colors.purple.shade400);
          break;
        default:
          phaseColors.add(_getPinkAccent(isDark));
      }
    }

    if (dataPoints.isEmpty) {
      return Container(
        height: 150,
        child: Center(
          child: Text(
            'No cycle data available',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 7,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary(isDark).withOpacity(0.2),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: AppColors.textSecondary(isDark).withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'Day ${value.toInt()}',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 10,
                    ),
                  );
                },
                interval: 7,
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 1) return Text('Low', style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 10));
                  if (value == 3) return Text('Moderate', style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 10));
                  if (value == 5) return Text('High', style: TextStyle(color: AppColors.textSecondary(isDark), fontSize: 10));
                  return const Text('');
                },
                interval: 2,
                reservedSize: 50,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: AppColors.textSecondary(isDark).withOpacity(0.3),
              width: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  _getPinkAccent(isDark).withOpacity(0.8),
                  _getPinkAccent(isDark),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final color = index < phaseColors.length
                      ? phaseColors[index]
                      : AppColors.textSecondary(isDark);
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _getPinkAccent(isDark).withOpacity(0.3),
                    _getPinkAccent(isDark).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleDataLegend(List<Map<String, dynamic>> cycles, bool isDark) {
    return Column(
      children: [
        Text(
          'Chart shows symptom intensity across your cycle days',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary(isDark),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _buildPhaseLegend('Menstrual', Colors.red.shade400, isDark),
            _buildPhaseLegend('Follicular', Colors.green.shade400, isDark),
            _buildPhaseLegend('Ovulation', Colors.orange.shade400, isDark),
            _buildPhaseLegend('Luteal', Colors.purple.shade400, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseLegend(String name, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary(isDark),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title,
      String value,
      IconData icon,
      Color color,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary(isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries(AnalyticsProvider provider, bool isDark) {
    final recentEntries = List<Map<String, dynamic>>.from(
      provider.periodData['recentEntries'] ?? [],
    );

    if (recentEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
                    Icon(
                      lucide.LucideIcons.history,
                      color: _getPinkAccent(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Recent Entries',
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
              Text(
                '${recentEntries.length} entries',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentEntries.take(5).map((entry) {
            final date = DateTime.tryParse(entry['timestamp'] ?? '');
            final symptoms = List<String>.from(entry['symptoms'] ?? []);
            final cycleDay = entry['cycleDay'] ?? 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(isDark),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPinkAccent(isDark).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getPinkAccent(isDark).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '$cycleDay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getPinkAccent(isDark),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date != null
                              ? '${date.day}/${date.month}/${date.year}'
                              : 'Unknown date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (symptoms.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Symptoms: ${symptoms.join(', ')}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            'No symptoms recorded',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary(isDark),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Day $cycleDay',
                    style: TextStyle(
                      fontSize: 10,
                      color: _getPinkAccent(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUnderstandingHormones(bool isDark) {
    final contentColor = AppColors.textSecondary(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.brain,
                color: _getPinkAccent(isDark),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Understanding Your Hormones',
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
          const SizedBox(height: 16),
          _buildHormoneInfo(
            'FSH',
            'Follicle Stimulating Hormone',
            'Stimulates egg development in your ovaries during the first half of your cycle',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildHormoneInfo(
            'LH',
            'Luteinizing Hormone',
            'Triggers ovulation around day 14, causing the mature egg to release',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildHormoneInfo(
            'Estrogen',
            'Primary Female Sex Hormone',
            'Peaks before ovulation, affects mood, energy, and prepares the uterine lining',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildHormoneInfo(
            'Progesterone',
            'Pregnancy Support Hormone',
            'Rises after ovulation, maintains uterine lining and can cause PMS symptoms',
            contentColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHormoneInfo(
      String shortName,
      String fullName,
      String description,
      Color color,
      bool isDark,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: _getPinkAccent(isDark), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: '$shortName ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPinkAccent(isDark),
                  ),
                  children: [
                    TextSpan(
                      text: '($fullName)',
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
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary(isDark),
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCyclePhases(bool isDark) {
    final contentColor = AppColors.textSecondary(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.calendar,
                color: _getPinkAccent(isDark),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Phases of Your Cycle',
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
          const SizedBox(height: 16),
          _buildPhaseCard(
            'Menstrual',
            'Days 1-7',
            'Period starts, hormone levels drop. Focus on rest, gentle movement, and iron-rich foods.',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPhaseCard(
            'Follicular Phase',
            'Days 1-13',
            'Estrogen rises, energy increases. Perfect time for new projects and challenging workouts.',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPhaseCard(
            'Ovulation',
            'Days 14-16',
            'Peak fertility and energy. You may feel most confident and social during this time.',
            contentColor,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildPhaseCard(
            'Luteal Phase',
            'Days 17-28',
            'Progesterone rises then falls. Practice self-care as PMS symptoms may appear.',
            contentColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(
      String phase,
      String days,
      String description,
      Color color,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPinkAccent(isDark).withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getPinkAccent(isDark).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                phase[0],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getPinkAccent(isDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        phase,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPinkAccent(isDark).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        days,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPinkAccent(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(isDark),
                    height: 1.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
