import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'typography.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF333366);

  // Create the base theme
  static ThemeData get theme {
    // Set up base text theme using Google Fonts directly
    final textTheme = GoogleFonts.urbanistTextTheme();

    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      fontFamily: 'Urbanist', // Ensure font family is set

      // Apply Google Fonts directly to the text theme
      textTheme: textTheme,

      // Set explicitly for all theme components
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        titleTextStyle: GoogleFonts.urbanist(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.urbanist(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.urbanist(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.urbanist(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
