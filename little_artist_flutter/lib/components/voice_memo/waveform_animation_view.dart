import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Animated waveform bars for real-time recording visualization.
///
/// Displays a row of vertical bars whose heights correspond to the
/// provided [levels] (0.0-1.0). Bars have rounded caps and a minimum
/// height of 4px.
class WaveformAnimationView extends StatelessWidget {
  /// Audio level values, each in the range 0.0 to 1.0.
  final List<double> levels;

  /// Color of the waveform bars.
  final Color color;

  /// Maximum bar height.
  final double maxHeight;

  const WaveformAnimationView({
    super.key,
    required this.levels,
    this.color = Brand.primary,
    this.maxHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < levels.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          _WaveformBar(
            height: (levels[i].clamp(0.0, 1.0) * maxHeight).clamp(4.0, maxHeight),
            color: color,
          ),
        ],
      ],
    );
  }
}

class _WaveformBar extends StatelessWidget {
  final double height;
  final Color color;

  const _WaveformBar({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
