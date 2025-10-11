import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static GoogleSignIn? _googleSignIn;

  // Initialize Google Sign-In with proper error handling
  static GoogleSignIn get googleSignIn {
    if (_googleSignIn == null) {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Add this for better Android compatibility
        signInOption: SignInOption.standard,
      );
    }
    return _googleSignIn!;
  }

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      print('FirebaseService: Initializing Firebase services...');
      // Firebase is already initialized in main.dart, just initialize Google Sign-In
      await _initializeGoogleSignIn();
      print('FirebaseService: Firebase services initialized successfully');
    } catch (e) {
      print('Firebase services initialization error: $e');
      // Don't rethrow as it might prevent app startup
    }
  }

  // Initialize Google Sign-In separately
  static Future<void> _initializeGoogleSignIn() async {
    try {
      // Force initialization of Google Sign-In
      await googleSignIn.isSignedIn();
    } catch (e) {
      print('Google Sign-In initialization error: $e');
      // Don't rethrow here as it might prevent app startup
    }
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges {
    print('FirebaseService: Getting auth state changes stream');

    return _auth.authStateChanges().map((user) {
      print(
        'FirebaseService: Auth state changed - User: ${user?.email}, UID: ${user?.uid}',
      );
      return user;
    });
  }

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Get user display name
  static String get userDisplayName =>
      currentUser?.displayName ?? currentUser?.email ?? 'User';

  // Get user email
  static String get userEmail => currentUser?.email ?? '';

  // Get user photo URL
  static String? get userPhotoURL => currentUser?.photoURL;

  // Store login date for daily logout feature
  static Future<void> _storeLoginDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('lastLoginDate', today);
      print('FirebaseService: Login date stored: $today');
    } catch (e) {
      print('FirebaseService: Error storing login date: $e');
    }
  }

  // Check and sign out if new day (your existing feature)
  static Future<void> checkAndSignOutIfNewDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String today = DateTime.now().toIso8601String().substring(0, 10);
      final String? lastLoginDate = prefs.getString('lastLoginDate');

      print(
        'FirebaseService: Checking daily logout - Today: $today, Last login: $lastLoginDate, Is signed in: $isSignedIn',
      );

      if (lastLoginDate != null && lastLoginDate != today) {
        // New day detected, sign out
        print('FirebaseService: New day detected, signing out user');
        await signOut();
        await prefs.setString('lastLoginDate', today);
      } else if (lastLoginDate == null && isSignedIn) {
        // First login, set date
        print('FirebaseService: First login, setting date to $today');
        await prefs.setString('lastLoginDate', today);
      } else {
        print('FirebaseService: No daily logout needed');
      }
    } catch (e) {
      print('FirebaseService: Error in daily logout check: $e');
    }
  }

  // Email/Password Sign Up
  static Future<User?> signUpWithEmailPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      print('FirebaseService: Starting email/password sign up for $email');
      final displayName = '$firstName $lastName'.trim();
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print(
        'FirebaseService: Email sign up successful for ${userCredential.user?.email}',
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(
        userCredential.user!,
        displayName,
        firstName,
        lastName,
      );

      // Store login date
      await _storeLoginDate();

      print('FirebaseService: Email sign up completed, returning user');

      // Force a small delay to ensure Firebase auth state is updated
      await Future.delayed(const Duration(milliseconds: 100));

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  static Future<User?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      print('FirebaseService: Starting email/password sign in for $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        'FirebaseService: Email sign in successful for ${userCredential.user?.email}',
      );

      // Update last sign in
      await updateLastSignIn();

      // Store login date
      await _storeLoginDate();

      print('FirebaseService: Email sign in completed, returning user');

      // Force a small delay to ensure Firebase auth state is updated
      await Future.delayed(const Duration(milliseconds: 100));

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Google Sign In - Enhanced with better error handling
  static Future<User?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');

      // First, ensure we're signed out from any previous sessions
      await googleSignIn.signOut();

      // Add a small delay to ensure cleanup
      await Future.delayed(const Duration(milliseconds: 500));

      print('Attempting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      print('Google Sign-In result: ${googleUser?.email}');

      // If the user cancels the sign-in
      if (googleUser == null) {
        print('Google Sign-In was cancelled by user');
        return null;
      }

      print('Getting Google authentication details...');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Creating Firebase credential...');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with Google credential...');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      print('Firebase sign-in successful: ${userCredential.user?.email}');

      // Create user document if new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        print('Creating user document for new user...');
        final nameParts = (userCredential.user?.displayName ?? 'User').split(
          ' ',
        );
        final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        final lastName = nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : '';

        await _createUserDocument(
          userCredential.user!,
          userCredential.user?.displayName ?? 'User',
          firstName,
          lastName,
        );
      } else {
        // Update last sign in for existing users
        print('Updating last sign-in for existing user...');
        await updateLastSignIn();
      }

      // Store login date
      await _storeLoginDate();

      print('Google Sign-In completed successfully');

      // Force a small delay to ensure Firebase auth state is updated
      await Future.delayed(const Duration(milliseconds: 100));

      return userCredential.user;
    } on PlatformException catch (e) {
      print('Platform Exception during Google Sign-In: $e');

      // Handle specific platform exceptions
      if (e.code == 'channel-error') {
        throw Exception(
          'Google Sign-In service is not available. Please try again later.',
        );
      } else if (e.code == 'sign_in_canceled') {
        print('Google Sign-In was cancelled');
        return null;
      } else if (e.code == 'sign_in_failed') {
        throw Exception('Google Sign-In failed. Please try again.');
      } else if (e.code == 'network_error') {
        throw Exception(
          'Network error during Google Sign-In. Please check your connection.',
        );
      }

      throw Exception('Google Sign-In failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during Google Sign-In: $e');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('Unexpected error during Google Sign-In: $e');
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Alternative Google Sign-In method with retry logic
  static Future<User?> signInWithGoogleRetry() async {
    const int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        return await signInWithGoogle();
      } catch (e) {
        currentRetry++;
        print('Google Sign-In attempt $currentRetry failed: $e');

        if (currentRetry >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: currentRetry * 2));

        // Try to reinitialize Google Sign-In
        try {
          await _initializeGoogleSignIn();
        } catch (initError) {
          print('Failed to reinitialize Google Sign-In: $initError');
        }
      }
    }

    return null;
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      // Sign out from Google first
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      // Then sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      // Still try to sign out from Firebase even if Google sign out fails
      try {
        await _auth.signOut();
      } catch (firebaseError) {
        print('Firebase sign out error: $firebaseError');
      }
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Create user document in Firestore
  static Future<void> _createUserDocument(
    User user,
    String displayName,
    String? firstName,
    String? lastName,
  ) async {
    try {
      print('FirebaseService: Creating user document for ${user.email}');
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'settings': {'notifications': true, 'darkMode': true, 'language': 'en'},
      }, SetOptions(merge: true));
      print('FirebaseService: User document created successfully');
    } catch (e) {
      print('FirebaseService: Error creating user document: $e');
      rethrow; // Re-throw to handle this error in the calling method
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);

        // Update Firestore document
        await _firestore.collection('users').doc(user.uid).update({
          'displayName': displayName,
          'photoURL': photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Get user data from Firestore
  static Future<DocumentSnapshot?> getUserData() async {
    try {
      User? user = currentUser;
      if (user != null) {
        return await _firestore.collection('users').doc(user.uid).get();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update last sign in
  static Future<void> updateLastSignIn() async {
    try {
      User? user = currentUser;
      if (user != null) {
        print('FirebaseService: Updating last sign in for ${user.email}');
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
        print('FirebaseService: Last sign in updated successfully');
      } else {
        print('FirebaseService: No current user to update last sign in');
      }
    } catch (e) {
      print('FirebaseService: Error updating last sign in: $e');
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
