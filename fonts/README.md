# Font Installation Guide

## Required Fonts

According to the typography guide, this application requires two font families:

1. **Visby**
   - Required weights: Regular (400), Medium (500), Semibold (600), Bold (700)
   - File structure needed:
     - `fonts/Visby/Visby-Regular.ttf`
     - `fonts/Visby/Visby-Medium.ttf`
     - `fonts/Visby/Visby-Semibold.ttf`
     - `fonts/Visby/Visby-Bold.ttf`

2. **Urbanist**
   - Required weights: Regular (400), Medium (500), Semibold (600), Bold (700)
   - File structure needed:
     - `fonts/Urbanist/Urbanist-Regular.ttf`
     - `fonts/Urbanist/Urbanist-Medium.ttf`
     - `fonts/Urbanist/Urbanist-Semibold.ttf`
     - `fonts/Urbanist/Urbanist-Bold.ttf`

## How to Install the Fonts

### Urbanist (Free Font)
1. Download the Urbanist font from Google Fonts: [Urbanist on Google Fonts](https://fonts.google.com/specimen/Urbanist)
2. Extract the files and place them in the `fonts/Urbanist/` directory with the names mentioned above.

### Visby (Commercial Font)
1. Visby CF is a commercial font by Connary Fagen. You'll need to purchase this font from:
   - [Connary Fagen Website](https://connary.com/visby.html) or
   - [MyFonts](https://www.myfonts.com/fonts/connary-fagen/visby-cf/)
2. Once purchased, place the font files in the `fonts/Visby/` directory with the names mentioned above.

## Alternative for Visby
If you don't have access to the Visby font, you could temporarily use one of these similar alternatives:
- For development: Work Sans, Outfit, or Satoshi
- Update the font family in `lib/theme/typography.dart` accordingly

## After Adding the Fonts
Once you've added the font files:
1. Run: `flutter pub get`
2. Clean and rebuild the app:
   ```
   flutter clean
   flutter pub get
   flutter run
   ``` 