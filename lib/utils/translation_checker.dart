import 'package:flutter/material.dart';

/// A utility class to help find untranslated text during development
class TranslationChecker {
  /// Whether to show debug borders around untranslated text
  static bool showDebugBorders = false;
  
  /// Whether to log warnings about untranslated text
  static bool logWarnings = false;
  
  /// List of text strings that are checked during development
  static final List<String> _checkedStrings = [];
  
  /// Enable debug mode to find untranslated text
  static void enableDebugMode() {
    showDebugBorders = true;
    logWarnings = true;
  }
  
  /// Disable debug mode
  static void disableDebugMode() {
    showDebugBorders = false;
    logWarnings = false;
  }
  
  /// Check if a string is likely to require translation
  static bool shouldTranslate(String text) {
    // Skip strings that are very short or just whitespace
    if (text.trim().length <= 1) return false;
    
    // Skip strings that are likely code or variables
    if (text.contains(RegExp(r'^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$'))) return false;
    
    // Skip strings that are likely dates/times
    if (text.contains(RegExp(r'^\d{1,2}\/\d{1,2}\/\d{2,4}$'))) return false;
    
    // Skip strings that are likely numbers or IDs
    if (text.contains(RegExp(r'^\d+$'))) return false;
    
    return true;
  }
  
  /// Check a Text widget and apply debug styling if needed
  static Widget checkText(Text textWidget) {
    final String? text = textWidget.data;
    if (text == null || !shouldTranslate(text)) return textWidget;
    
    if (logWarnings && !_checkedStrings.contains(text)) {
      _checkedStrings.add(text);
      debugPrint('WARNING: Potentially untranslated text: "$text"');
    }
    
    if (showDebugBorders) {
      return Text(
        text,
        style: textWidget.style?.copyWith(
          background: Paint()..color = Colors.yellow.withOpacity(0.3),
          decoration: TextDecoration.underline,
          decorationColor: Colors.red,
        ),
        textAlign: textWidget.textAlign,
        overflow: textWidget.overflow,
        maxLines: textWidget.maxLines,
      );
    }
    
    return textWidget;
  }
  
  /// Print a summary of untranslated strings found
  static void printSummary() {
    if (_checkedStrings.isEmpty) {
      debugPrint('No untranslated strings detected');
      return;
    }
    
    debugPrint('=== UNTRANSLATED STRINGS SUMMARY ===');
    debugPrint('Found ${_checkedStrings.length} potentially untranslated strings:');
    for (int i = 0; i < _checkedStrings.length; i++) {
      debugPrint('${i + 1}. "${_checkedStrings[i]}"');
    }
    debugPrint('===================================');
  }
} 