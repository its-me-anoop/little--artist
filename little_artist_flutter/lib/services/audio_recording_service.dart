import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Manages audio recording and playback for voice memos.
///
/// Uses [AudioRecorder] from the `record` package for capture and
/// [AudioPlayer] from `just_audio` for playback.
/// Records AAC audio at 44.1 kHz mono, capped at 30 seconds.
class AudioRecordingService extends ChangeNotifier {
  /// Maximum recording duration.
  static const maxDuration = Duration(seconds: 30);

  /// Sample rate for recording.
  static const _sampleRate = 44100;

  /// Number of level samples to keep in history.
  static const _maxLevelHistory = 30;

  // ---------------------------------------------------------------------------
  // Published state
  // ---------------------------------------------------------------------------

  /// Whether the service is currently recording.
  bool isRecording = false;

  /// Whether the service is currently playing audio.
  bool isPlaying = false;

  /// Current recording elapsed time.
  Duration recordingTime = Duration.zero;

  /// Current playback progress.
  Duration playbackTime = Duration.zero;

  /// Total duration of loaded audio for playback.
  Duration playbackDuration = Duration.zero;

  /// Current recording audio level (0.0 to 1.0) for live waveform.
  double currentLevel = 0.0;

  /// Rolling buffer of recent recording levels for live waveform display.
  List<double> levelHistory = [];

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Timer? _recordingTimer;
  Timer? _playbackTimer;
  String? _tempFilePath;

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  /// Requests microphone permission and begins recording.
  ///
  /// Automatically stops after [maxDuration].
  /// Returns `true` if recording started successfully.
  Future<bool> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return false;

    final tempDir = await getTemporaryDirectory();
    _tempFilePath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: _sampleRate,
          numChannels: 1,
          bitRate: 64000,
        ),
        path: _tempFilePath!,
      );

      isRecording = true;
      recordingTime = Duration.zero;
      levelHistory = [];
      currentLevel = 0.0;
      notifyListeners();

      _startRecordingTimer();
      return true;
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      return false;
    }
  }

  /// Stops the current recording and returns the audio data.
  Future<Uint8List?> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = await _recorder.stop();
      isRecording = false;
      notifyListeners();

      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final data = await file.readAsBytes();
      await _cleanupTempFile();
      return data;
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      isRecording = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancels and discards the current recording.
  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      await _recorder.stop();
    } catch (_) {}

    isRecording = false;
    recordingTime = Duration.zero;
    currentLevel = 0.0;
    levelHistory = [];
    notifyListeners();

    await _cleanupTempFile();
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Plays audio from raw data bytes.
  Future<void> play(Uint8List data) async {
    await stopPlayback();

    try {
      final tempDir = await getTemporaryDirectory();
      final playbackPath =
          '${tempDir.path}/playback_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(playbackPath);
      await file.writeAsBytes(data);

      final duration = await _player.setFilePath(playbackPath);
      playbackDuration = duration ?? Duration.zero;
      playbackTime = Duration.zero;
      notifyListeners();

      _player.play();
      isPlaying = true;
      notifyListeners();

      _startPlaybackTimer();

      // Clean up temp file when done and listen for completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          stopPlayback();
          try {
            File(playbackPath).deleteSync();
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Failed to play audio: $e');
      isPlaying = false;
      notifyListeners();
    }
  }

  /// Stops current playback.
  Future<void> stopPlayback() async {
    _playbackTimer?.cancel();
    _playbackTimer = null;

    try {
      await _player.stop();
    } catch (_) {}

    isPlaying = false;
    playbackTime = Duration.zero;
    currentLevel = 0.0;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Amplitude extraction
  // ---------------------------------------------------------------------------

  /// Extracts amplitude samples from audio data for waveform display.
  ///
  /// Since direct PCM parsing of AAC/M4A is complex in Dart, this generates
  /// smooth pseudo-random waveform data suitable for visualization.
  static List<double> extractAmplitudes(Uint8List data, int sampleCount) {
    if (data.isEmpty || sampleCount <= 0) {
      return List.filled(sampleCount, 0.08);
    }

    // Use the audio data bytes as a seed for deterministic waveform generation.
    // This produces a consistent waveform for the same audio data.
    final random = Random(data.fold<int>(0, (prev, byte) => prev ^ byte));
    final amplitudes = List<double>.generate(sampleCount, (i) {
      final t = i / sampleCount;
      // Create a natural-looking waveform with smooth variation
      final base = 0.2 + 0.6 * (sin(t * pi * 3)).abs();
      final noise = random.nextDouble() * 0.3;
      return (base + noise).clamp(0.08, 1.0);
    });

    // Normalize to 0...1 range
    final maxAmp = amplitudes.reduce(max);
    if (maxAmp > 0) {
      for (int i = 0; i < amplitudes.length; i++) {
        amplitudes[i] = (amplitudes[i] / maxAmp).clamp(0.08, 1.0);
      }
    }

    return amplitudes;
  }

  // ---------------------------------------------------------------------------
  // Timers
  // ---------------------------------------------------------------------------

  void _startRecordingTimer() {
    _recordingTimer =
        Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (!isRecording) return;

      // Update recording time
      final amplitude = await _recorder.getAmplitude();
      recordingTime += const Duration(milliseconds: 50);

      // Convert dB to 0...1 linear scale (-60 dB floor)
      final db = amplitude.current;
      final linear = _dbToLinear(db);
      currentLevel = linear;
      levelHistory.add(linear);
      if (levelHistory.length > _maxLevelHistory) {
        levelHistory.removeAt(0);
      }

      notifyListeners();

      // Auto-stop at max duration
      if (recordingTime >= maxDuration) {
        await stopRecording();
      }
    });
  }

  void _startPlaybackTimer() {
    _playbackTimer =
        Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (!isPlaying) return;

      final position = _player.position;
      playbackTime = position;
      notifyListeners();

      if (position >= playbackDuration && playbackDuration > Duration.zero) {
        await stopPlayback();
      }
    });
  }

  /// Converts decibels to a 0...1 linear scale with a -60 dB floor.
  static double _dbToLinear(double db) {
    const minDb = -60.0;
    if (db <= minDb) return 0.0;
    return ((db - minDb) / (0 - minDb)).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> _cleanupTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _tempFilePath = null;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _cleanupTempFile();
    super.dispose();
  }
}
