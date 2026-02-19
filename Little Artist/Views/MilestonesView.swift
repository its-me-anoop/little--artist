//
//  MilestonesView.swift
//  Little Artist
//
//  Statistics dashboard showing total artwork count, capture streaks,
//  achievement badges, and per-child breakdowns.
//

import SwiftUI
import SwiftData

struct MilestonesView: View {
    @Query(sort: \Child.createdAt) private var children: [Child]
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]

    private var totalArtworks: Int { artworks.count }
    private var childCount: Int { children.count }

    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date.now
        return artworks.filter { calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month) }.count
    }

    private var nextMilestone: Int {
        let milestones = [10, 25, 50, 100, 250, 500]
        return milestones.first(where: { $0 > totalArtworks }) ?? (totalArtworks + 50)
    }

    private var achievements: [Achievement] {
        let calendar = Calendar.current
        let uniqueMonths = Set(artworks.map {
            calendar.dateComponents([.year, .month], from: $0.createdAt)
        }).count
        let favoritedCount = artworks.filter(\.isFavorited).count

        return [
            Achievement(name: "First Steps", icon: "star.fill", current: min(totalArtworks, 1), target: 1, description: "Save your first artwork"),
            Achievement(name: "Prolific", icon: "paintbrush.fill", current: min(totalArtworks, 10), target: 10, description: "Save 10 artworks"),
            Achievement(name: "Gallery", icon: "photo.stack.fill", current: min(totalArtworks, 25), target: 25, description: "Save 25 artworks"),
            Achievement(name: "Rainbow", icon: "figure.child", current: min(childCount, 3), target: 3, description: "Artwork from 3 children"),
            Achievement(name: "Collector", icon: "heart.fill", current: min(favoritedCount, 5), target: 5, description: "Favorite 5 artworks"),
            Achievement(name: "Time Capsule", icon: "clock.fill", current: min(uniqueMonths, 12), target: 12, description: "Artwork spanning 12 months"),
        ]
    }

    private func artworkCount(for child: Child) -> Int {
        child.artworks?.count ?? 0
    }

    var body: some View {
        NavigationStack {
            Group {
                if artworks.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Milestones")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 60, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.6))
            Text("No milestones yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text("Capture your first artwork\nto start tracking milestones.")
                .font(Brand.subheadlineFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Brand.gallerySpacing) {
                // Hero stat card
                VStack(spacing: 12) {
                    Image(systemName: "paintpalette.fill")
                        .font(.title)
                        .foregroundStyle(Brand.primary)

                    Text("\(totalArtworks)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("Total Artworks")
                        .font(Brand.subheadlineFont)
                        .foregroundStyle(.secondary)

                    // Progress bar to next milestone
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Brand.softTan.opacity(0.5))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Brand.primary)
                                    .frame(width: geo.size.width * CGFloat(totalArtworks) / CGFloat(nextMilestone), height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("Next: \(nextMilestone)")
                            .font(Brand.caption2Font)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                .brandCardShadow()
                .padding(.horizontal, Brand.screenPadding)

                // 2x2 stat grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    StatCardView(icon: "figure.child", label: "Artists", value: "\(childCount)")
                    StatCardView(icon: "calendar", label: "This Month", value: "\(thisMonthCount)")
                    StatCardView(icon: "heart.fill", label: "Favorites", value: "\(artworks.filter(\.isFavorited).count)")
                    StatCardView(icon: "trophy.fill", label: "Badges", value: "\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                }
                .padding(.horizontal, Brand.screenPadding)

                // Achievements
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(Brand.title3Font)
                        .padding(.horizontal, Brand.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(achievements) { achievement in
                                AchievementBadgeView(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Per child breakdown
                if !children.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per Child")
                            .font(Brand.title3Font)
                            .padding(.horizontal, Brand.screenPadding)

                        VStack(spacing: 0) {
                            ForEach(children) { child in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(hex: child.avatarColor))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            Text(String(child.name.prefix(1)).uppercased())
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                        }

                                    Text(child.name)
                                        .font(Brand.subheadlineFont.weight(.medium))

                                    Spacer()

                                    Text("\(artworkCount(for: child))")
                                        .font(Brand.subheadlineFont)
                                        .foregroundStyle(.secondary)

                                    Image(systemName: "photo.on.rectangle")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if child.persistentModelID != children.last?.persistentModelID {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.vertical, Brand.screenPadding)
        }
    }
}

#Preview("With Data") {
    MilestonesView()
        .modelContainer(PreviewSampleData.container)
}

#Preview("Empty") {
    MilestonesView()
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
