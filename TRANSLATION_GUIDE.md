# Translation Guide for SalesApp

This guide explains how to add new languages to the SalesApp.

## Supported Languages

The app currently supports the following languages:
- English (en_US)
- Tamil (ta_IN)
- German (de_DE)

## How to Add a New Language

### 1. Create a New Translation File

1. Create a new JSON file in the `assets/lang/` directory with the language code as the filename.
   For example: `fr.json` for French.

2. Copy the contents of `en.json` to use as a template for the new language file.

3. Translate all the strings in the JSON file to the new language.

### 2. Update the Localization Service

1. Open `lib/services/localization_service.dart`

2. Add the new locale to the `supportedLocales` list:
   ```dart
   static final List<Locale> supportedLocales = [
     const Locale('en', 'US'),
     const Locale('ta', 'IN'),
     const Locale('de', 'DE'),
     const Locale('fr', 'FR'), // New language (example: French)
   ];
   ```

### 3. Update the Language Selection Screen

1. Open `lib/language_selection.dart`

2. Add the new language to the `_languages` list in the `_LanguageSelectionScreenState` class:
   ```dart
   final List<Map<String, dynamic>> _languages = [
     {'name': 'English', 'locale': const Locale('en', 'US')},
     {'name': 'Tamil', 'locale': const Locale('ta', 'IN')},
     {'name': 'German', 'locale': const Locale('de', 'DE')},
     {'name': 'French', 'locale': const Locale('fr', 'FR')}, // New language
   ];
   ```

### 4. Test the New Language

1. Build and run the app.
2. Navigate to the language selection screen.
3. Select the new language.
4. Verify that all UI elements display correctly in the new language.

## Translation Tips

- Keep translations concise and clear.
- Maintain consistent terminology throughout the app.
- Pay attention to pluralization rules for the target language.
- Consider cultural nuances when translating.
- Test the UI with the new language to ensure text fits properly in all UI elements.

## Translation Structure

The translation files follow a nested JSON structure organized by functionality:

```json
{
  "auth": {
    "signIn": "Sign In",
    ...
  },
  "navigation": {
    "dashboard": "Dashboard",
    ...
  }
}
```

Use the same structure and keys when creating new translation files to ensure compatibility. 