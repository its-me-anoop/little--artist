//
//  PlaybackWaveformView.swift
//  Little Artist
//
//  A colorful waveform visualization for voice memo playback.
//  Bars represent actual audio amplitudes extracted from the recording.
//  Colors come from the avatar palette, with bouncy spring animations.
//

import SwiftUI

/// A playful waveform that visualizes voice memo playback with real audio data.
///
/// Bars ahead of the playhead are muted; played bars are vibrant and bounce
/// near the playhead for a lively, kid-friendly animation.
struct PlaybackWaveformView: View {
    /// Normalized amplitude values (0.0 to 1.0) extracted from audio data.
    var amplitudes: [Float]
    /// Playback progress from 0.0 to 1.0.
    var progress: Double = 0
    /// Whether audio is currently playing.
    var isPlaying: Bool = false
    /// Current live playback level (0.0 to 1.0) for the active bar pulse.
    var liveLevel: Float = 0

    private let barWidth: CGFloat = 4
    private let barSpacing: CGFloat = 3
    private let minBarFraction: CGFloat = 0.08

    // Colorful palette from the brand avatar colors
    private let barColors: [Color] = [
        Color(hex: "F2784B"), // coral
        Color(hex: "A8C5A0"), // sage
        Color(hex: "7EB8DA"), // sky
        Color(hex: "B8A9D4"), // lavender
        Color(hex: "E8C94A"), // gold
        Color(hex: "D4928A"), // rose
        Color(hex: "7BC8B5"), // teal
    ]

    var body: some View {
        GeometryReader { geo in
            let barCount = max(1, Int(geo.size.width / (barWidth + barSpacing)))
            let resampled = resampleAmplitudes(to: barCount)
            let maxBarHeight = geo.size.height

            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    let normalizedPosition = Double(index) / Double(barCount)
                    let isPlayed = normalizedPosition < progress
                    let isNearPlayhead = isPlaying && abs(normalizedPosition - progress) < (1.0 / Double(barCount) * 1.5)
                    let color = barColors[index % barColors.count]

                    // Bar height from actual amplitude, with minimum floor
                    let amplitude = CGFloat(resampled[index])
                    let baseHeight = max(amplitude * maxBarHeight, maxBarHeight * minBarFraction)

                    // Pulse effect near playhead using live level
                    let pulseScale: CGFloat = isNearPlayhead ? 1.0 + CGFloat(liveLevel) * 0.25 : 1.0

                    Capsule()
                        .fill(isPlayed ? color : color.opacity(0.2))
                        .frame(width: barWidth, height: baseHeight)
                        .scaleEffect(y: pulseScale, anchor: .center)
                        .animation(
                            isPlaying
                                ? .spring(duration: 0.2, bounce: 0.4)
                                : .easeOut(duration: 0.3),
                            value: isPlayed
                        )
                        .animation(
                            .spring(duration: 0.1, bounce: 0.3),
                            value: pulseScale
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    /// Resamples the source amplitudes to fit the target bar count.
    private func resampleAmplitudes(to count: Int) -> [Float] {
        guard !amplitudes.isEmpty else {
            return Array(repeating: 0.08, count: count)
        }
        if amplitudes.count == count { return amplitudes }
        return (0..<count).map { index in
            let position = Float(index) / Float(count) * Float(amplitudes.count)
            let lower = min(Int(position), amplitudes.count - 1)
            let upper = min(lower + 1, amplitudes.count - 1)
            let fraction = position - Float(lower)
            return amplitudes[lower] * (1 - fraction) + amplitudes[upper] * fraction
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    PlaybackWaveformView(
        amplitudes: [0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 1.0, 0.5, 0.7,
                     0.85, 0.4, 0.6, 0.95, 0.3, 0.7, 0.5, 0.8, 0.45, 0.6,
                     0.55, 0.75, 0.4, 0.65, 0.8, 0.5, 0.9, 0.35, 0.7, 0.6],
        progress: 0,
        isPlaying: false
    )
    .frame(height: 32)
    .padding()
}

#Preview("Playing") {
    PlaybackWaveformView(
        amplitudes: [0.3, 0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 1.0, 0.5, 0.7,
                     0.85, 0.4, 0.6, 0.95, 0.3, 0.7, 0.5, 0.8, 0.45, 0.6,
                     0.55, 0.75, 0.4, 0.65, 0.8, 0.5, 0.9, 0.35, 0.7, 0.6],
        progress: 0.5,
        isPlaying: true,
        liveLevel: 0.6
    )
    .frame(height: 32)
    .padding()
}
