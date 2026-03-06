import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_repository.dart';
import '../services/firestore_sync_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

/// Provides the singleton [FirestoreRepository] for dual-write operations.
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final authService = ref.watch(firebaseAuthServiceProvider);
  final storageService = StorageService();
  return FirestoreRepository(
    db: db,
    authService: authService,
    storageService: storageService,
  );
});

/// Provides the singleton [FirestoreSyncService] for real-time Firestore
/// snapshot reconciliation into the local Drift database.
final syncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final repository = ref.watch(firestoreRepositoryProvider);
  final authService = ref.watch(firebaseAuthServiceProvider);
  final storageService = StorageService();
  return FirestoreSyncService(
    db: db,
    repository: repository,
    storageService: storageService,
    authService: authService,
  );
});
