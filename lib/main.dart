import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard/dashboard_screen.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/category_provider.dart';
import 'providers/notification_provider.dart';
import 'auth/signin.dart';
import 'auth/signup_screen.dart';
import 'walkthrough.dart';
import 'language_selection.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/staff_management.dart';
import 'screens/admin/statistics_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/auth_check_screen.dart';
import 'screens/add_stock_screen.dart';
import 'screens/use_stock_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'utils/font_loader.dart' as app_fonts;
import 'theme/typography.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/bottom_navigation.dart';
import 'navigation/role_based_navigation.dart';
import 'services/mysql_database_service.dart';
import 'utils/storage_utils.dart';
import 'utils/navigation_debug.dart';
import 'services/localization_service.dart';
import 'screens/profile_screen.dart';
import 'utils/translation_checker.dart';
import 'utils/translation_utils.dart';

// Add a lifecycle observer to handle app state changes
class AppLifecycleObserver extends WidgetsBindingObserver {
  final ItemProvider itemProvider;
  final CategoryProvider categoryProvider;

  AppLifecycleObserver(this.itemProvider, this.categoryProvider);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, reload data from local storage
      print('App resumed, reloading data from local storage');
      itemProvider.loadFromLocalStorage();
      categoryProvider.reloadFromLocalStorage();
    }
  }
}

// Add a NavigatorObserver to debug navigation
class DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationDebug.logPush(route.settings.name ?? 'unnamed route');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationDebug.logPop(route.settings.name ?? 'unnamed route');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationDebug.log('Removed route', route.settings.name ?? 'unnamed route');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    NavigationDebug.logReplace(
      oldRoute?.settings.name ?? 'unnamed route', 
      newRoute?.settings.name ?? 'unnamed route'
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic>? previousRoute) {
    NavigationDebug.log('Started gesture on route', route.settings.name ?? 'unnamed route');
    super.didStartUserGesture(route, previousRoute);
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable navigation debug logs in development
  NavigationDebug.enableDebugLogs = false;
  
  // Preload the Urbanist font asynchronously
  GoogleFonts.config.allowRuntimeFetching = true;

  // Startup MySQL initialization disabled in favor of Cloud Firestore
  print('MySQL startup initialization disabled (migrated to Cloud Firestore)');

  // Continue with the rest of initialization
  bool firebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDyB8egZY0hRJ5I3A7g1YV1gHCztDc25nk",
        appId: "1:509978989502:android:437b547417e33e10319fef",
        messagingSenderId: "509978989502",
        projectId: "salesapp-c530f",
        storageBucket: "salesapp-c530f.firebasestorage.app",
      ),
    );

    // Configure Firestore settings
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    print("Firebase initialized successfully");
    firebaseInitialized = true;
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // Continue without Firebase
  }

  // Initialize localization
  await LocalizationService.init();
  // After initialization, clear any stale cache
  TranslationCache.clear();
  print("Main: Localization service initialized, cache cleared");

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatefulWidget {
  final bool firebaseInitialized;

  const MyApp({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ItemProvider _itemProvider;
  late CategoryProvider _categoryProvider;
  late AppLifecycleObserver _lifecycleObserver;
  final DebugNavigatorObserver _debugNavigatorObserver = DebugNavigatorObserver();

  @override
  void initState() {
    super.initState();

    // Initialize providers first
    _itemProvider = ItemProvider();
    _categoryProvider = CategoryProvider();

    // Setup translation debugging in development mode
    _setupTranslationDebugging();

    // Delay creating the observer until the next frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lifecycleObserver =
          AppLifecycleObserver(_itemProvider, _categoryProvider);
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer when app is disposed
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<Widget> _getStartScreen(BuildContext context, AuthProvider authProvider) async {
    print("Main: Determining start screen. Auth initialized: ${authProvider.isFirebaseInitialized}, User authenticated: ${authProvider.isAuthenticated}");
    
    if (!authProvider.isFirebaseInitialized) {
      return ErrorScreen(
        title: "Initialization Error",
        message: "Could not connect to Firebase. Please check your internet connection and try again.",
        retryAction: () => _retryInitialization(context),
      );
    }

    // Check if user has completed onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboardingComplete') ?? false;
    
    // If user hasn't completed onboarding, show walkthrough screen
    if (!hasCompletedOnboarding) {
      print("Main: User has not completed onboarding, showing walkthrough");
      return const OnboardingScreen();
    }

    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      print("Main: User authenticated, user object: ${user?.toString()}");
      
      if (user == null) {
        print("Main: User is authenticated but user object is null");
        return const SignInScreen();
      }
      
      // This will handle navigation based on user role
      print("Main: Navigating based on role: ${user.role}, isAdmin: ${user.isAdmin}");
      return RoleBasedNavigation.getHomeScreen(user);
    } else {
      // User is not authenticated but has completed onboarding, show sign in screen
      print("Main: User not authenticated but has completed onboarding, showing sign in");
      return const SignInScreen();
    }
  }
  
  void _retryInitialization(BuildContext context) {
    // Reset providers
    Provider.of<AuthProvider>(context, listen: false).retryInitialization();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with LocalizationProvider
    return ChangeNotifierProvider(
      create: (context) => LocalizationProvider(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _itemProvider),
          ChangeNotifierProvider.value(value: _categoryProvider),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: Consumer2<AuthProvider, LocalizationProvider>(
          builder: (context, authProvider, localizationProvider, _) {
            return MaterialApp(
              navigatorKey: ItemProvider.navigatorKey,
              navigatorObservers: [_debugNavigatorObserver],
              title: 'Sales App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              // Add localization settings
              locale: localizationProvider.locale,
              supportedLocales: LocalizationService.supportedLocales,
              localizationsDelegates: [
                // Add Flutter's built-in localization delegates
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Add locale resolution callback to ensure we fall back to supported locales
              localeResolutionCallback: (locale, supportedLocales) {
                // If the locale from the device is not supported, use the first one
                // from the list (English in this case).
                if (locale != null) {
                  for (final supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale.languageCode) {
                      return supportedLocale;
                    }
                  }
                }
                return supportedLocales.first;
              },
              home: const AuthCheckScreen(),
              routes: {
                '/signin': (context) => const SignInScreen(),
                '/signup': (context) => SignUpScreen(selectedLanguage: 'en'),
                '/dashboard': (context) => const MainNavigationController(),
                '/main_navigation': (context) => const MainNavigationController(),
                '/admin_dashboard': (context) => const AdminDashboard(),
                '/search': (context) => const SearchScreen(),
                '/categories': (context) => const CategoriesScreen(),
                '/language': (context) => const LanguageSelectionScreen(),
                '/walkthrough': (context) => const OnboardingScreen(),
                '/admin/staff_management': (context) => const StaffManagementScreen(),
                '/admin/statistics': (context) => const StatisticsScreen(),
                '/profile': (context) => const ProfileScreen(),
                ...RoleBasedNavigation.generateRoutes(),
              },
            );
          },
        ),
      ),
    );
  }

  void _setupTranslationDebugging() {
    // Enable translation debugging in development mode
    assert(() {
      TranslationChecker.enableDebugMode();
      // Print summary when app is disposed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addObserver(
          _TranslationDebugObserver(),
        );
      });
      return true;
    }());
  }
}

class _TranslationDebugObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      TranslationChecker.printSummary();
    }
  }
}

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback retryAction;

  const ErrorScreen({
    super.key, 
    required this.title, 
    required this.message,
    required this.retryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 70,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: retryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BBF9),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  final String message;
  
  const LoadingScreen({super.key, required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() =>
      _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _dataLoaded = false;
  String _currentLanguage = '';

  @override
  void initState() {
    super.initState();
    // Register observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Store current language
    _currentLanguage = LocalizationService.currentLocale.languageCode;
    print("MainNavigationController: initialized with language $_currentLanguage");
    
    // Load data only once when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dataLoaded) {
        _loadData();
        _checkUserRole();
        _dataLoaded = true;
      }
    });
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only reload data when app comes to the foreground after being paused
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed from background - refreshing data if needed');
      // We could add specific refresh logic here if needed
      
      // Check for language changes on resume
      final currentLocale = LocalizationService.currentLocale;
      if (_currentLanguage != currentLocale.languageCode) {
        print("MainNavigationController: Language changed while app was in background");
        setState(() {
          _currentLanguage = currentLocale.languageCode;
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      debugPrint(
          'MainNavigationController: Loading data from local storage');
      await itemProvider.reloadFromLocalStorage();
      await categoryProvider.reloadFromLocalStorage();
    } catch (e) {
      debugPrint('Error loading data in main navigation: $e');
    }
  }

  Future<void> _checkUserRole() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get cached role first if available
      final cachedRole = await StorageUtils.getCachedStringValue('user_role');
      
      if (cachedRole != null) {
        debugPrint('MainNavigationController: Using cached role: $cachedRole');
        // Only redirect if cached role is admin
        if (cachedRole == 'admin') {
          debugPrint('MainNavigationController: User is admin from cache, redirecting to admin dashboard');
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
          return;
        }
      }
      
      // If no cache or not admin in cache, check live data
      if (authProvider.user?.isAdmin == true) {
        // Cache the role for future use
        await StorageUtils.cacheStringValue('user_role', 'admin');
        // Redirect to admin dashboard if user is an admin
        debugPrint('MainNavigationController: User is admin, redirecting to admin dashboard');
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (authProvider.user != null) {
        // Cache the non-admin role too
        await StorageUtils.cacheStringValue('user_role', 'staff');
        debugPrint('MainNavigationController: User is not admin, staying on regular dashboard');
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(isInMainNavigation: true),
    const SizedBox(), // Placeholder for Stock tab
    const SearchScreen(isInMainNavigation: true),
    const CategoriesScreen(),
    const MenuScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to LocalizationProvider changes to rebuild when language changes
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final currentLocale = localizationProvider.locale;
    
    // Update stored language if changed
    if (_currentLanguage != currentLocale.languageCode) {
      print("MainNavigationController: Language changed in build from $_currentLanguage to ${currentLocale.languageCode}");
      _currentLanguage = currentLocale.languageCode;
    }
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
        pageController: _pageController,
      ),
    );
  }
}
