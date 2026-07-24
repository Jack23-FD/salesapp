import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../walkthrough.dart';
import '../navigation/role_based_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if onboarding has been completed
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding = prefs.getBool('onboardingComplete') ?? false;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Show loading indicator while checking auth state
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If Firebase is not initialized, still allow using the app
    // by redirecting to the onboarding flow
    if (!authProvider.isFirebaseInitialized) {
      print('Firebase not initialized, proceeding to onboarding');
      return _hasCompletedOnboarding
          ? const Scaffold(
              body: Center(
                child: Text(
                    'Firebase is not initialized. Please restart the app.'),
              ),
            )
          : const OnboardingScreen();
    }

    // If user is authenticated, check role and redirect accordingly
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      print('User is authenticated, checking role for proper navigation');
      
      if (user != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          RoleBasedNavigation.navigateToHomeScreen(context, user);
        });
      } else {
        // User is authenticated but user object not loaded yet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        });
      }
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user completed onboarding but not logged in, go to sign in
    if (_hasCompletedOnboarding) {
      print('Onboarding complete, redirecting to sign in');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/signin');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Otherwise go to onboarding
    print('New user, starting onboarding flow');
    return const OnboardingScreen();
  }
}
