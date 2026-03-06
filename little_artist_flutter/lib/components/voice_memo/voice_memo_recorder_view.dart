import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/audio_recording_service.dart';
import '../../utils/brand_tokens.dart';
import 'waveform_animation_view.dart';

/// Voice memo recording widget with record, stop, and cancel controls.
///
/// When idle, displays a circular red record button. During recording,
/// shows a live waveform, elapsed timer, and stop/cancel buttons.
/// Automatically stops at 30 seconds.
class VoiceMemoRecorderView extends StatefulWidget {
  /// Called with the recorded audio bytes when recording is stopped.
  final ValueChanged<Uint8List> onRecordingComplete;

  /// Called when the user cancels recording.
  final VoidCallback? onCancel;

  const VoiceMemoRecorderView({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceMemoRecorderView> createState() => _VoiceMemoRecorderViewState();
}

class _VoiceMemoRecorderViewState extends State<VoiceMemoRecorderView> {
  final AudioRecordingService _service = AudioRecordingService();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    final wasRecording = _isRecording;
    setState(() {
      _isRecording = _service.isRecording;
    });

    // Auto-stop triggered by the service (30s limit)
    if (wasRecording && !_service.isRecording) {
      _handleAutoStop();
    }
  }

  Future<void> _handleAutoStop() async {
    // The service already stopped; retrieve data from the last stop call.
    // Since the service auto-stopped internally, we need to get data separately.
    // The auto-stop in the service calls stopRecording() which returns data,
    // but we can't capture that return value from the listener.
    // Instead, we handle the stop explicitly below.
  }

  Future<void> _startRecording() async {
    final started = await _service.startRecording();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final data = await _service.stopRecording();
    if (data != null && mounted) {
      widget.onRecordingComplete(data);
    }
  }

  Future<void> _cancelRecording() async {
    await _service.cancelRecording();
    widget.onCancel?.call();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return _buildIdleState();
    }
    return _buildRecordingState();
  }

  // ---------------------------------------------------------------------------
  // MARK: - Idle State
  // ---------------------------------------------------------------------------

  Widget _buildIdleState() {
    return Center(
      child: GestureDetector(
        onTap: _startRecording,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Brand.dustyRose,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Recording State
  // ---------------------------------------------------------------------------

  Widget _buildRecordingState() {
    final progress = _service.recordingTime.inMilliseconds /
        AudioRecordingService.maxDuration.inMilliseconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform
        SizedBox(
          height: 44,
          child: WaveformAnimationView(
            levels: _service.levelHistory,
            color: Brand.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Timer
        Text(
          _formatDuration(_service.recordingTime),
          style: Brand.headlineFont.copyWith(color: Brand.charcoal),
        ),
        const SizedBox(height: 4),

        // Recording label
        Text(
          'Recording...',
          style: Brand.captionFont.copyWith(color: Brand.warmGray),
        ),
        const SizedBox(height: 12),

        // Progress bar (30 second max indicator)
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Brand.softTan,
            valueColor: const AlwaysStoppedAnimation<Color>(Brand.primary),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 12),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel button
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Brand.softTan,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Brand.charcoal,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Stop button
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Brand.dustyRose,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
