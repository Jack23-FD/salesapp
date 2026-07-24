import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/date_formatter.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onClose;

  const CustomCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _currentMonth;
  late List<DateTime> _calendarDays;

  @override
  void initState() {
    super.initState();
    _currentMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    _calendarDays = _generateCalendarDays();
  }

  List<DateTime> _generateCalendarDays() {
    // First day of the month
    final DateTime firstDay =
        DateTime(_currentMonth.year, _currentMonth.month, 1);

    // Last day of the month
    final DateTime lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Find the first day of the week containing firstDay
    int startWeekday = firstDay.weekday;
    final DateTime firstCalendarDay =
        firstDay.subtract(Duration(days: startWeekday - 1));

    // Add days to create a complete 6-week calendar
    final List<DateTime> days = [];
    for (int i = 0; i < 42; i++) {
      days.add(firstCalendarDay.add(Duration(days: i)));
    }

    return days;
  }

  void _gotoPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _calendarDays = _generateCalendarDays();
    });
  }

  void _gotoNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _calendarDays = _generateCalendarDays();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with month/year and navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormatter.formatMonthYear(_currentMonth),
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.0,
                        color: const Color(0xFF00BBF9),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildNavButton(
                      onPressed: _gotoPreviousMonth,
                      icon: Icons.chevron_left,
                    ),
                    const SizedBox(width: 8),
                    _buildNavButton(
                      onPressed: _gotoNextMonth,
                      icon: Icons.chevron_right,
                    ),
                    const SizedBox(width: 8),
                    _buildNavButton(
                      onPressed: widget.onClose,
                      icon: Icons.close,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Days of week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildWeekdayHeaders(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
              ),
              itemCount: _calendarDays.length,
              itemBuilder: (context, index) {
                final day = _calendarDays[index];
                return _buildDayCell(day);
              },
            ),

            // Bottom actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    final today = DateTime.now();
                    // Pass today's date to parent and close calendar
                    widget.onDateSelected(today);
                    widget.onClose();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                      color: const Color(0xFF00BBF9),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BBF9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF00BBF9), size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final bool isCurrentMonth = day.month == _currentMonth.month;
    final bool isSelected = _isSameDay(day, widget.selectedDate);
    final bool isToday = _isSameDay(day, DateTime.now());

    return InkWell(
      onTap: () {
        if (isCurrentMonth) {
          widget.onDateSelected(day);
        }
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00BBF9)
              : isToday
                  ? const Color(0xFFE0F2FE)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: isToday && !isSelected
              ? Border.all(color: const Color(0xFF00BBF9), width: 1)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          day.day.toString(),
          style: GoogleFonts.urbanist(
            fontWeight:
                isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14.0,
            color: isSelected
                ? Colors.white
                : !isCurrentMonth
                    ? Colors.grey[400]
                    : isToday
                        ? const Color(0xFF00BBF9)
                        : Colors.black87,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildWeekdayHeaders() {
    final List<String> weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return weekdays.map((day) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          day,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00BBF9),
          ),
        ),
      );
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
