//
//  AchievementCelebrationView.swift
//  Little Artist
//
//  Full-screen celebration overlay shown when an achievement unlocks:
//  confetti, a springing achievement card, and a success haptic.
//

import SwiftUI

/// Celebrates a newly earned achievement with confetti and a card that
/// springs into view. Auto-dismisses after a few seconds, or on tap.
struct AchievementCelebrationView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cardVisible = false

    var body: some View {
        ZStack {
            Brand.charcoal.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if !reduceMotion {
                ConfettiBurstView()
                    .ignoresSafeArea()
            }

            // Achievement card
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Brand.primaryTint)
                        .frame(width: 88, height: 88)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Brand.primary)
                        .symbolEffect(.bounce, options: .nonRepeating, value: !reduceMotion && cardVisible)
                }

                Text("Achievement Unlocked")
                    .font(Brand.caption2Font.bold())
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Brand.warmGray)

                Text(achievement.title)
                    .font(Brand.title2Font)
                    .foregroundStyle(Brand.charcoal)
                    .multilineTextAlignment(.center)

                Text(achievement.subtitle)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.warmGray)
                    .multilineTextAlignment(.center)

                Button {
                    onDismiss()
                } label: {
                    Text("Hooray!")
                        .font(Brand.headlineFont)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 12)
                        .background(Brand.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
            }
            .padding(Brand.formPadding)
            .frame(maxWidth: 340)
            .background(
                Brand.surface,
                in: RoundedRectangle(cornerRadius: Brand.radiusSheet, style: .continuous)
            )
            .brandCardShadow()
            .padding(.horizontal, Brand.formPadding)
            .scaleEffect(cardVisible || reduceMotion ? 1 : 0.7)
            .opacity(cardVisible ? 1 : 0)
        }
        .onAppear {
            HapticService.success()
            withAnimation(
                reduceMotion
                    ? .easeOut(duration: 0.25)
                    : .spring(duration: 0.55, bounce: 0.35)
            ) {
                cardVisible = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(5))
            onDismiss()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Achievement unlocked: \(achievement.title). \(achievement.subtitle)")
    }
}

// MARK: - Preview

#Preview {
    AchievementCelebrationView(
        achievement: Achievement(
            identifier: "first_masterpiece",
            title: "First Masterpiece",
            subtitle: "The journey begins!",
            iconName: "star.fill",
            category: "artwork"
        ),
        onDismiss: {}
    )
}
