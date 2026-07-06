//
//  MilestoneCarouselView.swift
//  Little Artist
//
//  A horizontal scrolling carousel of MilestoneCardView items with a section header.
//

import SwiftUI
import SwiftData

/// A horizontal scrolling carousel of milestone achievement cards.
///
/// Displays a header row with a "View All" button and scrolls through
/// ``MilestoneCardView`` items for each achievement.
struct MilestoneCarouselView: View {

    // MARK: - Properties

    /// The achievements to display in the carousel.
    let achievements: [Achievement]
    /// Optional closure invoked when the user taps "View All".
    var onViewAll: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Header
            HStack {
                Text("Milestones")
                    .font(Brand.headlineFont)
                    .foregroundStyle(Brand.charcoal)

                Spacer()

                if let viewAll = onViewAll {
                    Button("View All", action: viewAll)
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.primary)
                }
            }
            .padding(.horizontal, Brand.screenPadding)

            // MARK: Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        MilestoneCardView(achievement: achievement)
                    }
                }
                .padding(.horizontal, Brand.screenPadding)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MilestoneCarouselView(
        achievements: [
            Achievement(
                identifier: "first-artwork",
                title: "First Steps",
                subtitle: "Save your first artwork",
                iconName: "star.fill",
                isEarned: true,
                earnedAt: Date(),
                category: "artwork"
            ),
            Achievement(
                identifier: "prolific",
                title: "Prolific Artist",
                subtitle: "Save 10 artworks",
                iconName: "paintbrush.fill",
                isEarned: false,
                category: "artwork"
            ),
            Achievement(
                identifier: "storyteller",
                title: "Storyteller",
                subtitle: "Add a voice story",
                iconName: "mic.fill",
                isEarned: true,
                earnedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                category: "voice"
            ),
        ],
        onViewAll: {}
    )
    .padding(.vertical)
    .background(Brand.cream)
}
