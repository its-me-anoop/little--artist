//
//  ConfettiView.swift
//  Little Artist
//
//  A full-screen confetti particle animation for celebrating achievements.
//  Spawns colorful shapes that fall with randomized physics.
//

import SwiftUI

/// A single confetti particle with randomized properties.
private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let isCircle: Bool
    let size: CGFloat
    let startX: CGFloat
    let spinSpeed: Double
    let fallDuration: Double
    let swayAmount: CGFloat
    let delay: Double
}

/// Full-screen confetti burst animation.
struct ConfettiView: View {
    let isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var animate = false

    private let colors: [Color] = [
        Brand.primary,
        Brand.sage,
        Brand.sky,
        Brand.lavender,
        Color(hex: "E8C94A"),
        Brand.dustyRose,
        Color(hex: "7BC8B5"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(
                        particle: particle,
                        animate: animate,
                        containerWidth: geo.size.width,
                        containerHeight: geo.size.height
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active {
                    spawnParticles(in: geo.size)
                }
            }
            .onAppear {
                if isActive {
                    spawnParticles(in: geo.size)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func spawnParticles(in size: CGSize) {
        animate = false
        particles = (0..<60).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? Brand.primary,
                isCircle: Bool.random(),
                size: CGFloat.random(in: 6...14),
                startX: CGFloat.random(in: 0...size.width),
                spinSpeed: Double.random(in: 2...6),
                fallDuration: Double.random(in: 2.5...4.5),
                swayAmount: CGFloat.random(in: -60...60),
                delay: Double.random(in: 0...0.6)
            )
        }

        // Trigger animations on next frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animate = true
        }
    }
}

/// Renders and animates a single confetti particle.
private struct ParticleView: View {
    let particle: ConfettiParticle
    let animate: Bool
    let containerWidth: CGFloat
    let containerHeight: CGFloat

    @State private var rotation: Double = 0
    @State private var yOffset: CGFloat = -20
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Group {
            if particle.isCircle {
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.5)
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0.5, z: 0.3))
        .offset(x: particle.startX + xOffset - containerWidth / 2, y: yOffset)
        .opacity(opacity)
        .onChange(of: animate) { _, active in
            if active {
                rotation = 0
                yOffset = -20
                xOffset = 0
                opacity = 1
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: particle.spinSpeed).repeatForever(autoreverses: false).delay(particle.delay)) {
            rotation = 360
        }
        withAnimation(.easeIn(duration: particle.fallDuration).delay(particle.delay)) {
            yOffset = containerHeight + 40
            xOffset = particle.swayAmount
        }
        withAnimation(.easeIn(duration: 1.0).delay(particle.delay + particle.fallDuration * 0.6)) {
            opacity = 0
        }
    }
}

// MARK: - Achievement Celebration Overlay

/// A modal overlay celebrating a newly unlocked achievement with confetti.
struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Confetti
            ConfettiView(isActive: showConfetti)

            // Card
            VStack(spacing: 20) {
                // Badge
                ZStack {
                    Circle()
                        .fill(achievement.accentColor.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(achievement.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(achievement.accentColor)
                        .symbolEffect(.bounce, value: showContent)
                }

                Text("Achievement Unlocked!")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(achievement.accentColor)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(achievement.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(achievement.description)
                    .font(Brand.subheadlineFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .font(Brand.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(achievement.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(28)
            .padding(.top, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(achievement.accentColor.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)
            .scaleEffect(showContent ? 1 : 0.7)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
            HapticService.success()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AchievementCelebrationView(
        achievement: Achievement(
            name: "First Steps",
            icon: "star.fill",
            current: 1,
            target: 1,
            description: "You saved your first artwork!",
            accentColor: Brand.primary
        )
    ) {}
}
