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

    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Tracks which achievements have already been celebrated (by name).
    @AppStorage("celebratedAchievements") private var celebratedAchievementsData: Data = Data()
    @State private var celebratingAchievement: Achievement?

    private var celebratedNames: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: celebratedAchievementsData)) ?? []
    }

    private func saveCelebrated(_ names: Set<String>) {
        celebratedAchievementsData = (try? JSONEncoder().encode(names)) ?? Data()
    }

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
            Achievement(name: "First Steps", icon: "star.fill", current: min(totalArtworks, 1), target: 1, description: "Save your first artwork", accentColor: Brand.primary),
            Achievement(name: "Prolific", icon: "paintbrush.fill", current: min(totalArtworks, 10), target: 10, description: "Save 10 artworks", accentColor: Brand.sage),
            Achievement(name: "Gallery", icon: "photo.stack.fill", current: min(totalArtworks, 25), target: 25, description: "Collect 25 masterpieces", accentColor: Brand.sky),
            Achievement(name: "Rainbow", icon: "figure.child", current: min(childCount, 3), target: 3, description: "3 little artists creating", accentColor: Brand.lavender),
            Achievement(name: "Collector", icon: "heart.fill", current: min(favoritedCount, 5), target: 5, description: "Favorite 5 artworks", accentColor: Brand.dustyRose),
            Achievement(name: "Time Capsule", icon: "clock.fill", current: min(uniqueMonths, 12), target: 12, description: "A year of creativity", accentColor: Color(hex: "E8C94A")),
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
            .background(BrandAppBackground())
            .toolbarBackground(Brand.backgroundBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay {
                if let achievement = celebratingAchievement {
                    AchievementCelebrationView(achievement: achievement) {
                        celebratingAchievement = nil
                    }
                }
            }
            .onAppear { checkForNewAchievements() }
            .onChange(of: artworks.count) { _, _ in checkForNewAchievements() }
            .onChange(of: children.count) { _, _ in checkForNewAchievements() }
        }
    }

    /// Checks if any achievement was newly unlocked and shows celebration.
    private func checkForNewAchievements() {
        let known = celebratedNames
        // Find the first unlocked achievement that hasn't been celebrated
        if let newAchievement = achievements.first(where: { $0.isUnlocked && !known.contains($0.name) }) {
            // Mark it celebrated immediately
            var updated = known
            updated.insert(newAchievement.name)
            saveCelebrated(updated)
            // Show celebration after a brief delay so the view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                celebratingAchievement = newAchievement
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            VStack(spacing: 14) {
                Image("LaunchFox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)

                Text("No milestones yet")
                    .font(Brand.title1Font)
                    .foregroundStyle(Brand.charcoal)
                    .multilineTextAlignment(.center)

                Text("Add your first artwork from Gallery to start tracking milestones.")
                    .font(Brand.title3Font)
                    .foregroundStyle(Brand.warmGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your achievements will appear here")
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Brand.glassStrong)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Brand.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Brand.glassStroke, lineWidth: 2)
            )
            .brandCardShadow()
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.large)
    }

    private var adaptivePadding: CGFloat {
        Brand.Adaptive.screenPadding(for: sizeClass)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Brand.Adaptive.gallerySpacing(for: sizeClass)) {
                // Hero stat card
                VStack(spacing: 12) {
                    Image("LaunchFox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                    Text("\(totalArtworks)")
                        .font(Brand.title1Font)
                        .foregroundStyle(Brand.charcoal)
                        .crayonStyle()

                    Text("Total Artworks")
                        .font(Brand.captionFont.bold())
                        .foregroundStyle(Brand.warmGray)
                        .crayonStyle()

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
                .frame(maxWidth: sizeClass == .regular ? Brand.Adaptive.maxContentWidth : .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Brand.glass)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Brand.glassStroke, lineWidth: 2)
                )
                .crayonStyle()
                .brandCardShadow()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, adaptivePadding)

                // Stat grid — 2 columns compact, 4 columns regular
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 12),
                        count: Brand.Adaptive.statGridColumns(for: sizeClass)
                    ),
                    spacing: 12
                ) {
                    StatCardView(icon: "figure.child", label: "Artists", value: "\(childCount)")
                    StatCardView(icon: "calendar", label: "This Month", value: "\(thisMonthCount)")
                    StatCardView(icon: "heart.fill", label: "Favorites", value: "\(artworks.filter(\.isFavorited).count)")
                    StatCardView(icon: "trophy.fill", label: "Badges", value: "\(achievements.filter(\.isUnlocked).count)/\(achievements.count)")
                }
                .padding(.horizontal, adaptivePadding)

                // Achievements
                VStack(alignment: .leading, spacing: 12) {
                    Text("Achievements")
                        .font(Brand.title2Font.bold())
                        .foregroundStyle(Brand.charcoal)
                        .crayonStyle()
                        .padding(.horizontal, adaptivePadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(achievements) { achievement in
                                AchievementBadgeView(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, adaptivePadding)
                        .padding(.vertical, 4)
                    }
                }

                // Per child breakdown
                if !children.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per Child")
                            .font(Brand.title2Font.bold())
                            .foregroundStyle(Brand.charcoal)
                            .crayonStyle()
                            .padding(.horizontal, adaptivePadding)

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
                                        .font(Brand.captionFont.bold())
                                        .foregroundStyle(Brand.charcoal)
                                        .crayonStyle()

                                    Spacer()

                                    Text("\(artworkCount(for: child))")
                                        .font(Brand.captionFont)
                                        .foregroundStyle(Brand.warmGray)

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
                        .frame(maxWidth: sizeClass == .regular ? Brand.Adaptive.maxContentWidth : .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(Brand.glass)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Brand.glassStroke, lineWidth: 2)
                        )
                        .crayonStyle()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, adaptivePadding)
                    }
                }
            }
            .padding(.vertical, adaptivePadding)
        }
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.large)
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
