//
//  ChildProfileView.swift
//  Little Artist
//
//  A child's profile page showing avatar hero, stats, milestones carousel,
//  and a scoped artwork timeline grouped by time period.
//

import SwiftUI
import SwiftData

/// Displays a child's profile with stats, milestones, and scoped artwork timeline.
///
/// Pushed from child avatars or cards. Shows a large avatar hero, stat pills,
/// a milestones carousel, and a chronological artwork feed filtered to this child.
struct ChildProfileView: View {

    // MARK: - Properties

    let child: Child

    @Query private var achievements: [Achievement]
    @State private var showEditSheet = false

    // MARK: - Computed Properties

    private var childArtworks: [Artwork] {
        (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    private var artworkCount: Int { childArtworks.count }

    private var level: Int { artworkCount / 10 + 1 }

    private var artistSinceYear: String {
        child.createdAt.formatted(.dateTime.year())
    }

    /// Timeline dot colors that cycle across groups.
    private let dotColors: [Color] = [Brand.primary, Brand.sky, Brand.lavender]

    // MARK: - Grouping

    private var groupedArtworks: [(title: String, subtitle: String, artworks: [Artwork])] {
        let calendar = Calendar.current
        let now = Date.now
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        var groups: [(title: String, subtitle: String, artworks: [Artwork])] = []
        var remaining = childArtworks

        // Today
        let today = remaining.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
        if !today.isEmpty {
            let subtitle = todayStart.formatted(.dateTime.month(.abbreviated).day())
            groups.append(("Today", subtitle, today))
            let todayIDs = Set(today.map(\.persistentModelID))
            remaining.removeAll { todayIDs.contains($0.persistentModelID) }
        }

        // This Week
        let thisWeek = remaining.filter { $0.createdAt >= weekStart }
        if !thisWeek.isEmpty {
            groups.append(("This Week", "", thisWeek))
            let weekIDs = Set(thisWeek.map(\.persistentModelID))
            remaining.removeAll { weekIDs.contains($0.persistentModelID) }
        }

        // This Month
        let thisMonth = remaining.filter { $0.createdAt >= monthStart }
        if !thisMonth.isEmpty {
            groups.append(("This Month", "", thisMonth))
            let monthIDs = Set(thisMonth.map(\.persistentModelID))
            remaining.removeAll { monthIDs.contains($0.persistentModelID) }
        }

        // By month
        let byMonth = Dictionary(grouping: remaining) { artwork in
            calendar.dateComponents([.year, .month], from: artwork.createdAt)
        }
        for key in byMonth.keys.sorted(by: { ($0.year!, $0.month!) > ($1.year!, $1.month!) }) {
            let artworks = byMonth[key]!
            let date = calendar.date(from: key)!
            groups.append((
                date.formatted(.dateTime.month(.wide).year()),
                "",
                artworks
            ))
        }

        return groups
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                // MARK: Profile Hero
                profileHero

                // MARK: Milestones
                if !achievements.isEmpty {
                    MilestoneCarouselView(
                        achievements: achievements,
                        onViewAll: nil
                    )
                }

                // MARK: Art Timeline
                if groupedArtworks.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .padding(.bottom, Brand.sectionSpacing)
        }
        .background(BrandAppBackground())
        .navigationTitle(child.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Brand.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditChildView(child: child)
        }
        .navigationDestination(for: Artwork.self) { artwork in
            ArtworkDetailView(artwork: artwork)
        }
    }

    // MARK: - Profile Hero

    private var profileHero: some View {
        VStack(spacing: 16) {
            // Avatar with accent shape
            ZStack {
                // Accent background shape
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(hex: child.avatarColor).opacity(0.2))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -8, y: 8)

                // Avatar
                if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .frame(width: 140, height: 140)
                        .overlay {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                }

                // Paint palette badge
                Circle()
                    .fill(Brand.primary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 50, y: 50)
                    .brandAvatarShadow()
            }
            .brandAvatarShadow()

            // Name
            Text(child.name)
                .font(Brand.displayFont)
                .foregroundStyle(Brand.charcoal)

            // Artist since
            Text("Artist since \(artistSinceYear)")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)

            // Stat pills
            HStack(spacing: 16) {
                StatPillView(
                    value: "\(artworkCount)",
                    label: "Artworks",
                    rotation: -1.5
                )
                StatPillView(
                    value: "Level \(level)",
                    label: "Creator",
                    rotation: 1.5
                )
            }
            .padding(.horizontal, Brand.screenPadding)
        }
        .padding(.top, 8)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(Brand.warmGray.opacity(0.6))

            Text("No artworks yet")
                .font(Brand.headlineFont)
                .foregroundStyle(Brand.charcoal)

            Text("Artworks will appear here in chronological order")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(groupedArtworks.enumerated()), id: \.offset) { index, group in
                timelineGroup(group, colorIndex: index)
            }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    // MARK: - Timeline Group

    @ViewBuilder
    private func timelineGroup(
        _ group: (title: String, subtitle: String, artworks: [Artwork]),
        colorIndex: Int
    ) -> some View {
        let dotColor = dotColors[colorIndex % dotColors.count]
        let isLast = colorIndex == groupedArtworks.count - 1

        HStack(alignment: .top, spacing: 16) {
            // Timeline rail
            VStack(spacing: 0) {
                // Dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 16, height: 16)

                // Line
                if !isLast {
                    Rectangle()
                        .fill(Brand.softTan)
                        .frame(width: 2)
                }
            }
            .frame(width: 16)

            // Group content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(Brand.headlineFont)
                        .foregroundStyle(Brand.charcoal)

                    if !group.subtitle.isEmpty {
                        Text(group.subtitle)
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.warmGray)
                    }
                }

                // Artwork grid
                let columns = [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ]

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(group.artworks.enumerated()), id: \.element.persistentModelID) { artworkIndex, artwork in
                        NavigationLink(value: artwork) {
                            BentoArtworkCardView(
                                artwork: artwork,
                                rotation: artworkIndex.isMultiple(of: 2) ? -1.5 : 1.5,
                                showTitle: true,
                                showVoiceMemoIndicator: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Voice memo entries
                ForEach(group.artworks.filter { $0.voiceNoteData != nil }, id: \.persistentModelID) { artwork in
                    voiceMemoCard(for: artwork)
                }

                // Bottom spacing between groups
                if !isLast {
                    Spacer()
                        .frame(height: Brand.gallerySpacing)
                }
            }
        }
    }

    // MARK: - Voice Memo Card

    private func voiceMemoCard(for artwork: Artwork) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Brand.primary)
                .frame(width: 32, height: 32)
                .background(Brand.primaryTint, in: Circle())

            // Waveform bars
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Brand.primary.opacity(0.5))
                        .frame(width: 3, height: waveformBarHeight(for: bar))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(artwork.title.isEmpty ? "Voice Story" : artwork.title)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.charcoal)
                    .lineLimit(1)

                Text(artwork.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()
        }
        .padding(12)
        .background(Brand.glass)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                .strokeBorder(Brand.glassStroke, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func waveformBarHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [8, 14, 10, 18, 12, 16, 9, 13]
        return heights[index % heights.count]
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChildProfileView(child: PreviewSampleData.emma)
    }
    .modelContainer(PreviewSampleData.container)
}
