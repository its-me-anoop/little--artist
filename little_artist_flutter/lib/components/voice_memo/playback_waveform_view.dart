import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Static waveform visualization with playback position indicator.
///
/// Bars before the current [progress] position are rendered in [activeColor],
/// while bars after are rendered in [inactiveColor].
class PlaybackWaveformView extends StatelessWidget {
  /// Pre-computed amplitude values (0.0-1.0) from the audio data.
  final List<double> amplitudes;

  /// Current playback position as a fraction (0.0-1.0).
  final double progress;

  /// Color for bars that have been played.
  final Color activeColor;

  /// Color for bars that have not yet been played.
  final Color inactiveColor;

  /// Maximum bar height.
  final double maxHeight;

  const PlaybackWaveformView({
    super.key,
    required this.amplitudes,
    this.progress = 0.0,
    this.activeColor = Brand.primary,
    this.inactiveColor = Brand.softTan,
    this.maxHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (amplitudes.isEmpty) return const SizedBox.shrink();

    final progressIndex = (progress.clamp(0.0, 1.0) * amplitudes.length).floor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < amplitudes.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 3,
            height: (amplitudes[i].clamp(0.0, 1.0) * maxHeight).clamp(4.0, maxHeight),
            decoration: BoxDecoration(
              color: i < progressIndex ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ],
    );
  }
}
