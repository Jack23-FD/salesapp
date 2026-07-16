# Sales App Walkthrough

A cross-platform mobile app built with Flutter that features an attractive onboarding/walkthrough experience.

## Features

- Interactive walkthrough screens
- Horizontal swipe navigation
- "Skip" functionality to jump to the last page
- "Get Started" button on the final screen
- Animated page indicators
- Support for both Android and iOS

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / Xcode for emulators and deployment
- Visby and Urbanist fonts (see [Font Installation Guide](fonts/README.md))

### Installation

1. Clone the repository
```bash
git clone <repository-url>
```

2. Navigate to the project directory
```bash
cd salesapp
```

3. Install the required fonts
See the [Font Installation Guide](fonts/README.md) for instructions on obtaining and installing the Visby and Urbanist fonts.

4. Install dependencies
```bash
flutter pub get
```

5. Run the app
```bash
flutter run
```

## Customization

### Adding Custom Images

Place your image assets in the `assets/images/` directory and update the references in the code as needed.

### Modifying Text Content

Modify the walkthrough text content by updating the `_walkthroughItems` list in the `_OnboardingScreenState` class.

### Typography System

The app uses a comprehensive typography system based on Visby and Urbanist fonts. The typography styles are defined in:

- `lib/theme/typography.dart` - Contains all text style definitions
- `lib/theme/app_theme.dart` - Applies the typography to the Material theme

For developers updating text styles in the app, refer to the [Typography Migration Guide](docs/typography_migration_guide.md).

### Styling

The app uses a purple/blue color scheme by default, but this can be easily modified by updating the color values in the relevant style properties.

## License

This project is licensed under the MIT License.
