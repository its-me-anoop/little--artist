//
//  WaveformAnimationView.swift
//  Little Artist
//
//  Animated colorful bars driven by real-time audio levels during recording.
//  Uses the avatar color palette for a playful, childlike feel.
//

import SwiftUI

/// Live waveform bars driven by actual microphone input levels.
///
/// Each bar represents a recent audio level sample. Bars use the avatar
/// color palette and animate with bouncy springs for a lively feel.
struct WaveformAnimationView: View {
    /// Rolling buffer of recent audio levels (0.0 to 1.0).
    var levels: [Float]
    /// Number of bars to display.
    var barCount: Int = 12

    // Avatar palette colors
    private let barColors: [Color] = [
        Color(hex: "F2784B"), // coral
        Color(hex: "A8C5A0"), // sage
        Color(hex: "7EB8DA"), // sky
        Color(hex: "B8A9D4"), // lavender
        Color(hex: "E8C94A"), // gold
        Color(hex: "D4928A"), // rose
        Color(hex: "7BC8B5"), // teal
    ]

    private let barWidth: CGFloat = 4
    private let minBarFraction: CGFloat = 0.12

    var body: some View {
        GeometryReader { geo in
            let maxHeight = geo.size.height
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let level = barLevel(for: index)
                    let height = max(maxHeight * CGFloat(level), maxHeight * minBarFraction)
                    let color = barColors[index % barColors.count]

                    Capsule()
                        .fill(color)
                        .frame(width: barWidth, height: height)
                        .animation(
                            .spring(duration: 0.15, bounce: 0.3),
                            value: level
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .accessibilityHidden(true)
    }

    /// Maps bar index to a level from the history buffer.
    private func barLevel(for index: Int) -> Float {
        guard !levels.isEmpty else { return 0.08 }

        // Distribute the level history across the bars
        let levelsCount = levels.count
        if levelsCount >= barCount {
            // More samples than bars: pick the proportional sample
            let sampleIndex = Int(Float(index) / Float(barCount) * Float(levelsCount))
            return levels[min(sampleIndex, levelsCount - 1)]
        } else {
            // Fewer samples than bars: fill from the right, empty bars get minimum
            let offset = barCount - levelsCount
            if index >= offset {
                return levels[index - offset]
            } else {
                return 0.08
            }
        }
    }
}

// MARK: - Preview

#Preview("With levels") {
    WaveformAnimationView(
        levels: [0.1, 0.3, 0.6, 0.9, 0.5, 0.7, 0.4, 0.8, 0.3, 0.6, 0.2, 0.5]
    )
    .frame(height: 32)
    .padding()
    .background(Brand.dustyRose.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
}

#Preview("Empty") {
    WaveformAnimationView(levels: [])
        .frame(height: 32)
        .padding()
}
