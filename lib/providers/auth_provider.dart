import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../services/auth_service.dart' hide describeEnum;
import '../services/rbac_service.dart';
import '../utils/storage_utils.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
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
      bool isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        _firebaseUser = _authService.currentUser;
        if (_firebaseUser != null) {
          await _loadUserData();
        }
      }

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

  Future<void> retryInitialization() async {
    await _init();
  }

  // Load user data from the PHP API backend
  Future<void> _loadUserData() async {
    try {
      print("AuthProvider: Loading user profile from PHP API");
      final profileMap = await _apiService.getProfile();
      
      // Parse role from string
      final roleStr = profileMap['role'] ?? 'staff';
      final role = roleStr == 'admin' ? UserRole.admin : UserRole.staff;

      _user = User(
        id: profileMap['id'] ?? '',
        email: profileMap['email'] ?? '',
        name: profileMap['name'] ?? '',
        companyName: profileMap['companyName'] ?? profileMap['company_name'] ?? '',
        phoneNumber: profileMap['phoneNumber'] ?? profileMap['phone_number'] ?? '',
        role: role,
        createdAt: DateTime.tryParse(profileMap['createdAt'] ?? profileMap['created_at'] ?? '') ?? DateTime.now(),
        lastLogin: DateTime.now(),
        authProvider: 'email',
      );

      print("AuthProvider: User profile loaded successfully from PHP API");
      await StorageUtils.cacheStringValue('user_role', roleStr);
      await StorageUtils.migrateToUserSpecificData();
      
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Error loading user data from PHP API: $e");
      _error = e.toString();
      notifyListeners();
      
      // Fallback: Populate basic info from Firebase Auth if the API call fails
      if (_firebaseUser != null && _user == null) {
        final cachedRole = await StorageUtils.getCachedStringValue('user_role');
        final userRole = cachedRole == 'admin' ? UserRole.admin : UserRole.staff;
        
        _user = User(
          id: _firebaseUser!.uid,
          email: _firebaseUser!.email ?? '',
          name: _firebaseUser!.displayName ?? 'User',
          role: userRole,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          authProvider: 'email',
        );
        notifyListeners();
      }
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
      
      // 1. Sign up on Firebase Auth primarily
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        companyName: companyName,
        phoneNumber: phoneNumber,
        role: role,
      );

      // 2. Register user details on PHP backend
      if (companyName != null) {
        final roleStr = role == UserRole.admin ? 'admin' : 'staff';
        print("AuthProvider: Registering user on PHP API with role: $roleStr");
        await _apiService.registerUser(name, companyName, roleStr, phoneNumber);
      }

      await _loadUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Invite and add a staff member (Admin Only)
  Future<bool> addStaff(String uid, String name, String email, String? phoneNumber) async {
    try {
      await _apiService.registerStaff(uid, name, email, phoneNumber);
      return true;
    } catch (e) {
      print("AuthProvider: Error registering staff: $e");
      return false;
    }
  }

  // List staff members
  Future<List<User>> getStaffList() async {
    try {
      final list = await _apiService.listStaff();
      return list.map<User>((json) {
        final roleStr = json['role'] ?? 'staff';
        final role = roleStr == 'admin' ? UserRole.admin : UserRole.staff;
        return User(
          id: json['id'] ?? '',
          email: json['email'] ?? '',
          name: json['name'] ?? '',
          phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
          role: role,
          createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
          lastLogin: DateTime.now(),
          authProvider: 'email',
        );
      }).toList();
    } catch (e) {
      print("AuthProvider: Error getting staff list: $e");
      return [];
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("AuthProvider: Sign out operation timed out!");
        },
      );
      _user = null;
      _firebaseUser = null;
    } catch (e) {
      print("AuthProvider: Error during sign out: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
