import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Utility class to find potentially untranslated strings in the codebase
class FindUntranslatedStrings {
  /// Directory paths to scan
  final List<String> directoriesToScan;
  
  /// File extensions to check
  final List<String> extensionsToCheck;
  
  /// Directory paths to exclude
  final List<String> directoriesToExclude;
  
  /// Words/patterns to ignore
  final List<RegExp> patternsToIgnore;
  
  /// Set of potentially untranslated strings
  final Set<String> potentialUntranslatedStrings = {};
  
  /// Set of keys already in the translation files
  final Set<String> existingTranslationKeys = {};
  
  /// Path to the EN translation file
  final String enTranslationFilePath;
  
  /// Path to the TA translation file
  final String taTranslationFilePath;
  
  FindUntranslatedStrings({
    this.directoriesToScan = const ['lib'],
    this.extensionsToCheck = const ['.dart'],
    this.directoriesToExclude = const ['lib/generated', 'test'],
    this.patternsToIgnore = const [
      RegExp(r'^[0-9]+$'),
      RegExp(r'^[0-9]+\.[0-9]+$'),
      RegExp(r'^[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$'),
      RegExp(r'^https?://'),
      RegExp(r'^[a-zA-Z0-9_]+@[a-zA-Z0-9_]+\.[a-zA-Z]+$'),
      RegExp(r'^[a-zA-Z0-9_]+$'),
    ],
    this.enTranslationFilePath = 'assets/lang/en.json',
    this.taTranslationFilePath = 'assets/lang/ta.json',
  });
  
  /// Run the scan and print results to console
  Future<void> run() async {
    await _loadExistingTranslationKeys();
    await _scanDirectories();
    _generateResults();
  }
  
  /// Load existing translation keys from translation files
  Future<void> _loadExistingTranslationKeys() async {
    try {
      final enFile = File(enTranslationFilePath);
      if (await enFile.exists()) {
        final content = await enFile.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        _extractKeys('', json);
      }
    } catch (e) {
      debugPrint('Error loading EN translation file: $e');
    }
  }
  
  /// Extract all keys from a nested Map
  void _extractKeys(String prefix, Map<String, dynamic> json) {
    json.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _extractKeys(fullKey, value);
      } else {
        existingTranslationKeys.add(fullKey);
      }
    });
  }
  
  /// Scan directories for potential untranslated strings
  Future<void> _scanDirectories() async {
    for (final dirPath in directoriesToScan) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await _scanDirectory(dir);
      }
    }
  }
  
  /// Scan a specific directory recursively
  Future<void> _scanDirectory(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final filePath = entity.path;
        
        // Skip if in excluded directories
        if (directoriesToExclude.any((excludePath) => filePath.contains(excludePath))) {
          continue;
        }
        
        // Check if file has the right extension
        if (extensionsToCheck.any((ext) => filePath.endsWith(ext))) {
          await _scanFile(entity);
        }
      }
    }
  }
  
  /// Scan a single file for potential untranslated strings
  Future<void> _scanFile(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Skip commented lines
        if (line.trim().startsWith('//') || line.trim().startsWith('/*')) {
          continue;
        }
        
        // Skip lines with imports
        if (line.trim().startsWith('import ') || line.trim().startsWith('export ')) {
          continue;
        }
        
        // Look for Text widgets with literal strings
        _checkWidgetStringLiterals(line, file.path, i + 1);
        
        // Look for strings that aren't using translation
        _checkForUntranslatedStrings(line, file.path, i + 1);
      }
    } catch (e) {
      debugPrint('Error scanning file ${file.path}: $e');
    }
  }
  
  /// Check for Text widget string literals
  void _checkWidgetStringLiterals(String line, String filePath, int lineNumber) {
    // Regex to find Text('...') or Text("...")
    final regex = RegExp(r'Text\([\'"]([^\'"]+)[\'"]\)');
    final matches = regex.allMatches(line);
    
    for (final match in matches) {
      final text = match.group(1);
      if (text != null && text.trim().isNotEmpty && !_shouldIgnore(text)) {
        potentialUntranslatedStrings.add('$text ($filePath:$lineNumber)');
      }
    }
  }
  
  /// Check for untranslated strings
  void _checkForUntranslatedStrings(String line, String filePath, int lineNumber) {
    // Look for strings with more than 2 words that aren't marked for translation
    // This is a simple heuristic and will need refinement based on your app
    final singleQuoteRegex = RegExp(r'\'([^\']+)\'');
    final doubleQuoteRegex = RegExp(r'"([^"]+)"');
    
    Iterable<RegExpMatch> matches = singleQuoteRegex.allMatches(line);
    _processMatches(matches, filePath, lineNumber);
    
    matches = doubleQuoteRegex.allMatches(line);
    _processMatches(matches, filePath, lineNumber);
  }
  
  /// Process regex matches and add potential untranslated strings
  void _processMatches(Iterable<RegExpMatch> matches, String filePath, int lineNumber) {
    for (final match in matches) {
      final text = match.group(1);
      if (text != null && 
          text.trim().isNotEmpty && 
          text.split(' ').length > 2 &&
          !_shouldIgnore(text) &&
          !line.contains('.tr') &&
          !line.contains('translate()') &&
          !line.contains('TranslatableText')) {
        potentialUntranslatedStrings.add('$text ($filePath:$lineNumber)');
      }
    }
  }
  
  /// Check if a string should be ignored
  bool _shouldIgnore(String text) {
    // Ignore strings that match ignore patterns
    if (patternsToIgnore.any((pattern) => pattern.hasMatch(text))) {
      return true;
    }
    
    // Ignore very short strings
    if (text.trim().length < 3) {
      return true;
    }
    
    // Ignore strings that are just variable names
    if (text.trim().startsWith(r'$')) {
      return true;
    }
    
    return false;
  }
  
  /// Generate and print the results
  void _generateResults() {
    if (potentialUntranslatedStrings.isEmpty) {
      debugPrint('No potentially untranslated strings found.');
      return;
    }
    
    debugPrint('\n==== POTENTIALLY UNTRANSLATED STRINGS ====');
    debugPrint('Found ${potentialUntranslatedStrings.length} potentially untranslated strings:\n');
    
    int i = 1;
    for (final str in potentialUntranslatedStrings) {
      debugPrint('${i++}. $str');
    }
    
    debugPrint('\n==== SUGGESTIONS ====');
    debugPrint('Add these keys to your translation files:\n');
    
    for (final str in potentialUntranslatedStrings) {
      final textPart = str.split(' (')[0];
      final suggestedKey = _suggestKey(textPart);
      
      if (!existingTranslationKeys.contains(suggestedKey)) {
        debugPrint('"$suggestedKey": "$textPart",');
      }
    }
  }
  
  /// Suggest a translation key from a string
  String _suggestKey(String text) {
    // Convert the text to lowercase, remove special chars, and replace spaces with dots
    final key = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '.')
        .trim();
        
    if (key.length > 30) {
      return key.substring(0, 30);
    }
    
    return key;
  }
  
  /// Utility method to run this tool from the console
  static void findStrings() {
    FindUntranslatedStrings().run();
  }
} 