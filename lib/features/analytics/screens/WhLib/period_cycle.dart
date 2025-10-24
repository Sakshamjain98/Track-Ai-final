import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Assuming DailyDetailsScreen exists and accepts DateTime
// import 'path/to/DailyDetailsScreen.dart';

class PeriodDashboard extends StatefulWidget {
  const PeriodDashboard({Key? key}) : super(key: key);

  @override
  State<PeriodDashboard> createState() => _PeriodDashboardState();
}

class _PeriodDashboardState extends State<PeriodDashboard> {
  int cycleDay = 1;
  String predictedPeriod = '---';
  String fertileWindow = '---';
  String currentPhase = 'Menstrual Phase';
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month); // Track selected month for calendar
  bool _isLoadingData = true;
  int _cycleLengthDays = 28; // Default
  int _periodLengthDays = 5; // Default
  DateTime? _lastPeriodDate;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _loadCycleData() async {
    setState(() {
      _isLoadingData = true;
      predictedPeriod = '---';
      fertileWindow = '---';
      currentPhase = 'Loading...';
      cycleDay = 1;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          predictedPeriod = 'Login Required';
          fertileWindow = 'Login Required';
          currentPhase = 'Login Required';
          _isLoadingData = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('period_settings')
          .doc('config')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        _lastPeriodDate = (data['lastPeriodDate'] as Timestamp?)?.toDate();
        _cycleLengthDays = (data['cycleLengthDays'] as num?)?.toInt() ?? 28;
        _periodLengthDays = (data['periodLengthDays'] as num?)?.toInt() ?? 5;

        if (_lastPeriodDate != null) {
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final daysSinceStart = today.difference(_lastPeriodDate!).inDays;

          final calculatedCycleDay = (daysSinceStart % _cycleLengthDays) + 1;

          final nextPeriod = _lastPeriodDate!.add(Duration(days: _cycleLengthDays));
          final periodEndDate = nextPeriod.add(Duration(days: _periodLengthDays - 1));

          // Ovulation is typically 14 days BEFORE the *next* period starts
          final ovulationDay = nextPeriod.subtract(const Duration(days: 14));
          final fertileStart = ovulationDay.subtract(const Duration(days: 5));
          final fertileEnd = ovulationDay.add(const Duration(days: 1)); // Include ovulation day

          setState(() {
            cycleDay = calculatedCycleDay;
            predictedPeriod = '${DateFormat('MMM d').format(nextPeriod)} - ${DateFormat('d').format(periodEndDate)}';
            fertileWindow = '${DateFormat('MMM d').format(fertileStart)} - ${DateFormat('d').format(fertileEnd)}';
            currentPhase = _getCurrentPhase(calculatedCycleDay, _periodLengthDays, _cycleLengthDays);
            _isLoadingData = false;
          });
        } else {
          if (mounted) {
            setState(() {
              predictedPeriod = 'Setup Required';
              fertileWindow = 'Setup Required';
              currentPhase = 'Setup Required';
              _isLoadingData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            predictedPeriod = 'Setup Required';
            fertileWindow = 'Setup Required';
            currentPhase = 'Setup Required';
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print("Error loading cycle data: $e"); // Log error
      if (mounted) {
        setState(() {
          predictedPeriod = 'Error Loading';
          fertileWindow = 'Error Loading';
          currentPhase = 'Error';
          _isLoadingData = false;
        });
      }
    }
  }

  // Updated phase calculation based on typical lengths
  String _getCurrentPhase(int day, int periodLength, int cycleLength) {
    // Ensure periodLength isn't longer than cycleLength for safety
    periodLength = periodLength.clamp(1, cycleLength - 3); // Need at least 3 days for other phases

    int approxOvulationDay = cycleLength - 14; // Typical ovulation day calculation
    int follicularEnd = approxOvulationDay - 3; // Follicular ends a few days before ovulation
    int ovulationStart = approxOvulationDay - 2;
    int ovulationEnd = approxOvulationDay + 1; // Fertile window includes ovulation day

    if (day <= periodLength) return 'Menstrual Phase';
    if (day <= follicularEnd) return 'Follicular Phase';
    if (day >= ovulationStart && day <= ovulationEnd) return 'Ovulation Phase'; // Fertile Window
    return 'Luteal Phase';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5E6F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'CYCLE TRACKER',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Implement Notifications Action
            },
          ),
        ],
      ),
      body: _buildTodayTab(),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column( // Use Column instead of SingleChildScrollView for fixed structure
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(thickness: 1, height: 1),
              _buildMonthSelector(),
              const Divider(thickness: 1, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildWeekdayHeaders(), // Separate widget for headers
              ),
              // Make the calendar grid expand
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildCalendarGrid(), // Use GridView
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView( // Keep this for the main tab content
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildCycleDayCircle(),
          const SizedBox(height: 20),
          _buildPredictions(),
          const SizedBox(height: 30),
          _buildQuickLogSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCycleDayCircle() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE91E63).withOpacity(0.3),
            const Color(0xFFE91E63).withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements (optional)
          Positioned(
            top: 20, right: 30,
            child: Icon(Icons.local_florist, color: const Color(0xFFE91E63).withOpacity(0.15), size: 40),
          ),
          Positioned(
            bottom: 30, left: 20,
            child: Icon(Icons.bubble_chart, color: const Color(0xFFE91E63).withOpacity(0.15), size: 35),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CYCLE DAY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingData
                    ? SizedBox(height: 64, child: Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.black54))))
                    : Text(
                  '$cycleDay',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1, // Adjust line height
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoadingData ? 'Loading...' : currentPhase,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPredictions() {
    // Common text style
    final baseStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.7));
    final valueStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87);
    final loadingStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: Colors.black.withOpacity(0.5));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFE91E63)),
              const SizedBox(width: 8),
              Text('Next Period: ', style: baseStyle),
              _isLoadingData
                  ? Text('Calculating...', style: loadingStyle)
                  : Text(predictedPeriod, style: valueStyle),
            ],
          ),
          const SizedBox(height: 8), // Increased spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 16, color: Color(0xFFE91E63)),
              const SizedBox(width: 8),
              Text('Fertile Days: ', style: baseStyle),
              _isLoadingData
                  ? Text('Calculating...', style: loadingStyle)
                  : Text(fertileWindow, style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Log',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickLogButton(
                icon: Icons.water_drop_outlined,
                label: 'Period',
                color: const Color(0xFFE91E63),
                // Navigate and refresh data on return
                onTap: () => Navigator.pushNamed(context, '/log-period')
                    .then((_) => _loadCycleData()),
              ),
              _buildQuickLogButton(
                icon: Icons.healing_outlined,
                label: 'Symptoms',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/log-symptoms')
                    .then((_) => _loadCycleData()), // Refresh data
              ),
              _buildQuickLogButton(
                icon: Icons.sentiment_satisfied_outlined,
                label: 'Mood',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/log-mood')
                    .then((_) => _loadCycleData()), // Refresh data
              ),
              _buildQuickLogButton(
                icon: Icons.favorite_outline, // Changed icon for variety
                label: 'Activity',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/log-activity')
                    .then((_) => _loadCycleData()), // Refresh data
              ),
              _buildQuickLogButton( // Added Notes Button
                icon: Icons.note_alt_outlined,
                label: 'Notes',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, '/log-notes')
                    .then((_) => _loadCycleData()), // Refresh data
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensure minimum vertical space
        children: [
          Container(
            width: 55, // Slightly smaller
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5, // Thinner border
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26, // Slightly smaller icon
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            label,
            style: const TextStyle(
              fontSize: 11, // Smaller font
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- Calendar Widgets ---

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0), // Adjust padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
              });
            },
            tooltip: 'Previous Month',
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(
              fontSize: 18, // Slightly smaller font
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
              });
            },
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']; // Use 2-letter codes
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) => Text(
        day,
        style: TextStyle(
          fontSize: 12, // Smaller font
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      )).toList(),
    );
  }

  // UPDATED: Uses GridView for better layout and overflow prevention
  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    // Adjust weekday calculation: Sunday=0, Monday=1, ..., Saturday=6
    final weekdayOfFirstDay = firstDayOfMonth.weekday % 7; // Sunday is 7, map to 0

    // Calculate total items needed in the grid (including placeholders)
    final totalGridSlots = ((daysInMonth + weekdayOfFirstDay) / 7).ceil() * 7;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the drawer
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1, // Adjust aspect ratio for better spacing
        mainAxisSpacing: 4, // Add vertical spacing
        crossAxisSpacing: 4, // Add horizontal spacing
      ),
      itemCount: totalGridSlots,
      itemBuilder: (context, index) {
        if (index < weekdayOfFirstDay || index >= daysInMonth + weekdayOfFirstDay) {
          // Empty placeholder cell
          return Container();
        } else {
          // Actual day cell
          final day = index - weekdayOfFirstDay + 1;
          final currentDate = DateTime(selectedMonth.year, selectedMonth.month, day);
          final isToday = DateUtils.isSameDay(currentDate, DateTime.now());

          // --- Add Logic Here to Determine Period/Fertile Day ---
          bool isPeriodDay = false; // Placeholder - implement your logic
          bool isFertileDay = false; // Placeholder - implement your logic
          // Example logic (replace with your actual calculation based on _lastPeriodDate etc.)
          // if (_lastPeriodDate != null) {
          //    Calculate period start/end and fertile window start/end for the *currentDate*
          // }
          // --- End of Placeholder Logic ---

          BoxDecoration decoration = BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent, // Default
            border: isToday ? Border.all(color: const Color(0xFFE91E63), width: 1.5) : null,
          );
          Color textColor = Colors.black87;

          if (isPeriodDay) {
            decoration = BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE91E63).withOpacity(0.3));
            textColor = Color(0xFFE91E63);
          } else if (isFertileDay) {
            decoration = BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.2));
            textColor = Colors.blue.shade700;
          } else if (isToday) {
            // Border is already set above
            textColor = Color(0xFFE91E63);
          }


          return GestureDetector(
            onTap: () {
              // Close drawer before navigating
              Navigator.pop(context); // Close the endDrawer
              Navigator.pushNamed(
                context,
                '/daily-details',
                arguments: currentDate,
              ).then((_) => _loadCycleData()); // Refresh dashboard data when returning
            },
            child: Container(
              decoration: decoration,
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13, // Slightly smaller font
                  fontWeight: isToday || isPeriodDay || isFertileDay ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          );
        }
      },
    );
  }
} // End of _PeriodDashboardState