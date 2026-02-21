//
//  VoiceMemoRecorderView.swift
//  Little Artist
//
//  Inline voice memo recording control for the artwork capture flow.
//  Shows a mic button that toggles recording, an animated waveform
//  while recording, and playback/delete controls after capture.
//

import SwiftUI

/// An inline voice memo recorder with idle, recording, and recorded states.
///
/// The parent view owns the audio data via a `Binding`; this component
/// manages the recording lifecycle through ``AudioRecordingService``.
struct VoiceMemoRecorderView: View {
    /// The captured voice memo data. `nil` means no memo recorded.
    @Binding var voiceNoteData: Data?

    @StateObject private var audioService = AudioRecordingService()
    @State private var permissionDenied = false
    @State private var amplitudes: [Float] = []

    var body: some View {
        VStack(spacing: 12) {
            if let data = voiceNoteData {
                recordedMemoRow(data: data)
            } else if audioService.isRecording {
                recordingRow
            } else {
                idleRow
            }

            if permissionDenied {
                Text("Microphone access denied. Enable in Settings.")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.dustyRose)
                    .multilineTextAlignment(.center)
            }
        }
        .onChange(of: voiceNoteData) { _, newData in
            if let data = newData {
                Task.detached(priority: .userInitiated) {
                    let extracted = AudioRecordingService.extractAmplitudes(from: data, sampleCount: 48)
                    await MainActor.run { amplitudes = extracted }
                }
            } else {
                amplitudes = []
            }
        }
        .onAppear {
            if let data = voiceNoteData, amplitudes.isEmpty {
                Task.detached(priority: .userInitiated) {
                    let extracted = AudioRecordingService.extractAmplitudes(from: data, sampleCount: 48)
                    await MainActor.run { amplitudes = extracted }
                }
            }
        }
    }

    // MARK: - Idle State

    private var idleRow: some View {
        Button {
            Task {
                let granted = await audioService.startRecording()
                if !granted {
                    permissionDenied = true
                } else {
                    permissionDenied = false
                    HapticService.light()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                Text("Add Voice Memo")
                    .font(Brand.subheadlineFont.weight(.medium))
            }
            .foregroundStyle(Brand.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusButton)
                    .fill(Brand.primaryTint)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add voice memo")
        .accessibilityHint("Double tap to start recording, up to 30 seconds")
    }

    // MARK: - Recording State

    private var recordingRow: some View {
        HStack(spacing: 16) {
            // Cancel
            Button {
                audioService.cancelRecording()
                HapticService.light()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Brand.warmGray)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel recording")

            // Live waveform from microphone
            WaveformAnimationView(levels: audioService.levelHistory)
                .frame(height: 28)
                .frame(maxWidth: .infinity)

            // Timer
            Text(formatTime(audioService.recordingTime))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Brand.charcoal)
                .frame(width: 50, alignment: .trailing)

            // Stop
            Button {
                if let data = audioService.stopRecording() {
                    voiceNoteData = data
                    HapticService.success()
                }
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.dustyRose)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop recording")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusButton)
                .fill(Brand.dustyRose.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusButton)
                        .strokeBorder(Brand.dustyRose.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Recorded Memo

    private var playbackProgress: Double {
        guard audioService.playbackDuration > 0 else { return 0 }
        return audioService.playbackTime / audioService.playbackDuration
    }

    private func recordedMemoRow(data: Data) -> some View {
        HStack(spacing: 12) {
            // Bouncy play / stop
            Button {
                if audioService.isPlaying {
                    audioService.stopPlayback()
                } else {
                    audioService.play(data: data)
                }
                HapticService.selection()
            } label: {
                Image(systemName: audioService.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Brand.primary)
                    .clipShape(Circle())
                    .scaleEffect(audioService.isPlaying ? 1.0 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(audioService.isPlaying ? "Stop playback" : "Play voice memo")

            // Waveform from actual audio content
            VStack(alignment: .leading, spacing: 4) {
                PlaybackWaveformView(
                    amplitudes: amplitudes,
                    progress: playbackProgress,
                    isPlaying: audioService.isPlaying,
                    liveLevel: audioService.currentLevel
                )
                .frame(height: 28)

                Text("Voice memo recorded")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            // Delete
            Button {
                audioService.stopPlayback()
                voiceNoteData = nil
                HapticService.light()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Brand.dustyRose)
                    .frame(width: 36, height: 36)
                    .background(Brand.dustyRose.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete voice memo")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusButton)
                .fill(Brand.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusButton)
                        .strokeBorder(Brand.softTan, lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time) % 60
        let tenths = Int(time * 10) % 10
        return String(format: "0:%02d.%d", seconds, tenths)
    }
}

// MARK: - Preview

#Preview("Idle") {
    VoiceMemoRecorderView(voiceNoteData: .constant(nil))
        .padding()
}

#Preview("Recorded") {
    VoiceMemoRecorderView(voiceNoteData: .constant(Data(repeating: 0, count: 1024)))
        .padding()
}
