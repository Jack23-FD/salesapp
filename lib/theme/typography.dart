import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography class that follows the design guide
class AppTypography {
  // Create a base style that all other styles inherit from
  static final _baseStyle = GoogleFonts.urbanist();

  // HEADINGS
  static get h1 => _baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 24.0,
        height: 20 / 24, // Line height 20px
      );

  static get h2 => _baseStyle.copyWith(
        fontWeight: FontWeight.w600, // Semibold
        fontSize: 20.0,
      );

  // TAB BAR
  static get tabBarDefault => _baseStyle.copyWith(
        fontWeight: FontWeight.w500, // Medium
        fontSize: 14.0,
        height: 20 / 14, // Line height 20px
      );

  static get tabBarActive => _baseStyle.copyWith(
        fontWeight: FontWeight.w600, // Semibold
        fontSize: 14.0,
        height: 20 / 14, // Line height 20px
      );

  // POPUP
  static get popupParagraphSentence => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 13.0,
        height: 16 / 13,
      );

  static get popupHeader => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17.0,
        height: 22 / 17,
      );

  static get buttonText => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17.0,
        height: 22 / 17,
      );

  // BUTTONS
  static get smallButton => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14.0,
        height: 20 / 14,
      );

  static get largeButton => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
      );

  // FILTERS AND SORTING
  static get filterTapPart => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 20 / 14,
      );

  static get filterOptionsText => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      );

  static get sortByChanger => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
      );

  static get sortByInfoSection => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.0,
        height: 1.2,
      );

  static get sortByOptions => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 20 / 14,
      );

  // ITEM SECTION
  static get itemName => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 20 / 16,
      );

  static get itemCode => _baseStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 10.0,
        height: 20 / 10,
      );

  static get itemUnitsAndPrice => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 20 / 16,
      );

  static get noItems => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 20 / 16,
      );

  // CATEGORY
  static get categoryRedirectionActive => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14.0,
      );

  static get categoryRedirectionNonActive => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
      );

  static get categoryName => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );

  static get firstScreen => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 20 / 16,
      );

  // BOUND (INPUT FIELDS)
  static get stockInputFields => _baseStyle.copyWith(
    fontSize: 15.0,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  static get stockChunks => _baseStyle.copyWith(
    fontSize: 14.0,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static get stockSubheadings => _baseStyle.copyWith(
    fontSize: 15.0,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  static get stockOtherCaptionText => _baseStyle.copyWith(
    fontSize: 13.0,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  // MENU SCREEN
  static get menuDetails => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );

  // SIGN UP & SIGN IN
  static get primaryText => _baseStyle.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
        height: 1.4,
      );

  static get inputFieldText => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 1.32,
      );

  static get errorStates => _baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 14.0,
        height: 1.32,
      );

  static get regularText => _baseStyle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
      );
}
