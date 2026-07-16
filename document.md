# Salesapp-praskla - Documentation

## Project Overview

This is a Flutter-based sales application with cross-platform support. The app focuses on inventory management with features like inbounding and outbounding items, category management, and user authentication. The application follows a structured architecture with clear separation of concerns.

### Key Components:

1. **Authentication System**: Sign-in, sign-up with dedicated providers and services.
2. **Dashboard**: Overview of sales activities with custom calendar and date selection.
3. **Inventory Management**:
   - Categories management
   - Items tracking
   - Inbounding (receiving inventory)
   - Outbounding (shipping inventory)
4. **Notifications**: User notification system with dedicated screens and providers.
5. **Search Functionality**: Comprehensive search screen for finding items and categories.
6. **Theming**: Custom app theme with typography definitions.
7. **Utilities**: Storage and font loading utilities.

The app uses a provider pattern for state management with clear separation between UI components, business logic, and data models.

# Salesapp-praskla - Tech Stack & Tooling

## Core Framework

-**Flutter**: Cross-platform UI toolkit for building natively compiled applications

-**Dart**: Programming language used with Flutter

## Backend & Services

-**Firebase**

- Firebase Authentication: User authentication system
- Firestore: NoSQL cloud database
- Firebase Analytics (implied)

## State Management

-**Provider Pattern**: Main state management approach

- MultiProvider: For managing multiple providers
- Custom providers (AuthProvider, ItemProvider, CategoryProvider, etc.)

## UI Components & Design

-**Material Design**: Flutter's implementation of Material Design

-**Custom UI Components**:

- Custom Calendar
- Date Selector
- Navigation components
- Various cards (InboundCard, OutboundCard, CategoryCard)

-**GoogleFonts**: For font management and typography

## Storage

-**SharedPreferences**: Local storage for user preferences and cached data

-**Firebase Storage**: For cloud storage (implied)

## Authentication

-**Firebase Authentication**: Email/password authentication

-**Google Sign-In**: OAuth integration for Google authentication

## Device Features

-**Scanner Integration**: Barcode/QR code scanning functionality

## Animation

-**AnimationController**: For custom UI animations

-**CompositedTransform**: For overlay animations and transitions

## Development Tools

-**Dart Tools**: Development utilities for Dart

-**Flutter CLI**: Command-line tools for Flutter development

-**Android Studio/IntelliJ IDEA**: IDE support (implied by .idea directory)

-**Dart Analyzer**: Code analysis (configured in analysis_options.yaml)

## Version Control

-**Git**: For source code management

## Platform Support

-**Android**: Native Android support

-**iOS**: Native iOS support

-**Web**: Web platform support

-**Desktop**: macOS, Windows, and Linux support

## Testing

- Test framework for Flutter (test directory)

# Salesapp-praskla - Local Setup & Environment Configuration

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Dart SDK](https://dart.dev/get-dart) (installed with Flutter)
- [Git](https://git-scm.com/downloads)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- [Firebase CLI](https://firebase.google.com/docs/cli) (for Firebase setup)

## Clone the Repository

```bash
git clone https://github.com/yourorganization/Salesapp-praskla.git
cd Salesapp-praskla
```

## Install Dependencies

```bash
flutter pub get
```

## Firebase Setup

This application requires Firebase services. Follow these steps to configure Firebase:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download the configuration files:
   - For Android: `google-services.json` and place it in `android/app/`
   - For iOS: `GoogleService-Info.plist` and place it in `ios/Runner/`
4. Enable Authentication (Email/Password and Google Sign-in) in Firebase Console
5. Create Firestore database and set up initial security rules

## Run the Development Server

To run the app in development mode:

```bash
# For Android
flutter run -d android

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome

# For specific device
flutter devices          # List available devices
flutter run -d device_id # Run on specific device
```

## Build for Production

### Android

```bash
flutter build apk --release
# The APK will be available at build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
flutter build ios --release
# Open Xcode to archive and distribute the app
```

### Web

```bash
flutter build web --release
# Output will be in build/web
```

## Testing

Run unit and widget tests:

```bash
flutter test
```

Run integration tests:

```bash
flutter drive --target=test_driver/app.dart
```

## Troubleshooting

### Common Issues

1. **Firebase Configuration**: Ensure all Firebase configuration files are correctly placed
2. **Flutter Version**: Ensure you're using the compatible Flutter version
3. **Dependencies**: If you encounter dependency conflicts, try:
   ```
   flutter clean
   flutter pub get
   ```
4. **Platform-specific Issues**: For platform-specific issues, check the respective directories (android/, ios/) for configuration files

### Logs

- Check terminal output for Flutter and Dart errors
- For Firebase-related issues, check Firebase Console logs

## File & Folder Structure

```
Salesapp-praskla/
├── .dart_tool/                # Dart tools and configuration for Flutter
├── .git/                      # Git repository files
├── .idea/                     # IntelliJ IDEA/Android Studio configuration files
├── android/                   # Android platform-specific files
├── assets/                    # App assets
│   └── images/                # Images used in the application
├── build/                     # Compiled and build output
├── docs/                      # Documentation files
├── fonts/                     # Custom fonts for the application
├── ios/                       # iOS platform-specific files
├── lib/                       # Main application source code
│   ├── auth/                  # Authentication-related components
│   │   ├── auth_widgets.dart  # Reusable authentication widgets
│   │   ├── signin.dart        # Sign in screen
│   │   └── signup_screen.dart # Sign up screen
│   ├── components/            # Reusable UI components
│   │   ├── bottom_navigation.dart  # Bottom navigation bar
│   │   └── category_card.dart      # Category card component
│   ├── dashboard/             # Dashboard related components
│   │   ├── components/        # Dashboard specific components
│   │   │   ├── custom_calendar.dart  # Custom calendar component
│   │   │   ├── date_selector.dart    # Date selection component
│   │   │   ├── inbound_card.dart     # Inbound transaction card
│   │   │   └── outbound_card.dart    # Outbound transaction card
│   │   ├── dashboard_screen.dart  # Dashboard screen implementation
│   │   └── utils/             # Dashboard-specific utilities
│   ├── models/                # Data models
│   │   ├── category.dart      # Category data model
│   │   ├── item.dart          # Item data model
│   │   └── notification_item.dart  # Notification data model
│   ├── providers/             # State management providers
│   │   ├── auth_provider.dart         # Authentication state provider
│   │   ├── category_provider.dart     # Category data provider
│   │   ├── item_provider.dart         # Item data provider
│   │   └── notification_provider.dart # Notification data provider
│   ├── screens/               # Application screens
│   │   ├── auth_check_screen.dart    # Authentication check screen
│   │   ├── inbounding_screen.dart    # Inbounding management screen
│   │   ├── items_screen.dart         # Items listing screen
│   │   ├── menu_screen.dart          # Menu/settings screen
│   │   ├── notification_screen.dart  # Notifications screen
│   │   ├── outbounding/              # Outbounding components
│   │   ├── outbounding_screen.dart   # Outbounding management screen
│   │   └── scanner/                  # Scanner-related components
│   ├── services/              # Service layer
│   │   └── auth_service.dart  # Authentication service
│   ├── theme/                 # App theming
│   │   ├── app_theme.dart     # Theme configuration
│   │   └── typography.dart    # Typography styles
│   ├── utils/                 # Utilities
│   │   ├── font_loader.dart   # Font loading utility
│   │   └── storage_utils.dart # Storage utilities
│   ├── categories_screen.dart # Categories management screen
│   ├── dashboard_screen.dart  # Entry point for dashboard
│   ├── language_selection.dart # Language selection screen
│   ├── main.dart              # App entry point
│   ├── new_category_screen.dart # Category creation screen
│   ├── search_screen.dart     # Search functionality
│   └── walkthrough.dart       # App walkthrough/onboarding
├── linux/                     # Linux platform-specific files
├── macos/                     # macOS platform-specific files
├── test/                      # Test files
├── web/                       # Web platform-specific files
├── windows/                   # Windows platform-specific files
├── .flutter-plugins           # Flutter plugins configuration
├── .flutter-plugins-dependencies # Flutter plugins dependencies
├── .gitignore                 # Git ignore file
├── .metadata                  # Flutter metadata
├── analysis_options.yaml      # Dart analyzer options
├── pubspec.lock               # Package dependencies lock file
├── pubspec.yaml               # Package dependencies and app configuration
├── README.md                  # Project readme
└── salesapp.iml               # IntelliJ IDEA module file
```

# Salesapp-praskla - Application Execution Flow

## Entry Point of the App

The application starts at `lib/main.dart` with the `main()` function, which serves as the entry point for the Flutter application. This function:

1. Initializes Firebase services
2. Preloads custom fonts using `FontLoader.loadFonts()`
3. Sets up widget binding
4. Creates and launches the root `MyApp` widget

## Initialization Flow

1.**Firebase Initialization**: The app first initializes Firebase services including Authentication and Firestore.

2.**Font Loading**: Custom fonts are preloaded using `FontLoader` to improve application startup performance.

3.**App Widget Creation**: The `MyApp` class is instantiated, which:

- Sets up the app theme
- Configures provider state management
- Creates app-wide providers for state management

4.**Provider Setup**: In the `initState()` of `MyApp`, the application:

- Initializes state providers for items, categories, and authentication
- Registers an `AppLifecycleObserver` to monitor app lifecycle events

5.**Auth Check**: The app checks for existing authentication state through `AuthService.isLoggedIn()` to determine the initial screen.

6.**Data Preloading**: If the user is already authenticated, initial data is loaded from storage through provider calls.

## Component Rendering Hierarchy

The component rendering hierarchy follows this structure:

1.**MyApp** (Root widget)

- Sets up theme and providers
- Uses `MaterialApp` for foundation

2.**AuthCheckScreen** (Initial route)

- Checks authentication state
- Redirects to either authentication screens or main app screens

3.**MainNavigationController** (For authenticated users)

- Manages the main navigation including bottom navigation
- Contains a `PageView` with the main application screens:

  - Dashboard screen
  - Inventory screens (Items, Categories)
  - Inbounding/Outbounding screens
  - Menu/Settings screen

4.**Individual Screens**

- Each screen has its own component hierarchy
- Screens use providers to access shared application state

## Key Lifecycle Events

1.**AppLifecycleObserver**:

- Monitors application state changes through `didChangeAppLifecycleState()`
- When app is resumed from background, triggers data reloading

2.**MyApp Lifecycle**:

   -`initState()`: Initializes providers and lifecycle observer

   -`dispose()`: Cleans up resources and removes observers

3.**MainNavigationController Lifecycle**:

   -`initState()`: Sets up the navigation controller and loads initial data

   -`_loadData()`: Loads application data from local storage after first render

   -`dispose()`: Cleans up the page controller

4.**Screen-Level Lifecycle**:

- Each screen implements its own `initState()` and `dispose()`
- Dashboard uses `initState()` to schedule data loading through `_loadData()`

## Data Fetching / API Calls

1.**Authentication Data**:

   -`AuthService` manages Firebase Authentication calls

- User data is fetched from Firestore via `getUserData()`

2.**Inventory Data Loading**:

- Initial data is loaded in `MainNavigationController._loadData()`
- Categories and items are loaded from local storage and/or Firestore
- The `ItemProvider` and `CategoryProvider` handle data fetching and caching

3.**On-Demand Loading**:

- Individual screens may load additional data as needed
- Dashboard loads summary data for selected dates

4.**Data Synchronization**:

- When app resumes from background, `AppLifecycleObserver` triggers data refresh
- Changes made in the app are persisted to both local storage and Firestore

## Routing and Navigation

1.**Initial Routing**:

- Based on authentication state, app routes to either auth screens or main app

2.**Main Navigation**:

- The `MainNavigationController` uses a `PageView` for main screen navigation
- A custom `BottomNavigation` widget handles tab selection

3.**Tab Navigation**:

   -`_onTabChanged(int index)` handles navigation between main tabs

- PageController animates between tab views

4.**Screen Navigation**:

- Within screens, navigation to detail views uses Flutter's navigation system
- Push/pop operations for detail screens and forms

5.**Authentication Flow**:

- Sign in/up screens handle their own navigation flow
- On successful authentication, redirects to main application
- Sign out returns to authentication screens

# Salesapp-praskla - Detailed File-Level Documentation

This document provides a comprehensive overview of each file in the Salesapp-praskla project, detailing all functions, their parameters, return values, and dependencies.

## lib/main.dart

Main entry point for the Flutter application. This file initializes Firebase, sets up the app theme, and configures provider state management.

### AppLifecycleObserver Class

Monitors application lifecycle states to reload data when necessary.

🔹 `didChangeAppLifecycleState(AppLifecycleState state): void`

Handles app lifecycle state changes, particularly focusing on the 'resumed' state.

**Parameters:**

-`state: AppLifecycleState` - Current state of the app lifecycle (resumed, paused, inactive, detached)

**Return value:** None

**Usage:** Called automatically by Flutter when app state changes. When app is resumed, it triggers reloading data from storage.

**Dependencies:**`ItemProvider`, `CategoryProvider`

### main() Function

🔹 `main(): Future<void>`

Application entry point that initializes required services and launches the app.

**Parameters:** None

**Return value:** None

**Usage:** Automatically called when app starts. Sets up Firebase, preloads fonts, and launches the app widget tree.

**Dependencies:**`Firebase`, `FirebaseFirestore`, `GoogleFonts`, `WidgetsFlutterBinding`

### MyApp Class

Root application widget that sets up theme and providers.

🔹 `initState(): void`

Initializes state providers and registers the lifecycle observer.

**Parameters:** None

**Return value:** None

**Usage:** Called automatically when the MyApp widget is first created. Creates and initializes providers.

**Dependencies:**`ItemProvider`, `CategoryProvider`, `AppLifecycleObserver`

🔹 `dispose(): void`

Performs cleanup by removing the lifecycle observer.

**Parameters:** None

**Return value:** None

**Usage:** Called automatically when the MyApp widget is removed from the widget tree.

**Dependencies:**`WidgetsBinding`

🔹 `build(BuildContext context): Widget`

Constructs the widget tree for the application root.

**Parameters:**

-`context: BuildContext` - The build context

**Return value:**`Widget` - The MaterialApp widget

**Usage:** Renders the app UI and wraps it with necessary providers for state management.

**Dependencies:**`MaterialApp`, `MultiProvider`, various state providers

### MainNavigationController Class

Manages the main app navigation including the bottom navigation bar.

🔹 `initState(): void`

Sets up the navigation controller and loads initial data.

**Parameters:** None

**Return value:** None

**Usage:** Called when this widget first builds. Schedules data loading after the first frame renders.

**Dependencies:**`WidgetsBinding`

🔹 `_loadData(): Future<void>`

Loads application data from local storage.

**Parameters:** None

**Return value:** None

**Usage:** Called from initState to ensure data is available for display.

**Dependencies:**`ItemProvider`, `CategoryProvider`, `Provider`

🔹 `dispose(): void`

Cleans up the page controller when the widget is removed.

**Parameters:** None

**Return value:** None

**Usage:** Automatically called when this widget is removed from the tree.

**Dependencies:**`PageController`

🔹 `_onTabChanged(int index): void`

Handles tab change events in the bottom navigation.

**Parameters:**

-`index: int` - Selected tab index

**Return value:** None

**Usage:** Called when user taps on a different navigation tab.

**Dependencies:** None

🔹 `build(BuildContext context): Widget`

Builds the main navigation UI with PageView and BottomNavigation.

**Parameters:**

-`context: BuildContext` - Build context

**Return value:**`Widget` - Scaffold widget containing the main navigation

**Usage:** Renders the primary navigation interface of the app.

**Dependencies:**`Scaffold`, `PageView`, `BottomNavigation`

## lib/providers/auth_provider.dart

Provider for authentication state management, handling user authentication, registration, and error management.

### AuthProvider Class

🔹 `_init(): Future<void>`

Initializes the authentication provider, checking login status and setting up listeners.

**Parameters:** None

**Return value:** None

**Usage:** Called from constructor to set up authentication state.

**Dependencies:**`AuthService`, `FirebaseAuth` streams

🔹 `_loadUserData(): Future<void>`

Loads authenticated user data from Firestore.

**Parameters:** None

**Return value:** None

**Usage:** Called when authentication state changes, or when profile data needs to be refreshed.

**Dependencies:**`AuthService`, `FirebaseFirestore`

🔹 `signUp({required String email, required String password, required String name, String? companyName, String? phoneNumber}): Future<bool>`

Registers a new user with email and password authentication.

**Parameters:**

-`email: String` - User's email address

-`password: String` - User's password

-`name: String` - User's full name

-`companyName: String?` - Optional company name

-`phoneNumber: String?` - Optional phone number

**Return value:**`Future<bool>` - Success status of the registration

**Usage:** Called when user submits the sign-up form.

**Dependencies:**`AuthService`, `FirebaseAuth`

🔹 `signIn({required String email, required String password}): Future<bool>`

Signs in an existing user with email and password.

**Parameters:**

-`email: String` - User's email

-`password: String` - User's password

**Return value:**`Future<bool>` - Success status of the sign-in attempt

**Usage:** Called when user submits the sign-in form.

**Dependencies:**`AuthService`, `FirebaseAuth`

🔹 `signInWithGoogle(): Future<bool>`

Performs Google OAuth authentication.

**Parameters:** None

**Return value:**`Future<bool>` - Success status of the Google sign-in

**Usage:** Called when user clicks the "Sign in with Google" button.

**Dependencies:**`AuthService`, `GoogleSignIn`, `FirebaseAuth`

🔹 `signOut(): Future<void>`

Signs out the current user from the application.

**Parameters:** None

**Return value:** None

**Usage:** Called when user requests to log out.

**Dependencies:**`AuthService`

🔹 `resetPassword(String email): Future<bool>`

Initiates password reset flow for the provided email.

**Parameters:**

-`email: String` - User's email address

**Return value:**`Future<bool>` - Success status of the password reset request

**Usage:** Called when user submits the password reset form.

**Dependencies:**`AuthService`, `FirebaseAuth`

🔹 `_handleAuthError(dynamic error): String`

Translates Firebase authentication errors into user-friendly messages.

**Parameters:**

-`error: dynamic` - The error object from Firebase

**Return value:**`String` - User-friendly error message

**Usage:** Called internally to process authentication errors.

**Dependencies:**`FirebaseAuthException`

## lib/services/auth_service.dart

Service layer that handles direct interactions with Firebase Authentication and Firestore for user management.

### AuthService Class

🔹 `signUp({required String email, required String password, required String name, String? companyName, String? phoneNumber}): Future<UserCredential>`

Creates a new user account in Firebase Auth and stores additional user data in Firestore.

**Parameters:**

-`email: String` - User's email

-`password: String` - User's password

-`name: String` - User's name

-`companyName: String?` - Optional company name

-`phoneNumber: String?` - Optional phone number

**Return value:**`Future<UserCredential>` - Firebase Authentication user credential

**Usage:** Called by AuthProvider to register a new user.

**Dependencies:**`FirebaseAuth`, `FirebaseFirestore`, `SharedPreferences`

🔹 `signIn({required String email, required String password}): Future<UserCredential>`

Authenticates a user with Firebase using email and password, updates last login timestamp.

**Parameters:**

-`email: String` - User's email

-`password: String` - User's password

**Return value:**`Future<UserCredential>` - Firebase Authentication user credential

**Usage:** Called by AuthProvider to authenticate a user.

**Dependencies:**`FirebaseAuth`, `FirebaseFirestore`, `SharedPreferences`

🔹 `signInWithGoogle(): Future<UserCredential>`

Performs OAuth authentication flow with Google and Firebase.

**Parameters:** None

**Return value:**`Future<UserCredential>` - Firebase Authentication user credential

**Usage:** Called by AuthProvider for Google sign-in.

**Dependencies:**`FirebaseAuth`, `GoogleSignIn`, `FirebaseFirestore`, `SharedPreferences`

🔹 `signOut(): Future<void>`

Signs out the user from both Firebase and Google (if applicable).

**Parameters:** None

**Return value:** None

**Usage:** Called by AuthProvider when user logs out.

**Dependencies:**`FirebaseAuth`, `GoogleSignIn`, `SharedPreferences`

🔹 `resetPassword(String email): Future<void>`

Sends a password reset email through Firebase Auth.

**Parameters:**

-`email: String` - User's email address

**Return value:** None

**Usage:** Called by AuthProvider when user requests password reset.

**Dependencies:**`FirebaseAuth`

🔹 `getUserData(): Future<Map<String, dynamic>?>`

Fetches the current user's profile data from Firestore.

**Parameters:** None

**Return value:**`Future<Map<String, dynamic>?>` - User data as a map or null if no user

**Usage:** Called to retrieve user profile information.

**Dependencies:**`FirebaseFirestore`, `FirebaseAuth`

🔹 `_saveLoginState(bool isLoggedIn): Future<void>`

Persists user login state to device storage.

**Parameters:**

-`isLoggedIn: bool` - Whether the user is currently logged in

**Return value:** None

**Usage:** Called internally after login/logout operations.

**Dependencies:**`SharedPreferences`

🔹 `isLoggedIn(): Future<bool>`

Retrieves the stored login state from device storage.

**Parameters:** None

**Return value:**`Future<bool>` - Whether user is logged in

**Usage:** Called during app initialization to check login status.

**Dependencies:**`SharedPreferences`

## lib/utils/font_loader.dart

Utility for pre-loading custom fonts to improve application startup performance.

### FontLoader Class

🔹 `loadFonts(): Future<void>`

Pre-loads and caches all custom fonts used in the application.

**Parameters:** None

**Return value:** None

**Usage:** Called during app initialization to ensure fonts are available.

**Dependencies:**`rootBundle` from `flutter/services.dart`

## lib/models/category.dart

Data model class representing a product category in the inventory system.

### Category Class

🔹 `toMap(): Map<String, dynamic>`

Serializes a Category object to a map for storage.

**Parameters:** None

**Return value:**`Map<String, dynamic>` - Category data as a map

**Usage:** Called when saving category data to storage or sending to API.

**Dependencies:** None

🔹 `Category.fromMap(Map<String, dynamic> map): Category`

Factory constructor that creates a Category object from a data map.

**Parameters:**

-`map: Map<String, dynamic>` - Map containing category data

**Return value:**`Category` - New Category instance

**Usage:** Called when retrieving category data from storage or API.

**Dependencies:** None

🔹 `_getIconFromCodePoint(int codePoint): IconData?`

Static helper method that maps icon code points to Flutter IconData.

**Parameters:**

-`codePoint: int` - The icon code point

**Return value:**`IconData?` - Corresponding IconData or null

**Usage:** Called internally by fromMap to resolve icon data.

**Dependencies:**`Icons` from Flutter material package

## lib/dashboard/dashboard_screen.dart

Main dashboard screen displaying inventory statistics and summaries.

### DashboardScreen Class

🔹 `initState(): void`

Initializes the dashboard screen and schedules data loading.

**Parameters:** None

**Return value:** None

**Usage:** Called when dashboard screen is first created.

**Dependencies:**`WidgetsBinding`

🔹 `_loadData(): Future<void>`

Loads inventory data from storage for display in dashboard.

**Parameters:** None

**Return value:** None

**Usage:** Called by initState to load initial data.

**Dependencies:**`ItemProvider`, `Provider`

🔹 `_onDateSelected(DateTime? date): void`

Updates the dashboard to show data for the selected date.

**Parameters:**

-`date: DateTime?` - Selected date for inventory summary

**Return value:** None

**Usage:** Called when user selects a different date.

**Dependencies:** None

🔹 `build(BuildContext context): Widget`

Constructs the dashboard UI with summary cards and statistics.

**Parameters:**

-`context: BuildContext` - Build context

**Return value:**`Widget` - Scaffold widget containing the dashboard

**Usage:** Renders the dashboard user interface.

**Dependencies:**`Scaffold`, `DateSelector`, `InboundCard`, `OutboundCard`, `ItemProvider`

## lib/dashboard/components/date_selector.dart

Custom calendar component for selecting dates in the dashboard.

### DateSelector Class

🔹 `initState(): void`

Sets up animation controller for the date selector transitions.

**Parameters:** None

**Return value:** None

**Usage:** Called when date selector is created.

**Dependencies:**`AnimationController`

🔹 `dispose(): void`

Cleans up resources used by the date selector.

**Parameters:** None

**Return value:** None

**Usage:** Called when date selector is removed from widget tree.

**Dependencies:**`AnimationController`

🔹 `_toggleCalendar(): void`

Shows or hides the calendar popup overlay.

**Parameters:** None

**Return value:** None

**Usage:** Called when user taps the date selector.

**Dependencies:**`AnimationController`

🔹 `_removeOverlay(): void`

Removes the calendar popup overlay from the screen.

**Parameters:** None

**Return value:** None

**Usage:** Called when calendar should be dismissed.

**Dependencies:**`OverlayEntry`

🔹 `_showOverlay(): void`

Displays the calendar popup overlay with animation.

**Parameters:** None

**Return value:** None

**Usage:** Called when calendar should be shown.

**Dependencies:**`GestureBinding`, `Overlay`

🔹 `_isInsideOverlay(Offset position): bool`

Determines if a tap position is inside the calendar overlay boundaries.

**Parameters:**

-`position: Offset` - Screen position of the tap

**Return value:**`bool` - Whether the position is inside the overlay

**Usage:** Used to handle taps outside the calendar for dismissal.

**Dependencies:** None

🔹 `_handlePointerEvent(PointerEvent event): void`

Processes pointer events for tap detection and overlay dismissal.

**Parameters:**

-`event: PointerEvent` - Pointer event from the system

**Return value:** None

**Usage:** Called for each pointer event when overlay is showing.

**Dependencies:** None

🔹 `_createOverlayEntry(): OverlayEntry`

Creates the calendar overlay UI entry with animations.

**Parameters:** None

**Return value:**`OverlayEntry` - The overlay entry containing the calendar

**Usage:** Called when showing the calendar overlay.

**Dependencies:**`CustomCalendar`, `Material`, `CompositedTransformFollower`

🔹 `build(BuildContext context): Widget`

Builds the date selector button UI.

**Parameters:**

-`context: BuildContext` - Build context

**Return value:**`Widget` - CompositedTransformTarget widget containing the date selector

**Usage:** Renders the date selector button in the dashboard.

**Dependencies:**`Card`, `InkWell`, `DateFormatter`, `CompositedTransformTarget`
