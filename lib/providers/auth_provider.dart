import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart' hide describeEnum;
import '../services/rbac_service.dart';
import '../utils/storage_utils.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  firebase_auth.User? _firebaseUser;
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isFirebaseInitialized = true;

  // Getters
  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  bool get isAdmin => _user?.isAdmin ?? false;
  
  // For backward compatibility
  Map<String, dynamic>? get userData {
    if (_user == null) return null;
    return {
      'name': _user!.name,
      'email': _user!.email,
      'companyName': _user!.companyName,
      'phoneNumber': _user!.phoneNumber,
      'role': _user!.role.toString().split('.').last,
    };
  }

  // Constructor
  AuthProvider() {
    _init();
  }

  // Initialize the provider
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if user is logged in from shared preferences
      bool isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Get current user
        _firebaseUser = _authService.currentUser;

        if (_firebaseUser != null) {
          // Get user data
          await _loadUserData();
        }
      }

      // Listen for auth state changes
      _authService.authStateChanges.listen((firebase_auth.User? user) {
        _firebaseUser = user;
        notifyListeners();

        if (user != null) {
          _loadUserData();
        } else {
          _user = null;
        }
      });
    } catch (e) {
      print("Error initializing AuthProvider: $e");
      _isFirebaseInitialized = false;
      _error = "Firebase initialization failed. Please try again later.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    try {
      print("AuthProvider: Loading user data from Firebase");
      _user = await _authService.getUserModel();
      
      if (_user == null) {
        print("AuthProvider: User data couldn't be retrieved from Firestore");
        // Try to create a basic user if Firestore data isn't available
        if (_firebaseUser != null) {
          print("AuthProvider: Creating basic user from Firebase user");
          
          // Check if we have a cached role from previous session
          final cachedRole = await StorageUtils.getCachedStringValue('user_role');
          final userRole = cachedRole == 'admin' 
              ? UserRole.admin 
              : UserRole.staff;
          
          print("AuthProvider: Using role from cache: $cachedRole (enum: $userRole)");
          
          _user = User(
            id: _firebaseUser!.uid,
            email: _firebaseUser!.email ?? '',
            name: _firebaseUser!.displayName ?? 'User',
            role: userRole,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            authProvider: 'email',
          );
          
          // Try to save user data to Firestore as a recovery mechanism
          try {
            print("AuthProvider: Attempting to recover by saving user data to Firestore");
            await _authService.updateUserData(_user!);
            print("AuthProvider: Recovery save successful");
          } catch (e) {
            print("AuthProvider: Failed to save recovery data: $e");
          }
        }
      } else {
        print("AuthProvider: User data loaded successfully");
        print("AuthProvider: User role: ${_user!.role}");
        print("AuthProvider: User is admin? ${_user!.isAdmin}");
        
        // Cache the role for future use
        await StorageUtils.cacheStringValue('user_role', describeEnum(_user!.role));
      }
      
      // Migrate any existing data to user-specific storage
      await StorageUtils.migrateToUserSpecificData();
      
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Error loading user data: $e");
      _error = e.toString();
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? companyName,
    String? phoneNumber,
    UserRole role = UserRole.staff,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print("AuthProvider: Starting sign up with role: $role");
      print("AuthProvider: Role as string: ${describeEnum(role)}");
      print("AuthProvider: Is admin? ${role == UserRole.admin}");
      
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        companyName: companyName,
        phoneNumber: phoneNumber,
        role: role,
      );

      await _loadUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );

      await _loadUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle({UserRole role = UserRole.staff}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle(role: role);
      await _loadUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add timeout to prevent hanging
      await _authService.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("AuthProvider: Sign out operation timed out!");
          // Force local sign-out even if Firebase times out
          _firebaseUser = null;
          _user = null;
          throw Exception("Sign out timed out. Please try again.");
        },
      );
      
      // Clear user data
      _firebaseUser = null;
      _user = null;
      
      // Clear any cached auth data
      await StorageUtils.clearAuthCache();
      
      print("AuthProvider: Sign out completed successfully");
    } catch (e) {
      print("AuthProvider: Error during sign out: $e");
      _error = "Sign out failed: ${e.toString()}";
      
      // Force sign out locally even if there was an error with Firebase
      _firebaseUser = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, UserRole role) async {
    try {
      final success = await _authService.updateUserRole(userId, role);
      
      if (success && _user != null && _user!.id == userId) {
        _user = _user!.copyWith(role: role);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    if (_user == null) return false;
    
    final rbacService = RbacService();
    return rbacService.hasPermission(_user!, permission);
  }

  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The email address is already in use.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'google-sign-in-cancelled':
          return 'Google sign in was cancelled.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return error.toString();
  }

  // Reset and retry initialization
  Future<void> retryInitialization() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print("AuthProvider: Retrying initialization");
      await _init();
    } catch (e) {
      print("Error during retry initialization: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
