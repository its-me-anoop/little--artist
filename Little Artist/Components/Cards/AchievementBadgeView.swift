//
//  AchievementBadgeView.swift
//  Little Artist
//
//  A rich achievement badge card with animated progress ring,
//  gradient fills, and unlock state.
//

import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let current: Int
    let target: Int
    let description: String
    let accentColor: Color

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var isUnlocked: Bool { current >= target }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            // Badge circle with progress ring
            ZStack {
                // Outer glow for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                }

                // Background track
                Circle()
                    .stroke(
                        achievement.isUnlocked
                            ? achievement.accentColor.opacity(0.2)
                            : Color(.tertiarySystemFill),
                        lineWidth: 4
                    )
                    .frame(width: 64, height: 64)

                // Progress arc
                Circle()
                    .trim(from: 0, to: achievement.progress)
                    .stroke(
                        achievement.isUnlocked
                            ? achievement.accentColor
                            : achievement.accentColor.opacity(0.6),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                // Inner circle fill
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? achievement.accentColor.opacity(0.12)
                            : Color(.tertiarySystemFill).opacity(0.5)
                    )
                    .frame(width: 54, height: 54)

                // Icon
                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.system(size: achievement.isUnlocked ? 22 : 16, weight: .semibold))
                    .foregroundStyle(
                        achievement.isUnlocked
                            ? achievement.accentColor
                            : .secondary
                    )
                    .symbolEffect(.bounce, value: achievement.isUnlocked)
            }
            .frame(width: 80, height: 80)

            // Name
            Text(achievement.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

            // Description or progress
            if achievement.isUnlocked {
                Text(achievement.description)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("\(achievement.current)/\(achievement.target)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 100)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    achievement.isUnlocked
                        ? achievement.accentColor.opacity(0.25)
                        : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.name), \(achievement.isUnlocked ? "unlocked" : "\(achievement.current) of \(achievement.target)")")
    }
}

#Preview {
    HStack(spacing: 12) {
        AchievementBadgeView(achievement: Achievement(
            name: "First Steps", icon: "star.fill",
            current: 1, target: 1, description: "Save your first artwork",
            accentColor: Brand.primary
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Prolific", icon: "paintbrush.fill",
            current: 7, target: 10, description: "Save 10 artworks",
            accentColor: Brand.sage
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Time Capsule", icon: "clock.fill",
            current: 3, target: 12, description: "12 months of art",
            accentColor: Brand.lavender
        ))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
