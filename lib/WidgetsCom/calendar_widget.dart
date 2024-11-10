import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'dark_mode_handler.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280, // Set a fixed height for the calendar
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 300, // Ensure the calendar doesn't shrink below this height
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.month, // default calendar format to month
            availableCalendarFormats: const {
              CalendarFormat.month: '', // Only display the month format
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set title text color
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: DarkModeHandler.getCalendarTextColor(), // Set left arrow color
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: DarkModeHandler.getCalendarTextColor(), // Set right arrow color
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false, // Hide days outside the month
              todayDecoration: const BoxDecoration(
                color: Color(0xFF0054FF), // Highlight color for the current date
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set default text color
              weekendTextStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set weekend text color
              selectedTextStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set selected text color
              todayTextStyle: TextStyle(color: Colors.white), // Set today text color
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set weekday text color
              weekendStyle: TextStyle(color: DarkModeHandler.getCalendarTextColor()), // Set weekend text color
            ),
            onDaySelected: _onDaySelected,
            rowHeight: 36, // Adjust the row height to reduce the gap between days
          ),
        ),
      ),
    );
  }
}
