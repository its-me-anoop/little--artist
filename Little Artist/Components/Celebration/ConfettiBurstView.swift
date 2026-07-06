//
//  ConfettiBurstView.swift
//  Little Artist
//
//  A one-shot confetti burst drawn with Canvas. Pieces fall, sway, and
//  spin using only transforms and opacity, then the view goes quiet.
//

import SwiftUI

/// A celebratory burst of brand-coloured confetti falling from the top
/// of the screen. Purely decorative — callers should skip it when
/// `accessibilityReduceMotion` is on.
struct ConfettiBurstView: View {

    /// One piece of confetti with all randomness decided up front.
    private struct Piece {
        let xFraction: CGFloat
        let delay: Double
        let fallDuration: Double
        let swayAmplitude: CGFloat
        let swayPhase: Double
        let spinSpeed: Double
        let width: CGFloat
        let height: CGFloat
        let color: Color
    }

    private let pieces: [Piece]
    private let startDate = Date()

    init(pieceCount: Int = 90) {
        let palette = Brand.avatarColors.map { Color(hex: $0) }
        pieces = (0..<pieceCount).map { _ in
            Piece(
                xFraction: CGFloat.random(in: 0.02...0.98),
                delay: Double.random(in: 0...0.7),
                fallDuration: Double.random(in: 2.1...3.2),
                swayAmplitude: CGFloat.random(in: 12...42),
                swayPhase: Double.random(in: 0...(2 * .pi)),
                spinSpeed: Double.random(in: 1.2...3.4),
                width: CGFloat.random(in: 6...11),
                height: CGFloat.random(in: 9...16),
                color: palette.randomElement() ?? Brand.primary
            )
        }
    }

    var body: some View {
        // Fully qualified: the app's own `TimelineView` screen shadows SwiftUI's.
        SwiftUI.TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)

                for piece in pieces {
                    let progress = (elapsed - piece.delay) / piece.fallDuration
                    guard progress > 0, progress < 1 else { continue }

                    let sway = sin(elapsed * 3 + piece.swayPhase) * piece.swayAmplitude
                    let x = piece.xFraction * size.width + sway
                    let y = -20 + progress * (size.height + 40)
                    let rotation = Angle.radians(elapsed * piece.spinSpeed * 2 * .pi)
                    // Fade out over the last quarter of the fall.
                    let opacity = progress > 0.75 ? (1 - progress) / 0.25 : 1

                    var pieceContext = context
                    pieceContext.opacity = opacity
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: rotation)
                    let rect = CGRect(
                        x: -piece.width / 2,
                        y: -piece.height / 2,
                        width: piece.width,
                        height: piece.height
                    )
                    pieceContext.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(piece.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Brand.cream.ignoresSafeArea()
        ConfettiBurstView()
    }
}
