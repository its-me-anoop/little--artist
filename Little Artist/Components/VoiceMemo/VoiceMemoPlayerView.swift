//
//  VoiceMemoPlayerView.swift
//  Little Artist
//
//  Compact inline audio player for voice memos attached to artwork.
//  Shows a waveform derived from actual audio content with playful animations.
//

import SwiftUI

/// A read-only voice memo player with real audio waveform and bouncy controls.
struct VoiceMemoPlayerView: View {
    let audioData: Data

    @StateObject private var audioService = AudioRecordingService()
    @State private var amplitudes: [Float] = []
    @State private var buttonBounce = false

    private var progress: Double {
        guard audioService.playbackDuration > 0 else { return 0 }
        return audioService.playbackTime / audioService.playbackDuration
    }

    var body: some View {
        HStack(spacing: 12) {
            // Bouncy play / stop button
            Button {
                if audioService.isPlaying {
                    audioService.stopPlayback()
                } else {
                    audioService.play(data: audioData)
                }
                HapticService.selection()
                triggerBounce()
            } label: {
                Image(systemName: audioService.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Brand.primary))
                    .overlay {
                        if audioService.isPlaying {
                            Circle()
                                .strokeBorder(Brand.primary.opacity(0.3), lineWidth: 2)
                                .frame(width: 44, height: 44)
                                .scaleEffect(buttonBounce ? 1.2 : 1.0)
                                .opacity(buttonBounce ? 0 : 0.6)
                                .animation(
                                    .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                    value: buttonBounce
                                )
                        }
                    }
                    .scaleEffect(buttonBounce ? 0.85 : 1.0)
                    .animation(.spring(duration: 0.3, bounce: 0.5), value: buttonBounce)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(audioService.isPlaying ? "Stop voice memo" : "Play voice memo")

            // Waveform from actual audio content
            PlaybackWaveformView(
                amplitudes: amplitudes,
                progress: progress,
                isPlaying: audioService.isPlaying,
                liveLevel: audioService.currentLevel
            )
            .frame(height: 32)

            // Duration
            Text(formatDuration(audioService.isPlaying ? audioService.playbackTime : audioService.playbackDuration))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(audioService.isPlaying ? Brand.primary : Brand.warmGray)
                .frame(width: 36, alignment: .trailing)
                .animation(.easeInOut(duration: 0.2), value: audioService.isPlaying)
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
        .onAppear {
            extractAmplitudes()
        }
        .onDisappear {
            audioService.stopPlayback()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voice memo")
        .accessibilityHint("Double tap to play or stop")
    }

    private func extractAmplitudes() {
        Task.detached(priority: .userInitiated) {
            let extracted = AudioRecordingService.extractAmplitudes(from: audioData, sampleCount: 48)
            await MainActor.run {
                amplitudes = extracted
            }
        }
    }

    private func triggerBounce() {
        buttonBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            buttonBounce = false
        }
    }

    private func formatDuration(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return String(format: "0:%02d", seconds)
    }
}

// MARK: - Preview

#Preview {
    VoiceMemoPlayerView(audioData: Data())
        .padding()
}
