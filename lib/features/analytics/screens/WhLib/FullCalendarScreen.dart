import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'DailyDetailsScreen.dart'; // Make sure this path is correct

class FullCalendarScreen extends StatefulWidget {
  const FullCalendarScreen({Key? key}) : super(key: key);

  @override
  State<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends State<FullCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6F1), // Pinkish background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CALENDAR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black, // Black type
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; // update 'focusedDay' here
                  });

                  // Navigate to DailyDetailsScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyDetailsScreen(
                        selectedDate: selectedDay,
                      ),
                    ),
                  );
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // --- Styling ---
                calendarStyle: const CalendarStyle(
                  // Selected day
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFFE91E63), // Pink
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.white),
                  // Today
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFFFC1E3), // Light pink
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: Colors.black),
                  // Default
                  defaultTextStyle: TextStyle(color: Colors.black87),
                  weekendTextStyle: TextStyle(color: Color(0xFFE91E63)),
                  outsideTextStyle: TextStyle(color: Colors.black26),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.black, // Black type
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon:
                  const Icon(Icons.chevron_left, color: Color(0xFFE91E63)),
                  rightChevronIcon:
                  const Icon(Icons.chevron_right, color: Color(0xFFE91E63)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // You can add a legend here if you want
          ],
        ),
      ),
    );
  }
}