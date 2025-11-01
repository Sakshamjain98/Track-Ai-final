import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Import your other screens
import 'FullCalendarScreen.dart';
import 'analyticsscreen.dart'; // Make sure this path is correct
import 'InsightsScreen.dart'; // Make sure this path is correct

class PeriodDashboard extends StatefulWidget {
  const PeriodDashboard({Key? key}) : super(key: key);

  @override
  State<PeriodDashboard> createState() => _PeriodDashboardState();
}

class _PeriodDashboardState extends State<PeriodDashboard> {
  int cycleDay = 1;
  String predictedPeriod = '---';
  String fertileWindow = '---';
  String currentPhase = 'Loading...';
  bool _isLoadingData = true;
  int _cycleLengthDays = 28;
  int _periodLengthDays = 5;
  DateTime? _lastPeriodDate;
  DateTime _currentDate = DateTime.now();

  // --- NEW STATE VARIABLES ---
  int _daysToOvulation = 0;
  String _pregnancyChance = ''; // Will store "High", "Low", etc.
  // -------------------------

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _showLogCycleForm() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogMenstrualCycleForm(),
    );

    if (result == true) {
      _loadCycleData();
    }
  }

  // --- MODIFIED FUNCTION ---
  Future<void> _loadCycleData() async {
    setState(() {
      _isLoadingData = true;
      predictedPeriod = '---';
      fertileWindow = '---';
      currentPhase = 'Loading...';
      _pregnancyChance = ''; // Reset
      cycleDay = 1;
      _daysToOvulation = 0; // Reset countdown
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
          final today =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final daysSinceStart = today.difference(_lastPeriodDate!).inDays;

          final calculatedCycleDay = (daysSinceStart % _cycleLengthDays) + 1;

          final nextPeriod =
          _lastPeriodDate!.add(Duration(days: _cycleLengthDays));
          final periodEndDate =
          nextPeriod.add(Duration(days: _periodLengthDays - 1));

          final ovulationDay = nextPeriod.subtract(const Duration(days: 14));
          final fertileStart = ovulationDay.subtract(const Duration(days: 5));
          final fertileEnd = ovulationDay.add(const Duration(days: 1));

          int approxOvulationDayNum = _cycleLengthDays - 14;
          DateTime currentCycleOvulationDate =
          _lastPeriodDate!.add(Duration(days: approxOvulationDayNum));

          int daysToOvulation;
          if (today.isAfter(currentCycleOvulationDate)) {
            DateTime nextCycleOvulationDate =
            currentCycleOvulationDate.add(Duration(days: _cycleLengthDays));
            daysToOvulation = nextCycleOvulationDate.difference(today).inDays;
          } else {
            daysToOvulation = currentCycleOvulationDate.difference(today).inDays;
          }

          // --- MODIFIED: Get phase and chance from map ---
          final phaseData = _getCurrentPhase(
              calculatedCycleDay, _periodLengthDays, _cycleLengthDays, ovulationDay, fertileStart, fertileEnd);

          setState(() {
            cycleDay = calculatedCycleDay;
            _daysToOvulation = daysToOvulation; // <-- Save to state
            predictedPeriod =
            '${DateFormat('MMM d').format(nextPeriod)} - ${DateFormat('d').format(periodEndDate)}';
            fertileWindow =
            '${DateFormat('MMM d').format(fertileStart)} - ${DateFormat('d').format(fertileEnd)}';

            // --- MODIFIED: Set new state variables ---
            currentPhase = phaseData['phase']!;
            _pregnancyChance = phaseData['chance']!;
            // -----------------------------------------

            _isLoadingData = false;
          });
        } else {
          if (mounted) {
            setState(() {
              predictedPeriod = 'Setup Required';
              fertileWindow = 'Setup Required';
              currentPhase = 'Log your cycle';
              _pregnancyChance = ''; // <-- Reset
              _isLoadingData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            predictedPeriod = 'Setup Required';
            fertileWindow = 'Setup Required';
            currentPhase = 'Log your cycle';
            _pregnancyChance = ''; // <-- Reset
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print("Error loading cycle data: $e");
      if (mounted) {
        setState(() {
          predictedPeriod = 'Error Loading';
          fertileWindow = 'Error Loading';
          currentPhase = 'Error';
          _pregnancyChance = ''; // <-- Reset
          _isLoadingData = false;
        });
      }
    }
  }
  // -------------------------

  // --- MODIFIED: Function now returns a Map ---
  Map<String, String> _getCurrentPhase(int day, int periodLength, int cycleLength, DateTime ovulationDay, DateTime fertileStart, DateTime fertileEnd) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // 1. Menstrual Phase
    if (day <= periodLength) {
      return {'phase': 'Menstrual Phase', 'chance': 'Very Low chance of pregnancy'};
    }

    // 2. Ovulation Phase (Fertile Window)
    if (DateUtils.isSameDay(today, ovulationDay)) {
      return {'phase': 'Ovulation Day', 'chance': 'High chance of pregnancy'};
    }
    if ((today.isAfter(fertileStart) || DateUtils.isSameDay(today, fertileStart)) &&
        (today.isBefore(fertileEnd) || DateUtils.isSameDay(today, fertileEnd))) {
      return {'phase': 'Ovulation Phase', 'chance': 'High chance of pregnancy'};
    }

    // 3. Follicular Phase (after period, before fertile window)
    int approxOvulationDay = cycleLength - 14;
    // Assuming fertile window starts 5 days before ovulation, so "low" is before that.
    int follicularEnd = approxOvulationDay - 6;

    if (day <= follicularEnd) {
      return {'phase': 'Follicular Phase', 'chance': 'Low chance of pregnancy'};
    }

    // 4. Luteal Phase (after fertile window)
    // Anything after fertile window and before next period
    return {'phase': 'Luteal Phase', 'chance': 'Very Low chance of pregnancy'};
  }
  // ----------------------------------------------


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final weekDates = _getWeekDates(_currentDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'TODAY',
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
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFFE91E63)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FullCalendarScreen()),
              );
            },
            tooltip: 'View Calendar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: _buildWeekCalendar(screenWidth, screenHeight, weekDates),
            ),
            const SizedBox(height: 30),
            _buildCycleDayCircle(), // This widget is modified
            const SizedBox(height: 20),
            _buildLogCycleWidget(),
            const SizedBox(height: 20),
            _buildPredictions(), // This widget is modified
            const SizedBox(height: 30),
            _buildQuickLogSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<DateTime> _getWeekDates(DateTime date) {
    // ... (This function is correct, no changes needed) ...
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Widget _buildWeekCalendar(
      double screenWidth,
      double screenHeight,
      List<DateTime> weekDates,
      ) {
    // ... (This function is correct, no changes needed) ...
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDates.asMap().entries.map((entry) {
          final date = entry.value;
          final dayLetters = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
          final dayLetter = dayLetters[date.weekday % 7];

          final today = DateTime.now();
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;

          return Column(
            children: [
              Text(
                dayLetter,
                style: TextStyle(
                  color: isToday ? Color(0xFFE91E63) : Colors.black54,
                  fontSize: screenWidth * 0.035,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              SizedBox(height: screenHeight * 0.008),
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                    color: isToday ? Color(0xFFE91E63).withOpacity(0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday ? Border.all(color: Color(0xFFE91E63), width: 1.5) : null
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isToday ? Color(0xFFE91E63) : Colors.black87,
                      fontSize: screenWidth * 0.04,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- MODIFIED WIDGET ---
  Widget _buildCycleDayCircle() {
    String ovulationText = '';

    // --- NEW: Logic for pregnancy chance color ---
    Color chanceColor = Colors.black.withOpacity(0.6); // Default
    if (_pregnancyChance.contains('High')) {
      chanceColor = Color(0xFFE91E63); // Pink
    } else if (_pregnancyChance.contains('Low')) {
      chanceColor = Colors.teal; // Green/Teal
    } else if (_pregnancyChance.contains('Very Low')) {
      chanceColor = Colors.black.withOpacity(0.6); // Grey
    }
    // ------------------------------------------

    if (_isLoadingData) {
      ovulationText = '...';
    } else if (_daysToOvulation == 0) {
      ovulationText = 'Ovulation Today';
    } else if (_daysToOvulation == 1) {
      ovulationText = 'Ovulation in 1 day';
    } else if (_daysToOvulation > 1) {
      ovulationText = 'Ovulation in $_daysToOvulation days';
    }

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
      child: Center(
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
                ? SizedBox(
                height: 64,
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Colors.black54))))
                : Text(
              '$cycleDay',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),

            if (ovulationText.isNotEmpty)
              Text(
                ovulationText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE91E63),
                    height: 1.2
                ),
              ),
            const SizedBox(height: 4),

            // --- MODIFIED: Show phase and chance separately ---
            Text(
              _isLoadingData ? 'Loading...' : currentPhase,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.2
              ),
            ),

            // ------------------------------------------------
          ],
        ),
      ),
    );
  }
  // -------------------------

  Widget _buildLogCycleWidget() {
    // ... (This function is correct, no changes needed) ...
    return GestureDetector(
      onTap: _showLogCycleForm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Color(0xFFE91E63), size: 18),
            SizedBox(width: 8),
            Text(
              'Log or edit your cycle',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED WIDGET ---
  Widget _buildPredictions() {
    final baseStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black.withOpacity(0.7));
    final valueStyle =
    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87);
    final loadingStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: Colors.black.withOpacity(0.5));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFFE91E63)),
              const SizedBox(width: 8),
              Text('Next Period: ', style: baseStyle),
              _isLoadingData
                  ? Text('Calculating...', style: loadingStyle)
                  : Text(predictedPeriod, style: valueStyle),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 15),

          if (!_isLoadingData && _pregnancyChance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _pregnancyChance,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600, // Bolder
                    color: Colors.teal, // Use dynamic color
                    height: 1.2
                ),
              ),
            ),

          // --- REMOVED: Fertile hint text (now in circle) ---

        ],
      ),
    );
  }
  // -------------------------

  Widget _buildQuickLogSection() {
    // ... (This function is correct, no changes needed) ...
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Quick Log',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildQuickLogButton(
                  icon: Icons.water_drop_outlined,
                  label: 'Period',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.pushNamed(context, '/log-period')
                      .then((_) => _loadCycleData()),
                ),
                const SizedBox(width: 20),
                _buildQuickLogButton(
                  icon: Icons.healing_outlined,
                  label: 'Symptoms',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.pushNamed(context, '/log-symptoms')
                      .then((_) => _loadCycleData()),
                ),
                const SizedBox(width: 20),
                _buildQuickLogButton(
                  icon: Icons.sentiment_satisfied_outlined,
                  label: 'Mood',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.pushNamed(context, '/log-mood')
                      .then((_) => _loadCycleData()),
                ),
                const SizedBox(width: 20),
                _buildQuickLogButton(
                  icon: Icons.favorite_outline,
                  label: 'Activity',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.pushNamed(context, '/log-activity')
                      .then((_) => _loadCycleData()),
                ),
                const SizedBox(width: 20),
                _buildQuickLogButton(
                  icon: Icons.note_alt_outlined,
                  label: 'Notes',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.pushNamed(context, '/log-notes')
                      .then((_) => _loadCycleData()),
                ),
              ],
            ),
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
    // ... (This function is correct, no changes needed) ...
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// --- LOG MENSTRUAL CYCLE FORM (No changes needed) ---
// -------------------------------------------------------------------

class LogMenstrualCycleForm extends StatefulWidget {
  const LogMenstrualCycleForm({Key? key}) : super(key: key);

  @override
  State<LogMenstrualCycleForm> createState() => _LogMenstrualCycleFormState();
}

class _LogMenstrualCycleFormState extends State<LogMenstrualCycleForm> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final TextEditingController _cycleLengthController = TextEditingController(text: '28');
  final TextEditingController _periodLengthController = TextEditingController(text: '5');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // You could fetch existing data here if you want this form to 'edit'
    // For now, it just sets new data.
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _saveEntry() async {
    // ... (This function is correct, no changes needed) ...
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Not logged in.')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      final int cycleLength = int.parse(_cycleLengthController.text);
      final int periodLength = int.parse(_periodLengthController.text);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('period_settings')
          .doc('config')
          .set({
        'lastPeriodDate': Timestamp.fromDate(_selectedDate),
        'cycleLengthDays': cycleLength,
        'periodLengthDays': periodLength,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cycle data saved!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error saving entry: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Menstrual Cycle',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the start date of your last period.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildCalendarGrid(),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Typical Cycle Length (days)*',
                controller: _cycleLengthController,
                hint: 'e.g., 28',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Period Length (days)',
                controller: _periodLengthController,
                hint: 'e.g., 5',
                isOptional: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Save Entry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth =
    DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth =
    DateTime(_currentMonth.year, _currentMonth.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday % 7;

    final weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1,
      ),
      itemCount: daysInMonth + weekdayOfFirstDay + 7,
      itemBuilder: (context, index) {
        if (index < 7) {
          return Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        int gridIndex = index - 7;
        if (gridIndex < weekdayOfFirstDay) {
          return Container();
        }

        final day = gridIndex - weekdayOfFirstDay + 1;
        if (day > daysInMonth) {
          return Container();
        }

        final currentDate =
        DateTime(_currentMonth.year, _currentMonth.month, day);
        final isSelected = DateUtils.isSameDay(currentDate, _selectedDate);

        return GestureDetector(
          onTap: () => _onDateSelected(currentDate),
          child: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.black),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFFF5E6F1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFFE91E63)),
            ),
          ),
          validator: (value) {
            // ... (Validator logic is correct, no changes needed) ...
            if (!isOptional && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            if (value != null && value.isNotEmpty) {
              final n = int.tryParse(value);
              if (n == null || n <= 0) {
                return 'Please enter a valid number';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------
// --- MAIN NAVIGATION SCREEN (No changes needed) ---
// -------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PeriodDashboard(), // Tab 0: Today
    InsightsScreen(),  // Tab 1: Insights
    AnalyticsScreen(), // Tab 2: Analytics
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFE91E63), // Bright pink for selected
        unselectedItemColor: const Color(0xFFFFC1E3), // Light pink for unselected
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: _onItemTapped,
      ),
    );
  }
}