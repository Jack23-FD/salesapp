import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  
  factory TranslationService() {
    return _instance;
  }
  
  TranslationService._internal();
  
  String translate(String key, {Map<String, String>? params}) {
    String translated = key.tr;
    
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translated = translated.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return translated;
  }
  
  // Helper method to get current locale
  Locale getCurrentLocale() {
    return Get.locale ?? const Locale('en', 'US');
  }
  
  // Switch language
  Future<void> changeLanguage(String languageCode, String countryCode) async {
    await Get.updateLocale(Locale(languageCode, countryCode));
  }
} 