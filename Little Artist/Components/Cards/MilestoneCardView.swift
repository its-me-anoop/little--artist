//
//  MilestoneCardView.swift
//  Little Artist
//
//  A compact card displaying a single Achievement milestone with icon, title, and status.
//

import SwiftUI
import SwiftData

/// A compact card displaying a single `Achievement` milestone.
///
/// Shows an icon circle in the achievement's accent color when earned,
/// or a locked state with a dimmed icon when not yet earned.
struct MilestoneCardView: View {

    // MARK: - Properties

    /// The achievement to display.
    let achievement: Achievement

    // MARK: - Computed

    private var accentColor: Color {
        switch achievement.category {
        case "artwork":    return Brand.primary
        case "voice":      return Brand.sky
        case "seasonal":   return Brand.sage
        case "medium":     return Brand.lavender
        case "engagement": return Brand.sky
        default:           return Brand.warmGray
        }
    }

    private var earnedDateText: String? {
        guard let date = achievement.earnedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            // MARK: Icon Circle
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? accentColor.opacity(0.15) : Brand.softTan.opacity(0.5))
                    .frame(width: 40, height: 40)

                Image(systemName: achievement.isEarned ? achievement.iconName : "lock.fill")
                    .font(.system(size: achievement.isEarned ? 18 : 14, weight: .semibold))
                    .foregroundStyle(achievement.isEarned ? accentColor : Brand.warmGray)
            }

            // MARK: Title
            Text(achievement.title)
                .font(Brand.captionFont.bold())
                .foregroundStyle(achievement.isEarned ? Brand.charcoal : Brand.warmGray)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            // MARK: Subtitle or Earned Date
            if achievement.isEarned, let dateText = earnedDateText {
                Text(dateText)
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
                    .lineLimit(1)
            } else {
                Text(achievement.subtitle)
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 150)
        .padding(Brand.fieldPadding)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .brandCardShadow()
        .opacity(achievement.isEarned ? 1.0 : 0.5)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        MilestoneCardView(achievement: Achievement(
            identifier: "first-artwork",
            title: "First Steps",
            subtitle: "Save your first artwork",
            iconName: "star.fill",
            isEarned: true,
            earnedAt: Date(),
            category: "artwork"
        ))
        MilestoneCardView(achievement: Achievement(
            identifier: "voice-story",
            title: "Storyteller",
            subtitle: "Add a voice story to artwork",
            iconName: "mic.fill",
            isEarned: false,
            category: "voice"
        ))
    }
    .padding()
    .background(Brand.cream)
}
