import 'package:flutter/services.dart';

/// Provides simple haptic feedback helpers using platform haptic APIs.
abstract final class HapticService {
  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void warning() => HapticFeedback.vibrate();
}
