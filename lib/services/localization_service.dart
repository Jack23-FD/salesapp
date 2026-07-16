import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translation_utils.dart';

class LocalizationService {
  // Supported languages
  static final List<Locale> supportedLocales = [
    const Locale('en', 'US'),
    const Locale('ta', 'IN'),
    const Locale('de', 'DE'),
  ];

  // Default locale
  static const Locale defaultLocale = Locale('en', 'US');

  // Private variables
  static late Map<String, dynamic> _localizedValues;
  static Locale _currentLocale = defaultLocale;

  // Getter for current locale
  static Locale get currentLocale => _currentLocale;

  // Initialize the localization service
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('locale');

    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        _currentLocale = Locale(parts[0], parts[1]);
      }
    }

    await loadLanguage(_currentLocale);
  }

  // Load language json file
  static Future<void> loadLanguage(Locale locale) async {
    String languageCode = locale.languageCode;
    String jsonString = await rootBundle.loadString('assets/lang/$languageCode.json');
    _localizedValues = json.decode(jsonString);
    _currentLocale = locale;

    // Save selected locale to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', '${locale.languageCode}_${locale.countryCode}');
  }

  // Change app language
  static Future<void> changeLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      return;
    }
    
    // Clear any cached values before loading new language
    TranslationCache.clear();
    
    print("LocalizationService: Changing language to ${locale.languageCode}");
    await loadLanguage(locale);
    print("LocalizationService: Language changed successfully");
  }

  // Get translated value for a key
  static String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedValues;

    for (String k in keys) {
      if (value == null) return key;
      value = value[k];
    }

    return value?.toString() ?? key;
  }
}

// Provider for localization changes
class LocalizationProvider extends ChangeNotifier {
  Locale _locale = LocalizationService.currentLocale;

  Locale get locale => _locale;

  Future<void> changeLanguage(Locale locale) async {
    print("LocalizationProvider: Language change requested to ${locale.languageCode}");
    
    // Skip if we're already using this locale
    if (_locale.languageCode == locale.languageCode) {
      print("LocalizationProvider: Already using ${locale.languageCode}, forcing refresh");
      // Just force a refresh to be safe
      notifyListeners();
      return;
    }
    
    // Always clear cache before changing language
    TranslationCache.clear();
    
    await LocalizationService.changeLanguage(locale);
    _locale = LocalizationService.currentLocale;
    
    // Make sure cache is cleared again to be safe
    TranslationCache.clear();
    
    // Force UI refresh
    print("LocalizationProvider: Notifying listeners to refresh UI");
    notifyListeners();
    
    // Add a delayed second notification to ensure all widgets update
    // This helps when certain widgets might miss the first notification
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_locale.languageCode == locale.languageCode) {
        print("LocalizationProvider: Sending delayed notification for ${locale.languageCode}");
        notifyListeners();
      }
    });
    
    // Add another delayed notification with a longer delay as a safety net
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_locale.languageCode == locale.languageCode) {
        print("LocalizationProvider: Sending final delayed notification for ${locale.languageCode}");
        notifyListeners();
      }
    });
  }
}

// Extension method for easier access to translated strings
extension TranslateX on String {
  String get tr => LocalizationService.translate(this);
} 