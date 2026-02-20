//
//  AIShimmerView.swift
//  Little Artist
//
//  An Apple Intelligence-style animated shimmer effect for AI processing states.
//  Features a multi-colour gradient that orbits and pulses around a rounded rectangle.
//

import SwiftUI

/// A glowing, orbiting gradient border effect inspired by Apple Intelligence.
///
/// Wraps any content in an animated border that shows a smoothly rotating
/// multi-colour gradient with a soft outer glow, used to indicate AI processing.
struct AIShimmerView<Content: View>: View {
    let isAnimating: Bool
    @ViewBuilder let content: () -> Content

    @State private var rotation: Double = 0
    @State private var glowOpacity: Double = 0.6

    private let gradientColors: [Color] = [
        Color(hex: "F2784B"),  // Brand primary (coral)
        Color(hex: "B8A9D4"),  // Lavender
        Color(hex: "7EB8DA"),  // Sky blue
        Color(hex: "A8C5A0"),  // Sage green
        Color(hex: "E8C94A"),  // Gold
        Color(hex: "F2784B"),  // Back to coral for smooth loop
    ]

    var body: some View {
        content()
            .overlay {
                if isAnimating {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            AngularGradient(
                                colors: gradientColors,
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 2.5
                        )
                        .blur(radius: 0.5)
                }
            }
            .background {
                if isAnimating {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            AngularGradient(
                                colors: gradientColors,
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 4
                        )
                        .blur(radius: 8)
                        .opacity(glowOpacity)
                }
            }
            .onChange(of: isAnimating) { _, animating in
                if animating {
                    startAnimations()
                }
            }
            .onAppear {
                if isAnimating {
                    startAnimations()
                }
            }
    }

    private func startAnimations() {
        // Continuous rotation
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        // Pulsing glow
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        AIShimmerView(isAnimating: true) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Brand.primary)
                Text("Generating Suggestions...")
                    .font(Brand.subheadlineFont.weight(.semibold))
            }
            .foregroundStyle(Brand.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Brand.primaryTint)
            )
        }
        .padding(.horizontal, 32)

        AIShimmerView(isAnimating: false) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Suggest Title & Caption")
                    .font(Brand.subheadlineFont.weight(.semibold))
            }
            .foregroundStyle(Brand.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Brand.primaryTint)
            )
        }
        .padding(.horizontal, 32)
    }
    .padding()
    .background(Color.black)
}
