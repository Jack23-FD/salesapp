import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFFFF8A00); // Primary Orange
  static const Color secondaryColor = Color(0xFF424242); // Dark Grey (was Blue)
  static const Color backgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color secondaryBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color lightOrange = Color(0xFFFFF3E0); // Light Orange
  static const Color lightBlue = Color(0xFFF5F5F5); // Light Grey (was Light Blue)
  static const Color success = Color(0xFF22C55E); // Green - keep
  static const Color successBackground = Color(0xFFDCFCE7); // Light Green - keep
  static const Color warning = Color(0xFFEF4444); // Red - keep
  static const Color warningBackground = Color(0xFFFEE2E2); // Light Red - keep
  static const Color textPrimary = Color(0xFF111111); // Near Black
  static const Color textSecondary = Color(0xFF757575); // Medium Grey
  static const Color borderColor = Color(0xFFE0E0E0); // Light Grey Border
  static const Color dividerColor = Color(0xFFF5F5F5); // Very Light Grey Divider
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // White Card

  // Create the base theme
  static ThemeData get theme {
    final textTheme = GoogleFonts.urbanistTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: secondaryBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: secondaryBackgroundColor,
        surface: cardBackgroundColor,
      ),
      fontFamily: 'Urbanist',
      textTheme: textTheme,
      dividerColor: dividerColor,

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardBackgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.urbanist(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: warning, width: 1),
        ),
        labelStyle: GoogleFonts.urbanist(color: textSecondary),
        hintStyle: GoogleFonts.urbanist(color: textSecondary),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundColor,
        indicatorColor: lightOrange,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryColor);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            );
          }
          return GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
    );
  }
}
