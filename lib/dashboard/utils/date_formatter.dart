import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/localization_service.dart';

class DateFormatter {
  // Simple date formatter without using intl package
  static String formatDate(DateTime date) {
    // Get current locale
    final String languageCode = LocalizationService.currentLocale.languageCode;
    
    // Create a locale-aware formatter
    DateFormat formatter;
    
    try {
      // Use locale-specific formatting when available
      formatter = DateFormat('EEEE, MMMM d, yyyy', languageCode);
    } catch (e) {
      // Fallback to English formatting
      formatter = DateFormat('EEEE, MMMM d, yyyy', 'en');
      print("DateFormatter: Failed to create formatter for locale $languageCode: $e");
    }
    
    return formatter.format(date);
  }

  // Format month and year (e.g., "January 2023")
  static String formatMonthYear(DateTime date) {
    final List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final String monthName = monthNames[date.month - 1];
    return '$monthName ${date.year}';
  }

  static Future<DateTime?> selectDate(
      BuildContext context, DateTime selectedDate) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2025, 12, 31),
        helpText: 'SELECT DATE',
        cancelText: 'CANCEL',
        confirmText: 'OK',
        fieldLabelText: 'Date',
        errorFormatText: 'Invalid date format',
        errorInvalidText: 'Invalid date',
        keyboardType: TextInputType.datetime,
      );

      return picked;
    } catch (e) {
      debugPrint('Date picker error: $e');
      return null;
    }
  }

  // Check if two dates represent the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
