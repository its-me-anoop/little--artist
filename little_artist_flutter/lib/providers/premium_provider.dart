import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/store_manager.dart';

/// Provides the singleton [StoreManager] as a [ChangeNotifier] so widgets can
/// reactively watch purchase state, product details, and premium status.
final storeManagerProvider = ChangeNotifierProvider<StoreManager>((ref) {
  return StoreManager();
});

/// Convenience provider that exposes only the boolean premium flag.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(storeManagerProvider).isPremium;
});
