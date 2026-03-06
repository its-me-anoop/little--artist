import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight static manager that tracks whether the current user has an
/// active premium subscription and exposes free-tier limits.
abstract final class PremiumManager {
  static const int freeChildLimit = 2;
  static const int freeArtworkLimit = 50;

  static bool _isPremium = false;

  static bool get isPremium => _isPremium;

  /// Load the persisted premium flag from disk. Call once at app startup.
  static Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('isPremium') ?? false;
  }

  /// Persist the premium flag. Typically called by [StoreManager] after a
  /// successful purchase or restore.
  static Future<void> setIsPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', value);
  }

  static bool canAddChild(int currentCount) =>
      isPremium || currentCount < freeChildLimit;

  static bool canAddArtwork(int currentCount) =>
      isPremium || currentCount < freeArtworkLimit;

  static bool canShare() => isPremium;

  static bool canUseVoiceMemos() => isPremium;
}
