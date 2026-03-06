import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/audio_recording_service.dart';
import '../../utils/brand_tokens.dart';
import 'playback_waveform_view.dart';

/// Voice memo playback widget with play/pause, waveform, and duration display.
///
/// Renders a circular play/pause button, a [PlaybackWaveformView] showing
/// playback progress, and a duration label.
class VoiceMemoPlayerView extends StatefulWidget {
  /// The raw audio data to play.
  final Uint8List audioData;

  const VoiceMemoPlayerView({
    super.key,
    required this.audioData,
  });

  @override
  State<VoiceMemoPlayerView> createState() => _VoiceMemoPlayerViewState();
}

class _VoiceMemoPlayerViewState extends State<VoiceMemoPlayerView> {
  final AudioRecordingService _service = AudioRecordingService();
  late final List<double> _amplitudes;

  @override
  void initState() {
    super.initState();
    _amplitudes = AudioRecordingService.extractAmplitudes(widget.audioData, 30);
    _service.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    if (_service.isPlaying) {
      await _service.stopPlayback();
    } else {
      await _service.play(widget.audioData);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (_service.playbackDuration.inMilliseconds == 0) return 0.0;
    return (_service.playbackTime.inMilliseconds /
            _service.playbackDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _service.isPlaying
        ? _service.playbackDuration
        : _service.playbackDuration;
    final displayDuration =
        duration > Duration.zero ? duration : const Duration(seconds: 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayback,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Brand.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _service.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Waveform
        Expanded(
          child: PlaybackWaveformView(
            amplitudes: _amplitudes,
            progress: _progress,
          ),
        ),
        const SizedBox(width: 10),

        // Duration label
        Text(
          _formatDuration(
            _service.isPlaying ? _service.playbackTime : displayDuration,
          ),
          style: Brand.captionFont.copyWith(color: Brand.warmGray),
        ),
      ],
    );
  }
}
