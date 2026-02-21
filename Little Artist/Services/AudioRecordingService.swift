//
//  AudioRecordingService.swift
//  Little Artist
//
//  Centralized audio recording and playback service using AVFoundation.
//  Records AAC audio at 44.1kHz mono, capped at 30 seconds.
//  Provides real-time metering and amplitude extraction for waveform display.
//

import AVFoundation
import Combine
import SwiftUI

/// Manages audio recording and playback for voice memos.
///
/// Uses AVAudioRecorder for capture and AVAudioPlayer for playback.
/// Each view that needs recording or playback creates its own instance
/// via `@StateObject`.
@MainActor
final class AudioRecordingService: ObservableObject {

    // MARK: - Published State

    /// Whether the service is currently recording.
    @Published private(set) var isRecording = false

    /// Whether the service is currently playing audio.
    @Published private(set) var isPlaying = false

    /// Current recording elapsed time in seconds (0...30).
    @Published private(set) var recordingTime: TimeInterval = 0

    /// Current playback progress in seconds.
    @Published private(set) var playbackTime: TimeInterval = 0

    /// Total duration of loaded audio for playback.
    @Published private(set) var playbackDuration: TimeInterval = 0

    /// Current recording audio level (0.0 to 1.0) for live waveform.
    @Published private(set) var currentLevel: Float = 0

    /// Rolling buffer of recent recording levels for live waveform display.
    @Published private(set) var levelHistory: [Float] = []

    // MARK: - Constants

    /// Maximum recording duration in seconds.
    static let maxDuration: TimeInterval = 30

    /// Number of level samples to keep in history.
    private static let maxLevelHistory = 30

    // MARK: - Private

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var tempURL: URL?

    /// Audio settings for AAC M4A recording.
    private static let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44_100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 64_000
    ]

    // MARK: - Recording

    /// Requests microphone permission and begins recording.
    /// Automatically stops after ``maxDuration`` seconds.
    /// - Returns: `true` if recording started successfully.
    func startRecording() async -> Bool {
        let permission = await AVAudioApplication.requestRecordPermission()
        guard permission else { return false }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return false
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        tempURL = url

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: Self.recordingSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record(forDuration: Self.maxDuration)
            isRecording = true
            recordingTime = 0
            levelHistory = []
            currentLevel = 0
            startRecordingTimer()
            return true
        } catch {
            return false
        }
    }

    /// Stops the current recording and returns the audio data.
    func stopRecording() -> Data? {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        isRecording = false

        defer { cleanupTempFile() }

        guard let url = tempURL else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Cancels and discards the current recording.
    func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        isRecording = false
        recordingTime = 0
        currentLevel = 0
        levelHistory = []
        cleanupTempFile()
    }

    // MARK: - Playback

    /// Plays audio from raw data.
    func play(data: Data) {
        stopPlayback()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.isMeteringEnabled = true
            playbackDuration = audioPlayer?.duration ?? 0
            playbackTime = 0
            audioPlayer?.play()
            isPlaying = true
            startPlaybackTimer()
        } catch {
            isPlaying = false
        }
    }

    /// Stops current playback.
    func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackTime = 0
        currentLevel = 0
    }

    // MARK: - Amplitude Extraction

    /// Extracts normalized amplitude samples from audio data for waveform display.
    /// - Parameters:
    ///   - data: The audio data (M4A/AAC).
    ///   - sampleCount: Number of amplitude bars to generate.
    /// - Returns: Array of normalized amplitudes (0.0 to 1.0).
    nonisolated static func extractAmplitudes(from data: Data, sampleCount: Int = 20) -> [Float] {
        // Write data to a temp file so AVAudioFile can read it
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        do {
            try data.write(to: tempURL)
        } catch {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        defer { try? FileManager.default.removeItem(at: tempURL) }

        guard let audioFile = try? AVAudioFile(forReading: tempURL) else {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        let frameCount = AVAudioFrameCount(audioFile.length)
        guard frameCount > 0,
              let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: audioFile.fileFormat.sampleRate,
                                         channels: 1,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        do {
            try audioFile.read(into: buffer)
        } catch {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        guard let channelData = buffer.floatChannelData?[0] else {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        let totalFrames = Int(buffer.frameLength)
        let framesPerSample = totalFrames / sampleCount
        guard framesPerSample > 0 else {
            return Self.fallbackAmplitudes(count: sampleCount)
        }

        var amplitudes = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let start = i * framesPerSample
            let end = min(start + framesPerSample, totalFrames)
            var sum: Float = 0
            for j in start..<end {
                sum += abs(channelData[j])
            }
            amplitudes[i] = sum / Float(end - start)
        }

        // Normalize to 0...1 range
        let maxAmplitude = amplitudes.max() ?? 1
        if maxAmplitude > 0 {
            amplitudes = amplitudes.map { min($0 / maxAmplitude, 1.0) }
        }

        // Apply a minimum floor so silent sections still show small bars
        amplitudes = amplitudes.map { max($0, 0.08) }

        return amplitudes
    }

    /// Fallback amplitudes when audio parsing fails.
    nonisolated private static func fallbackAmplitudes(count: Int) -> [Float] {
        (0..<count).map { i in
            let t = Float(i) / Float(count)
            return 0.2 + 0.6 * abs(sin(t * .pi * 3))
        }
    }

    // MARK: - Timers

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                self.recordingTime = self.audioRecorder?.currentTime ?? 0

                // Read live audio level
                self.audioRecorder?.updateMeters()
                let db = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                // Convert dB to 0...1 linear scale (-60dB floor)
                let linear = Self.dbToLinear(db)
                self.currentLevel = linear
                self.levelHistory.append(linear)
                if self.levelHistory.count > Self.maxLevelHistory {
                    self.levelHistory.removeFirst()
                }

                if self.recordingTime >= Self.maxDuration {
                    let _ = self.stopRecording()
                }
            }
        }
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let player = self.audioPlayer, player.isPlaying {
                    self.playbackTime = player.currentTime
                    player.updateMeters()
                    let db = player.averagePower(forChannel: 0)
                    self.currentLevel = Self.dbToLinear(db)
                } else {
                    self.stopPlayback()
                }
            }
        }
    }

    /// Converts decibels to a 0...1 linear scale with a -60dB floor.
    private static func dbToLinear(_ db: Float) -> Float {
        let minDb: Float = -60
        guard db > minDb else { return 0 }
        return max(0, min(1, (db - minDb) / (0 - minDb)))
    }

    // MARK: - Cleanup

    private func cleanupTempFile() {
        if let url = tempURL {
            try? FileManager.default.removeItem(at: url)
            tempURL = nil
        }
    }

    deinit {
        recordingTimer?.invalidate()
        playbackTimer?.invalidate()
        if let url = tempURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
