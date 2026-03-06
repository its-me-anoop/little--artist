import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_auth_service.dart';

/// Provides the singleton [FirebaseAuthService] instance as a [ChangeNotifier].
final firebaseAuthServiceProvider =
    ChangeNotifierProvider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream of Firebase auth state changes (emits the current [User] or `null`).
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Convenience provider that exposes just the current user's UID.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Whether the current user has linked an Apple credential.
final isLinkedWithAppleProvider = Provider<bool>((ref) {
  return ref.watch(firebaseAuthServiceProvider).isLinkedWithApple;
});
