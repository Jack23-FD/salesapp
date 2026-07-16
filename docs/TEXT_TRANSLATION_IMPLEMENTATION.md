# Text Translation Implementation Guide

## Overview
This guide outlines the approach for implementing text translations throughout the app to support multiple languages.

## Translation Utility

### 1. Create a `TranslationService` Class
```dart
// lib/services/translation_service.dart
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
```

### 2. Create a `TranslatableText` Widget
```dart
// lib/widgets/translatable_text.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TranslatableText extends StatelessWidget {
  final String translationKey;
  final Map<String, String>? params;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatableText(
    this.translationKey, {
    Key? key,
    this.params,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text = translationKey.tr;
    
    if (params != null) {
      params!.forEach((paramKey, paramValue) {
        text = text.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
```

## Implementation Guidelines

### Using TranslatableText Widget
Always use the `TranslatableText` widget for any text that might need translation:

```dart
// Instead of:
Text('Hello World')

// Use:
TranslatableText('hello_world')
```

### For Text with Parameters
```dart
TranslatableText(
  'welcome_user',
  params: {'name': userName},
)
```

### For Buttons and Other Components
```dart
ElevatedButton(
  onPressed: () {},
  child: TranslatableText('save_button'),
)
```

### For Hint Texts in TextFields
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'enter_name'.tr,
  ),
)
```

## Translation Keys Structure
Organize translation keys hierarchically based on features or screens:

- `common.`: For common UI elements (buttons, labels)
- `auth.`: For authentication-related text
- `product.`: For product-related text
- `settings.`: For settings screen
- `errors.`: For error messages

Examples:
- `common.save_button`: "Save"
- `auth.login_title`: "Login to Your Account"
- `product.quantity_label`: "Quantity"
- `errors.invalid_email`: "Please enter a valid email address"

## Translation Files

### English (Default)
```dart
// lib/translations/en_US.dart
final Map<String, String> enUS = {
  'common.save_button': 'Save',
  'common.cancel_button': 'Cancel',
  'common.next': 'Next',
  'common.back': 'Back',
  
  'auth.login_title': 'Login to Your Account',
  'auth.email_hint': 'Email Address',
  'auth.password_hint': 'Password',
  'auth.login_button': 'Log In',
  'auth.forgot_password': 'Forgot Password?',
  
  'welcome_user': 'Welcome, {name}!',
  
  // Add more translations as needed
};
```

### Tamil
```dart
// lib/translations/ta_IN.dart
final Map<String, String> taIN = {
  'common.save_button': 'சேமி',
  'common.cancel_button': 'ரத்து செய்',
  'common.next': 'அடுத்து',
  'common.back': 'பின்னால்',
  
  'auth.login_title': 'உங்கள் கணக்கில் உள்நுழைக',
  'auth.email_hint': 'மின்னஞ்சல் முகவரி',
  'auth.password_hint': 'கடவுச்சொல்',
  'auth.login_button': 'உள்நுழைக',
  'auth.forgot_password': 'கடவுச்சொல் மறந்துவிட்டதா?',
  
  'welcome_user': 'வரவேற்கிறோம், {name}!',
  
  // Add more translations as needed
};
```

### Register Translations
```dart
// lib/translations/app_translations.dart
import 'package:get/get.dart';
import 'en_US.dart';
import 'ta_IN.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'ta_IN': taIN,
  };
}
```

## Initializing Translations in main.dart
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'translations/app_translations.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My App',
      translations: AppTranslations(),
      locale: const Locale('en', 'US'), // Default locale
      fallbackLocale: const Locale('en', 'US'), // Fallback locale
      // ... other app config
    );
  }
}
```

## Finding Untranslated Text
To ensure all text is translated, follow these steps:

1. Use Flutter linting rules to require `.tr` on all string literals
2. Conduct regular code reviews focused on internationalization
3. Create a script to scan the codebase for `Text(` widgets with direct string literals
4. Test the app with different languages to identify missing translations

## Testing Translations
1. Switch languages in the app settings
2. Verify all text displays correctly in each supported language
3. Check for layout issues with longer text in different languages
4. Ensure dynamic text with parameters works correctly

## Best Practices
1. Never hardcode user-facing strings
2. Keep translation keys consistent and organized
3. Use descriptive key names that reflect the content
4. Add new translations immediately when adding new features
5. Regularly update translation files with new keys
6. Consider context when translating (different meanings in different languages)
7. Avoid concatenating strings - use parameters instead

## Language Selection
Implement a language selection screen:

```dart
// lib/screens/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/translation_service.dart';

class LanguageSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService();
    
    return Scaffold(
      appBar: AppBar(
        title: TranslatableText('settings.language_title'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('English'),
            trailing: translationService.getCurrentLocale().languageCode == 'en'
                ? const Icon(Icons.check)
                : null,
            onTap: () => translationService.changeLanguage('en', 'US'),
          ),
          ListTile(
            title: const Text('தமிழ்'),
            trailing: translationService.getCurrentLocale().languageCode == 'ta'
                ? const Icon(Icons.check)
                : null,
            onTap: () => translationService.changeLanguage('ta', 'IN'),
          ),
          // Add more languages as needed
        ],
      ),
    );
  }
}
```

By following this guide, you can ensure consistent translation implementation throughout the app, allowing for seamless multilingual support. 