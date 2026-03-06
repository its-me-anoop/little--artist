import 'package:flutter/material.dart';

import 'fan_cards_view.dart';
import 'drop_cards_view.dart';
import 'pulse_cards_view.dart';
import 'drift_cards_view.dart';

/// Displays the appropriate card animation for the given onboarding page.
class AnimatedCardsView extends StatelessWidget {
  const AnimatedCardsView({super.key, required this.pageIndex});

  /// The current onboarding page index (0-3).
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return switch (pageIndex) {
      0 => const FanCardsView(),
      1 => const DropCardsView(),
      2 => const PulseCardsView(),
      3 => const DriftCardsView(),
      _ => const SizedBox.shrink(),
    };
  }
}
