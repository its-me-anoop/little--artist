import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// Describes which usage limit was exceeded and when it resets.
enum ExceededLimit {
  daily,
  weekly,
  monthly;

  /// Human-readable message including the relative reset time.
  String message(DateTime resetDate) {
    final now = DateTime.now();
    final diff = resetDate.difference(now);

    String relative;
    if (diff.inDays >= 1) {
      relative = 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    } else if (diff.inHours >= 1) {
      relative = 'in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    } else if (diff.inMinutes >= 1) {
      relative = 'in ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}';
    } else {
      relative = 'shortly';
    }

    switch (this) {
      case ExceededLimit.daily:
        return 'Daily AI limit reached. Resets $relative.';
      case ExceededLimit.weekly:
        return 'Weekly AI limit reached. Resets $relative.';
      case ExceededLimit.monthly:
        return 'Monthly AI limit reached. Resets $relative.';
    }
  }
}

/// Usage data for a single tracking period.
class PeriodUsage {
  final int used;
  final int limit;
  final DateTime resetDate;

  const PeriodUsage({
    required this.used,
    required this.limit,
    required this.resetDate,
  });

  int get remaining => (limit - used).clamp(0, limit);
  double get fraction => used / limit;
  bool get isExceeded => used >= limit;
}

/// Snapshot of usage across all three periods.
class UsageSummary {
  final PeriodUsage daily;
  final PeriodUsage weekly;
  final PeriodUsage monthly;

  const UsageSummary({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });
}

// ---------------------------------------------------------------------------
// Tracker
// ---------------------------------------------------------------------------

/// Tracks Gemini API request usage and enforces rate limits.
///
/// Persists counters in SharedPreferences with automatic period rollover.
/// Each call to [recordRequest] increments the current period's count.
/// Check [canMakeRequest] before every Gemini API call.
class GeminiUsageTracker extends ChangeNotifier {
  // Limits
  static const dailyLimit = 15;
  static const weeklyLimit = 60;
  static const monthlyLimit = 200;

  // State
  int dailyCount = 0;
  int weeklyCount = 0;
  int monthlyCount = 0;

  // Persistence keys
  static const _keyDailyCount = 'geminiDailyCount';
  static const _keyWeeklyCount = 'geminiWeeklyCount';
  static const _keyMonthlyCount = 'geminiMonthlyCount';
  static const _keyLastDailyReset = 'geminiLastDailyReset';
  static const _keyLastWeeklyReset = 'geminiLastWeeklyReset';
  static const _keyLastMonthlyReset = 'geminiLastMonthlyReset';

  SharedPreferences? _prefs;
  bool _initialised = false;

  /// Loads persisted counters and performs any needed rollovers.
  Future<void> initialise() async {
    if (_initialised) return;
    _prefs = await SharedPreferences.getInstance();
    _rolloverIfNeeded();
    _initialised = true;
  }

  /// Whether a new Gemini API request is allowed under all active limits.
  bool get canMakeRequest {
    _rolloverIfNeeded();
    return dailyCount < dailyLimit &&
        weeklyCount < weeklyLimit &&
        monthlyCount < monthlyLimit;
  }

  /// The most restrictive limit that is currently exceeded, if any.
  ExceededLimit? get exceededLimit {
    _rolloverIfNeeded();
    if (dailyCount >= dailyLimit) return ExceededLimit.daily;
    if (weeklyCount >= weeklyLimit) return ExceededLimit.weekly;
    if (monthlyCount >= monthlyLimit) return ExceededLimit.monthly;
    return null;
  }

  /// The reset date for the currently exceeded limit, if any.
  DateTime? get exceededLimitResetDate {
    _rolloverIfNeeded();
    if (dailyCount >= dailyLimit) return _nextDailyReset;
    if (weeklyCount >= weeklyLimit) return _nextWeeklyReset;
    if (monthlyCount >= monthlyLimit) return _nextMonthlyReset;
    return null;
  }

  /// Records a successful Gemini API request.
  void recordRequest() {
    _rolloverIfNeeded();
    dailyCount++;
    weeklyCount++;
    monthlyCount++;
    _save();
    notifyListeners();
    debugPrint(
      'Gemini usage: $dailyCount/$dailyLimit daily, '
      '$weeklyCount/$weeklyLimit weekly, '
      '$monthlyCount/$monthlyLimit monthly',
    );
  }

  /// Remaining requests for the most restrictive active period.
  int get remainingRequests {
    _rolloverIfNeeded();
    final remaining = [
      dailyLimit - dailyCount,
      weeklyLimit - weeklyCount,
      monthlyLimit - monthlyCount,
    ];
    return remaining.reduce((a, b) => a < b ? a : b);
  }

  /// Summary of current usage across all periods.
  UsageSummary get usageSummary {
    _rolloverIfNeeded();
    return UsageSummary(
      daily: PeriodUsage(
        used: dailyCount,
        limit: dailyLimit,
        resetDate: _nextDailyReset,
      ),
      weekly: PeriodUsage(
        used: weeklyCount,
        limit: weeklyLimit,
        resetDate: _nextWeeklyReset,
      ),
      monthly: PeriodUsage(
        used: monthlyCount,
        limit: monthlyLimit,
        resetDate: _nextMonthlyReset,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Period rollover
  // ---------------------------------------------------------------------------

  void _rolloverIfNeeded() {
    final prefs = _prefs;
    if (prefs == null) return;

    final now = DateTime.now();
    bool didReset = false;

    // Daily reset
    final lastDailyMs = prefs.getInt(_keyLastDailyReset);
    final lastDaily = lastDailyMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastDailyMs)
        : DateTime(2000);
    if (!_isSameDay(lastDaily, now)) {
      dailyCount = 0;
      prefs.setInt(_keyLastDailyReset, now.millisecondsSinceEpoch);
      didReset = true;
    } else {
      dailyCount = prefs.getInt(_keyDailyCount) ?? 0;
    }

    // Weekly reset (different ISO week number or year)
    final lastWeeklyMs = prefs.getInt(_keyLastWeeklyReset);
    final lastWeekly = lastWeeklyMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastWeeklyMs)
        : DateTime(2000);
    if (_isoWeekNumber(lastWeekly) != _isoWeekNumber(now) ||
        _isoWeekYear(lastWeekly) != _isoWeekYear(now)) {
      weeklyCount = 0;
      prefs.setInt(_keyLastWeeklyReset, now.millisecondsSinceEpoch);
      didReset = true;
    } else {
      weeklyCount = prefs.getInt(_keyWeeklyCount) ?? 0;
    }

    // Monthly reset
    final lastMonthlyMs = prefs.getInt(_keyLastMonthlyReset);
    final lastMonthly = lastMonthlyMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMonthlyMs)
        : DateTime(2000);
    if (lastMonthly.month != now.month || lastMonthly.year != now.year) {
      monthlyCount = 0;
      prefs.setInt(_keyLastMonthlyReset, now.millisecondsSinceEpoch);
      didReset = true;
    } else {
      monthlyCount = prefs.getInt(_keyMonthlyCount) ?? 0;
    }

    if (didReset) {
      _save();
      debugPrint('Gemini usage counters reset');
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setInt(_keyDailyCount, dailyCount);
    prefs.setInt(_keyWeeklyCount, weeklyCount);
    prefs.setInt(_keyMonthlyCount, monthlyCount);
  }

  // ---------------------------------------------------------------------------
  // Reset date helpers
  // ---------------------------------------------------------------------------

  DateTime get _nextDailyReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime get _nextWeeklyReset {
    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    final daysUntilNextMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday =
        daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday;
    return DateTime(now.year, now.month, now.day + nextMonday);
  }

  DateTime get _nextMonthlyReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  // ---------------------------------------------------------------------------
  // Date helpers
  // ---------------------------------------------------------------------------

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// ISO 8601 week number.
  static int _isoWeekNumber(DateTime date) {
    // Algorithm: find the Thursday of this date's week, then count weeks.
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final jan1 = DateTime(thursday.year, 1, 1);
    return ((thursday.difference(jan1).inDays) / 7).ceil() + 1;
  }

  /// ISO 8601 week-numbering year.
  static int _isoWeekYear(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    return thursday.year;
  }
}
