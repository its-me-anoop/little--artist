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
    var cornerRadius: CGFloat = 16
    @ViewBuilder let content: () -> Content

    @State private var borderRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.94
    @State private var sheenOffset: CGFloat = -220

    private let gradientColors: [Color] = [
        Color(hex: "F2784B"),  // Brand primary (coral)
        Color(hex: "B8A9D4"),  // Lavender
        Color(hex: "7EB8DA"),  // Sky blue
        Color(hex: "A8C5A0"),  // Sage green
        Color(hex: "E8C94A"),  // Gold
        Color(hex: "F2784B"),  // Back to coral for smooth loop
    ]

    private var shimmerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .overlay {
                if isAnimating {
                    animatedBorder
                }
            }
            .overlay {
                if isAnimating {
                    animatedSheen
                }
            }
            .background {
                if isAnimating {
                    animatedGlow
                }
            }
            .task(id: isAnimating) {
                if isAnimating {
                    startAnimations()
                } else {
                    resetAnimations()
                }
            }
            .onAppear {
                if isAnimating {
                    startAnimations()
                }
            }
    }

    private var animatedBorder: some View {
        shimmerShape
            .strokeBorder(
                AngularGradient(
                    colors: gradientColors,
                    center: .center,
                    angle: .degrees(borderRotation)
                ),
                lineWidth: 2.6
            )
            .overlay {
                shimmerShape
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8)
                    .blur(radius: 0.8)
            }
            .shadow(color: Color(hex: "F2784B").opacity(0.18), radius: 10)
            .shadow(color: Color(hex: "7EB8DA").opacity(0.14), radius: 18)
            .allowsHitTesting(false)
    }

    private var animatedGlow: some View {
        shimmerShape
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color(hex: "F2784B").opacity(0.15),
                        Color(hex: "7EB8DA").opacity(0.10),
                        .clear
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: 140
                )
            )
            .scaleEffect(glowScale)
            .blur(radius: 18)
            .opacity(glowOpacity)
            .padding(-10)
            .allowsHitTesting(false)
    }

    private var animatedSheen: some View {
        shimmerShape
            .fill(Color.white.opacity(0.001))
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.26),
                        Color(hex: "7EB8DA").opacity(0.14),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(18))
                .scaleEffect(x: 1.7, y: 1.35)
                .offset(x: sheenOffset)
                .blur(radius: 6)
                .blendMode(.plusLighter)
            }
            .mask(shimmerShape)
            .allowsHitTesting(false)
    }

    private func startAnimations() {
        resetAnimations()

        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            borderRotation = 360
        }

        withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
            glowOpacity = 0.95
            glowScale = 1.06
        }

        withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: false)) {
            sheenOffset = 220
        }
    }

    private func resetAnimations() {
        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            borderRotation = 0
            glowOpacity = 0
            glowScale = 0.94
            sheenOffset = -220
        }
    }
}

/// Inline permission prompt shown when AI captions are disabled but the user
/// explicitly asks the app to generate or improve text.
struct AIPermissionRequestCardView: View {
    let title: String
    let message: String
    let actionTitle: String
    let onEnable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.primary)
                    .frame(width: 34, height: 34)
                    .background(Brand.primaryTint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Brand.subheadlineFont.weight(.semibold))
                        .foregroundStyle(Brand.charcoal)

                    Text(message)
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(actionTitle, action: onEnable)
                    .font(Brand.captionFont.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Brand.primary, in: Capsule())

                Button("Not Now", action: onDismiss)
                    .font(Brand.captionFont.weight(.semibold))
                    .foregroundStyle(Brand.warmGray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Brand.glassStrong, in: Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Brand.glassStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Brand.softTan, lineWidth: 1.2)
        )
        .brandCardShadow()
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
                RoundedRectangle(cornerRadius: 16)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(Brand.primaryTint)
            )
        }
        .padding(.horizontal, 32)
    }
    .padding()
    .background(Color.black)
}
