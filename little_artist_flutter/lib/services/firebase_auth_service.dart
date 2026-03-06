import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Manages Firebase Authentication lifecycle.
///
/// On first launch the user is signed in anonymously. When premium
/// users enable sync, they upgrade to Sign in with Apple via
/// [signInWithApple], preserving their anonymous UID and any data
/// already written to Firestore.
class FirebaseAuthService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// The currently authenticated Firebase user (anonymous or Apple-linked).
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// `true` while an auth operation is in flight.
  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  /// Human-readable error from the last auth attempt, if any.
  String? _authError;
  String? get authError => _authError;

  /// `true` once the user has linked an Apple credential.
  bool get isLinkedWithApple {
    return _currentUser?.providerData
            .any((info) => info.providerId == 'apple.com') ??
        false;
  }

  /// Convenience accessor for the Firebase UID.
  String? get userId => _currentUser?.uid;

  /// Stream of auth state changes from Firebase.
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  FirebaseAuthService() {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  // ---------------------------------------------------------------------------
  // Anonymous Auth
  // ---------------------------------------------------------------------------

  /// Signs in anonymously. Called automatically at first launch.
  Future<void> signInAnonymously() async {
    if (_currentUser != null) return;
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      _currentUser = result.user;
      debugPrint('Anonymous sign-in OK: ${result.user?.uid}');
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Anonymous sign-in failed.';
      debugPrint('Anonymous sign-in failed: ${e.message}');
    } catch (e) {
      _authError = e.toString();
      debugPrint('Anonymous sign-in failed: $e');
    }

    _isAuthenticating = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sign in with Apple
  // ---------------------------------------------------------------------------

  /// Starts the Sign in with Apple flow and links the credential to the
  /// current anonymous account. Returns `true` on success.
  Future<bool> signInWithApple() async {
    _isAuthenticating = true;
    _authError = null;
    notifyListeners();

    try {
      final rawNonce = _generateNonce();
      final sha256Nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // If the current user is anonymous, try to link the Apple credential
      // so the UID (and any associated data) is preserved.
      if (_currentUser != null && _currentUser!.isAnonymous) {
        try {
          final result =
              await _currentUser!.linkWithCredential(oauthCredential);
          _currentUser = result.user;
          debugPrint(
              'Apple account linked to anonymous: ${result.user?.uid}');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // The Apple credential is already associated with another
            // Firebase account. Delete the orphaned anonymous user and
            // sign in directly with the existing account.
            debugPrint(
                'Credential already in use - deleting anonymous user and signing in directly');
            try {
              await _currentUser!.delete();
            } catch (_) {
              // Best-effort cleanup of the anonymous account.
            }
            final result = await FirebaseAuth.instance
                .signInWithCredential(oauthCredential);
            _currentUser = result.user;
            debugPrint(
                'Apple sign-in OK (credential reuse recovery): ${result.user?.uid}');
          } else {
            rethrow;
          }
        }
      } else {
        // No anonymous user — sign in directly.
        final result =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        _currentUser = result.user;
        debugPrint('Apple sign-in OK: ${result.user?.uid}');
      }

      _isAuthenticating = false;
      notifyListeners();
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      _authError = e.message;
      debugPrint('Apple sign-in cancelled or failed: ${e.message}');
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Apple sign-in failed.';
      debugPrint('Apple sign-in failed: ${e.message}');
    } catch (e) {
      _authError = e.toString();
      debugPrint('Apple sign-in failed: $e');
    }

    _isAuthenticating = false;
    notifyListeners();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Signs out the current user and re-authenticates anonymously.
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _currentUser = null;
      debugPrint('Signed out - will re-authenticate anonymously');
      notifyListeners();
      await signInAnonymously();
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Sign-out failed.';
      debugPrint('Sign-out failed: ${e.message}');
      notifyListeners();
    } catch (e) {
      _authError = e.toString();
      debugPrint('Sign-out failed: $e');
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Account
  // ---------------------------------------------------------------------------

  /// Deletes the current Firebase account, then falls back to anonymous auth.
  Future<void> deleteAccount() async {
    try {
      await _currentUser?.delete();
      _currentUser = null;
      debugPrint('Account deleted - will re-authenticate anonymously');
      notifyListeners();
      await signInAnonymously();
    } on FirebaseAuthException catch (e) {
      _authError = e.message ?? 'Account deletion failed.';
      debugPrint('Account deletion failed: ${e.message}');
      notifyListeners();
    } catch (e) {
      _authError = e.toString();
      debugPrint('Account deletion failed: $e');
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Generates a cryptographically secure random nonce string.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA-256 hash of [input] as a hex string.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
