import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_models;

class AuthService {
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await _googleSignIn.initialize();
      _googleSignInInitialized = true;
    }
  }

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<firebase_auth.UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    String? companyName,
    String? phoneNumber,
    app_models.UserRole role = app_models.UserRole.staff,
  }) async {
    try {
      print("AuthService: Starting sign up process for $email with role: ${describeEnum(role)}");
      print("AuthService: Role enum value: $role");
      print("AuthService: Is admin role? ${role == app_models.UserRole.admin}");
      print("AuthService: Admin value check: ${app_models.UserRole.admin}");
      print("AuthService: Staff value check: ${app_models.UserRole.staff}");
      
      // Create user with email and password
      firebase_auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("AuthService: User created in Firebase Auth with UID: ${userCredential.user?.uid}");

      // Save additional user data to Firestore with retries
      if (userCredential.user != null) {
        await _saveUserToFirestore(
          userCredential.user!.uid,
          name,
          email,
          companyName,
          phoneNumber,
          role,
        );

        // Update display name
        try {
          await userCredential.user!.updateDisplayName(name);
          print("AuthService: Display name updated in Firebase Auth");
        } catch (e) {
          print("Error updating display name: $e");
          // Continue even if updating display name fails
        }

        // Save login state to shared preferences
        await _saveLoginState(true);
      }

      return userCredential;
    } catch (e) {
      print("Error in signUp: $e");
      rethrow;
    }
  }

  // Helper method to save user to Firestore with retry mechanism
  Future<bool> _saveUserToFirestore(
    String uid,
    String name,
    String email,
    String? companyName,
    String? phoneNumber,
    app_models.UserRole role,
  ) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        print("AuthService: Attempt ${attempts + 1} - Saving user data to Firestore with role: ${describeEnum(role)}");
        print("AuthService: Role enum value in _saveUserToFirestore: $role");
        print("AuthService: Is admin in _saveUserToFirestore? ${role == app_models.UserRole.admin}");
        
        final userData = {
          'name': name,
          'email': email,
          'companyName': companyName ?? '',
          'phoneNumber': phoneNumber ?? '',
          'role': describeEnum(role),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'authProvider': 'email',
        };
        
        print("AuthService: User data to save: $userData");
        
        await _firestore
            .collection('users')
            .doc(uid)
            .set(userData);
            
        print("AuthService: User data saved to Firestore successfully");
        
        // Verify the document was created
        final docSnapshot = await _firestore.collection('users').doc(uid).get();
        if (docSnapshot.exists) {
          print("AuthService: Verified user document exists in Firestore. Data: ${docSnapshot.data()}");
          print("AuthService: Role in Firestore: ${docSnapshot.data()?['role']}");
          return true;
        } else {
          print("AuthService: Failed to verify user document exists after saving");
          attempts++;
          await Future.delayed(Duration(milliseconds: 500 * attempts));
          continue;
        }
      } catch (e) {
        print("Error saving user data to Firestore (attempt ${attempts + 1}): $e");
        attempts++;
        if (attempts >= maxAttempts) {
          print("All $maxAttempts attempts to save user data failed");
          return false;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    
    return false;
  }

  // Sign in with email and password
  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      firebase_auth.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login timestamp
      if (userCredential.user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print("Error updating last login: $e");
          // Continue even if Firestore update fails
        }

        // Save login state to shared preferences
        await _saveLoginState(true);
      }

      return userCredential;
    } catch (e) {
      print("Error in signIn: $e");
      rethrow;
    }
  }

  // Sign in with Google
  Future<firebase_auth.UserCredential> signInWithGoogle({app_models.UserRole role = app_models.UserRole.staff}) async {
    try {
      await _ensureGoogleSignInInitialized();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign in was cancelled by the user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Check if this is a new user
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // Save or update user data in Firestore
      if (userCredential.user != null) {
        try {
          final userData = {
            'name': userCredential.user!.displayName ?? '',
            'email': userCredential.user!.email ?? '',
            'lastLogin': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          };

          // If new user, add additional fields
          if (isNewUser) {
            userData['createdAt'] = FieldValue.serverTimestamp();
            userData['companyName'] = '';
            userData['phoneNumber'] = userCredential.user!.phoneNumber ?? '';
            userData['role'] = describeEnum(role); // Use the provided role
          }

          // Use set with merge to update existing or create new
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(
                userData,
                SetOptions(merge: true),
              );
        } catch (e) {
          print("Error saving Google user data to Firestore: $e");
          // Continue even if Firestore fails
        }

        // Save login state to shared preferences
        await _saveLoginState(true);
      }

      return userCredential;
    } catch (e) {
      print("Error in signInWithGoogle: $e");
      rethrow;
    }
  }

  // Get user app model
  Future<app_models.User?> getUserModel() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print("AuthService: getCurrentUser is null");
        return null;
      }

      print("AuthService: Getting user data from Firestore for UID: ${firebaseUser.uid}");
      
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (!doc.exists) {
          print("AuthService: User document doesn't exist in Firestore, creating one");
          
          // Create a default user document with staff role if it doesn't exist
          final userData = {
            'name': firebaseUser.displayName ?? 'User',
            'email': firebaseUser.email ?? '',
            'role': 'staff',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'authProvider': 'email',
          };
          
          // Save the user data to Firestore
          await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
          
          print("AuthService: Created default user document in Firestore");
          
          // Return the newly created user model
          return app_models.User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
            role: app_models.UserRole.staff,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            authProvider: 'email',
          );
        }

        print("AuthService: User document exists in Firestore with data: ${doc.data()}");
        // Check specifically for role
        if (doc.data()!.containsKey('role')) {
          print("AuthService: Role found in Firestore document: ${doc.data()!['role']}");
        } else {
          print("AuthService: Role not found in Firestore document");
        }
        
        return app_models.User.fromMap(doc.data()!, firebaseUser.uid);
      } catch (firestoreError) {
        print("AuthService: Firestore error when getting user model: $firestoreError");
        // Create a basic user anyway so the app doesn't crash
        return app_models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
          role: app_models.UserRole.staff,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          authProvider: 'email',
        );
      }
    } catch (e) {
      print("Error getting user model: $e");
      return null;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      return doc.data();
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user role in Firestore
  Future<bool> updateUserRole(String userId, app_models.UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': describeEnum(role),
      });
      return true;
    } catch (e) {
      print("Error updating user role: $e");
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
      await _saveLoginState(false);
    } catch (e) {
      print("Error in signOut: $e");
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error in resetPassword: $e");
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Save login state to shared preferences
  Future<void> _saveLoginState(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  // Update user data in Firestore
  Future<bool> updateUserData(app_models.User user) async {
    try {
      print("AuthService: Updating user data in Firestore for ${user.id}, role: ${describeEnum(user.role)}");
      
      final userData = {
        'name': user.name,
        'email': user.email,
        'companyName': user.companyName ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'role': describeEnum(user.role),
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': user.authProvider,
      };
      
      // Only set createdAt if not already present
      final doc = await _firestore.collection('users').doc(user.id).get();
      if (!doc.exists || doc.data()?['createdAt'] == null) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(userData, SetOptions(merge: true));
          
      print("AuthService: User data updated in Firestore successfully");
      return true;
    } catch (e) {
      print("Error updating user data in Firestore: $e");
      return false;
    }
  }
}

// Helper function to convert enum to string
String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}
