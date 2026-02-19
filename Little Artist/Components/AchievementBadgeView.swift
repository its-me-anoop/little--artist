//
//  AchievementBadgeView.swift
//  Little Artist
//
//  A circular badge with a progress ring showing completion
//  toward an achievement milestone.
//

import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let current: Int
    let target: Int
    let description: String

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var isUnlocked: Bool { current >= target }
}

struct AchievementBadgeView: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Brand.softTan, lineWidth: 3)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: achievement.progress)
                    .stroke(Brand.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                // Icon
                if achievement.isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.title3)
                        .foregroundStyle(Brand.primary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Brand.warmGray)
                }
            }

            Text(achievement.name)
                .font(Brand.caption2Font.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

            Text("\(Int(achievement.progress * 100))%")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.name), \(Int(achievement.progress * 100))% complete")
        .accessibilityHint("Double tap for details")
    }
}

#Preview {
    HStack {
        AchievementBadgeView(achievement: Achievement(
            name: "First Steps", icon: "star.fill",
            current: 1, target: 1, description: "Save your first artwork"
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Prolific", icon: "paintbrush.fill",
            current: 7, target: 10, description: "Save 10 artworks"
        ))
        AchievementBadgeView(achievement: Achievement(
            name: "Time Capsule", icon: "clock.fill",
            current: 3, target: 12, description: "Artwork spanning 12 months"
        ))
    }
    .padding()
}
