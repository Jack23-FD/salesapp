# Typography Migration Guide

## Overview

This guide helps developers update text styles across the application to use the new typography system based on Visby and Urbanist fonts. The styles are defined in `lib/theme/typography.dart` and applied globally via `lib/theme/app_theme.dart`.

## How to Apply Typography Styles

Replace hardcoded TextStyle declarations with the appropriate style from `AppTypography`.

### Before:
```dart
Text(
  'Hello World',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
),
```

### After:
```dart
Text(
  'Hello World',
  style: AppTypography.menuDetails, // or the appropriate style
),
```

Remember to add the import at the top of your file:
```dart
import 'package:salesapp/theme/typography.dart';
```

## Mapping Guide

Reference this chart to find the appropriate AppTypography style for each use case:

| UI Element Type | Context | AppTypography Style |
|---------------|---------|------------------|
| **Headings** |
| Main section heading | Primary heading | `AppTypography.h1` |
| Screen heading | Every screen title | `AppTypography.h2` |
| **Tab Bar** |
| Default tab | Not selected tab | `AppTypography.tabBarDefault` |
| Active tab | Selected tab | `AppTypography.tabBarActive` |
| **Popup** |
| Popup paragraph | Sentence in popup | `AppTypography.popupParagraphSentence` |
| Popup header | Popup title | `AppTypography.popupHeader` |
| Button text | Text in buttons | `AppTypography.buttonText` |
| **Buttons** |
| Small button | Smaller CTAs | `AppTypography.smallButton` |
| Large button | Primary CTAs | `AppTypography.largeButton` |
| **Filters & Sorting** |
| Filter tap part | For changing filter | `AppTypography.filterTapPart` |
| Filter options | Text like "Active", "Low Stocks" | `AppTypography.filterOptionsText` |
| Sort by changer | Text like "Ascending", "Descending" | `AppTypography.sortByChanger` |
| Sort by info | Tap selection & below section | `AppTypography.sortByInfoSection` |
| Sort by options | For sort-by content | `AppTypography.sortByOptions` |
| **Item Section** |
| Item name | Item name text | `AppTypography.itemName` |
| Item code | Unique code for item | `AppTypography.itemCode` |
| Item units/price | Item units and price details | `AppTypography.itemUnitsAndPrice` |
| No items text | Empty state text | `AppTypography.noItems` |
| **Category Section** |
| Category active | Active category state | `AppTypography.categoryRedirectionActive` |
| Category non-active | Non-active category state | `AppTypography.categoryRedirectionNonActive` |
| Category name | Category names | `AppTypography.categoryName` |
| First screen text | Initial empty screen text | `AppTypography.firstScreen` |
| **Input Fields** |
| Input fields | Select Category, etc. | `AppTypography.inboundingInputFields` |
| Chunks | Predefined category | `AppTypography.inboundingChunks` |
| Subheadings | Quantity, Price, etc. | `AppTypography.inboundingSubheadings` |
| Caption text | Add Photos, Link QR Code | `AppTypography.inboundingOtherCaptionText` |
| **Menu Screen** |
| Menu details | User profile, company details | `AppTypography.menuDetails` |
| **Sign Up & Sign In** |
| Primary text | Main headings | `AppTypography.primaryText` |
| Input field text | Text in input fields | `AppTypography.inputFieldText` |
| Error states | Error messages | `AppTypography.errorStates` |
| Regular text | General body text | `AppTypography.regularText` |

## Using Theme Text Styles

For commonly used text styles, Material's built-in text theme can be used:

```dart
// Example using the theme-based approach
Text(
  'Hello World',
  style: Theme.of(context).textTheme.bodyLarge,
),
```

Key theme mappings:
- `Theme.of(context).textTheme.displayLarge` → Heading 1
- `Theme.of(context).textTheme.displayMedium` → Heading 2
- `Theme.of(context).textTheme.bodyLarge` → Regular text
- `Theme.of(context).textTheme.labelLarge` → Large button text

## Common Style Modifications

If you need to modify a style (e.g., change color while keeping other properties):

```dart
Text(
  'Error message',
  style: AppTypography.errorStates.copyWith(
    color: Colors.red,
  ),
),
```

## Testing Font Integration

To check if fonts are loading correctly:

1. Make sure fonts are added to the `fonts` directory as specified in `fonts/README.md`
2. Check pubspec.yaml has the correct font entries
3. Run `flutter clean && flutter pub get` 