//
//  ArtworkGalleryView.swift
//  Little Artist
//
//  A Photos-style image grid with pinch-to-resize thumbnails,
//  sort order, and favorites filter.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// Displays a collection of artworks in a Photos-style grid.
///
/// Supports dynamic column count (pinch or toolbar toggle),
/// sort order, and a favorites-only filter.
struct ArtworkGalleryView: View {
    let artworks: [Artwork]

    /// When set, tapping a tile calls this callback instead of pushing a NavigationLink (iPad master-detail).
    var onSelect: ((Artwork) -> Void)? = nil
    /// The currently selected artwork's ID, used to highlight the tile in master-detail mode.
    var selectedArtworkID: PersistentIdentifier? = nil
    var topContent: AnyView? = nil

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var columnCount: Int?
    @State private var sortNewestFirst = true
    @State private var showFavoritesOnly = false
    @State private var controlsArePinned = false

    private let spacing: CGFloat = 3
    private let tileRadius: CGFloat = 4

    private var columnRange: ClosedRange<Int> {
        sizeClass == .regular ? 2...8 : 2...5
    }

    private func resolvedColumnCount(width: CGFloat) -> Int {
        columnCount ?? Brand.Adaptive.galleryColumns(for: width)
    }

    private func columns(for width: CGFloat) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: resolvedColumnCount(width: width))
    }

    private var displayedArtworks: [Artwork] {
        var result = artworks
        if showFavoritesOnly {
            result = result.filter(\.isFavorited)
        }
        return result.sorted { sortNewestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt }
    }

    /// Artworks grouped by year → month → date.
    private var groupedSections: [YearGroup] {
        let calendar = Calendar.current
        let dayBuckets = Dictionary(grouping: displayedArtworks) { artwork in
            ArtworkDate.dayKey(for: artwork.createdAt, calendar: calendar)
        }

        let sortedDays = dayBuckets.keys.sorted(by: sortNewestFirst ? (>) : (<))
        var yearGroups: [YearGroup] = []

        for day in sortedDays {
            let year = calendar.component(.year, from: day)
            let month = calendar.component(.month, from: day)
            let monthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: day)) ?? day
            let dayArtworks = (dayBuckets[day] ?? []).sorted {
                sortNewestFirst ? $0.createdAt > $1.createdAt : $0.createdAt < $1.createdAt
            }
            let dayGroup = DayGroup(date: day, artworks: dayArtworks)

            if yearGroups.last?.year != year {
                yearGroups.append(YearGroup(year: year, monthGroups: []))
            }

            let yearIndex = yearGroups.index(before: yearGroups.endIndex)
            if yearGroups[yearIndex].monthGroups.last?.month != month {
                yearGroups[yearIndex].monthGroups.append(
                    MonthGroup(month: month, date: monthDate, dayGroups: [])
                )
            }

            let monthIndex = yearGroups[yearIndex].monthGroups.index(before: yearGroups[yearIndex].monthGroups.endIndex)
            yearGroups[yearIndex].monthGroups[monthIndex].dayGroups.append(dayGroup)
        }

        return yearGroups
    }

    private var adaptivePadding: CGFloat {
        Brand.Adaptive.screenPadding(for: sizeClass)
    }

    private struct GridPreset: Identifiable {
        let title: String
        let columns: Int

        var id: Int { columns }
    }

    private var gridPresets: [GridPreset] {
        let presets: [GridPreset]

        if sizeClass == .regular {
            presets = [
                GridPreset(title: "Large", columns: 2),
                GridPreset(title: "Medium", columns: 4),
                GridPreset(title: "Small", columns: 6),
                GridPreset(title: "Tiny", columns: 8)
            ]
        } else {
            presets = [
                GridPreset(title: "Large", columns: 2),
                GridPreset(title: "Medium", columns: 3),
                GridPreset(title: "Small", columns: 4),
                GridPreset(title: "Tiny", columns: 5)
            ]
        }

        return presets.filter { columnRange.contains($0.columns) }
    }

    private func currentGridPreset(for width: CGFloat) -> GridPreset {
        let currentColumnCount = resolvedColumnCount(width: width)
        return gridPresets.min {
            abs($0.columns - currentColumnCount) < abs($1.columns - currentColumnCount)
        } ?? GridPreset(title: "Medium", columns: currentColumnCount)
    }

    private var sortLabel: String {
        sortNewestFirst ? "Newest first" : "Oldest first"
    }

    private var artworkCountLabel: String {
        let count = displayedArtworks.count
        return "\(count) \(count == 1 ? "piece" : "pieces")"
    }

    private func controlPill<Content: View>(
        isHighlighted: Bool = false,
        tint: Color = Brand.primary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        isHighlighted
                            ? AnyShapeStyle(tint.opacity(0.11).gradient)
                            : AnyShapeStyle(Brand.glass.gradient)
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isHighlighted ? tint.opacity(0.26) : Brand.glassStroke,
                        lineWidth: 1
                    )
            }
            .shadow(color: Brand.charcoal.opacity(0.035), radius: 6, x: 0, y: 2)
    }

    private var countPill: some View {
        controlPill(tint: Brand.primary) {
            Label(artworkCountLabel, systemImage: "photo.on.rectangle.angled")
                .font(Brand.captionFont.weight(.semibold))
                .foregroundStyle(Brand.warmGray)
        }
    }

    private var favoritesControl: some View {
        Button {
            withAnimation(.snappy) {
                showFavoritesOnly.toggle()
            }
        } label: {
            controlPill(isHighlighted: showFavoritesOnly, tint: Brand.dustyRose) {
                HStack(spacing: 8) {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Favorites")
                        .font(Brand.captionFont.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(showFavoritesOnly ? Brand.dustyRose : Brand.charcoal)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showFavoritesOnly ? "Favorites only on" : "Favorites only off")
    }

    private var sortControl: some View {
        Menu {
            Button {
                withAnimation(.snappy) {
                    sortNewestFirst = true
                }
            } label: {
                Label("Newest First", systemImage: sortNewestFirst ? "checkmark" : "")
            }

            Button {
                withAnimation(.snappy) {
                    sortNewestFirst = false
                }
            } label: {
                Label("Oldest First", systemImage: sortNewestFirst ? "" : "checkmark")
            }
        } label: {
            controlPill {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.primary)
                    Text(sortNewestFirst ? "Newest" : "Oldest")
                        .font(Brand.captionFont.bold())
                        .foregroundStyle(Brand.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Brand.warmGray)
                }
            }
        }
        .accessibilityLabel("Sort order, \(sortLabel)")
    }

    private func gridSizeControl(width: CGFloat) -> some View {
        let activePreset = currentGridPreset(for: width)

        return Menu {
            ForEach(gridPresets) { preset in
                Button {
                    withAnimation(.snappy) {
                        columnCount = preset.columns
                    }
                } label: {
                    Label(
                        preset.title,
                        systemImage: activePreset.columns == preset.columns ? "checkmark" : ""
                    )
                }
            }
        } label: {
            controlPill {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.primary)
                    Text(activePreset.title)
                        .font(Brand.captionFont.bold())
                        .foregroundStyle(Brand.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Brand.warmGray)
                }
            }
        }
        .accessibilityLabel("Grid size, \(activePreset.title)")
    }

    private func galleryControls(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                countPill
                favoritesControl
                sortControl
                gridSizeControl(width: width)
            }
            .padding(.horizontal, adaptivePadding)
            .padding(.vertical, 10)
        }
        .scrollClipDisabled()
        .background {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(controlsArePinned ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Brand.backgroundBase.opacity(0.96)))

                LinearGradient(
                    colors: [
                        Brand.backgroundBase.opacity(controlsArePinned ? 0.16 : 0),
                        Brand.backgroundBase.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                Rectangle()
                    .fill(controlsArePinned ? Brand.glassStroke : Brand.softTan.opacity(0.45))
                    .frame(height: 1)
            }
            .shadow(
                color: Brand.charcoal.opacity(controlsArePinned ? 0.08 : 0.02),
                radius: controlsArePinned ? 10 : 0,
                x: 0,
                y: controlsArePinned ? 6 : 0
            )
        }
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: [Color.clear, Brand.backgroundBase.opacity(0.95)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 24)
            .allowsHitTesting(false)
            .opacity(controlsArePinned ? 1 : 0.7)
        }
    }

    private var scrollTopTracker: some View {
        Color.clear
            .frame(height: 0)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: GalleryScrollOffsetKey.self,
                            value: geo.frame(in: .named("galleryScroll")).minY
                        )
                }
            )
    }

    private var emptyFavoritesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.4))
            Text("No favorites yet")
                .font(Brand.subheadlineFont.weight(.medium))
            Text("Tap the heart on an artwork to favorite it")
                .font(Brand.caption2Font)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func galleryContent(width: CGFloat, bottomInset: CGFloat) -> some View {
        LazyVStack(alignment: .leading, spacing: 22) {
            ForEach(groupedSections) { yearGroup in
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(yearGroup.year))
                        .font(Brand.title1Font)
                        .foregroundStyle(Brand.charcoal)
                        .crayonStyle()
                        .padding(.horizontal, adaptivePadding)

                    ForEach(yearGroup.monthGroups) { monthGroup in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Brand.primary.opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text(monthGroup.displayName)
                                    .font(Brand.headlineFont)
                                    .foregroundStyle(Brand.warmGray)
                                    .crayonStyle()
                            }
                            .padding(.horizontal, adaptivePadding)

                            ForEach(monthGroup.dayGroups) { dayGroup in
                                VStack(alignment: .leading, spacing: spacing) {
                                    Text(dayGroup.displayName)
                                        .font(Brand.captionFont.bold())
                                        .foregroundStyle(Brand.warmGray.opacity(0.7))
                                        .padding(.horizontal, adaptivePadding)
                                        .crayonStyle()

                                    LazyVGrid(columns: columns(for: width), spacing: spacing) {
                                        ForEach(dayGroup.artworks) { artwork in
                                            Group {
                                                if let onSelect {
                                                    Button {
                                                        onSelect(artwork)
                                                    } label: {
                                                        GalleryTile(artwork: artwork)
                                                    }
                                                    .buttonStyle(.plain)
                                                } else {
                                                    NavigationLink {
                                                        ArtworkDetailView(artwork: artwork)
                                                    } label: {
                                                        GalleryTile(artwork: artwork)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .overlay {
                                                if artwork.persistentModelID == selectedArtworkID {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .strokeBorder(Brand.primary, lineWidth: 3)
                                                }
                                            }
                                            .contextMenu {
                                                Button {
                                                    artwork.isFavorited.toggle()
                                                } label: {
                                                    Label(
                                                        artwork.isFavorited ? "Unfavorite" : "Favorite",
                                                        systemImage: artwork.isFavorited ? "heart.slash" : "heart"
                                                    )
                                                }
                                                ShareLink(
                                                    item: artwork.title.isEmpty ? "Artwork" : artwork.title,
                                                    preview: SharePreview(artwork.title.isEmpty ? "Artwork" : artwork.title)
                                                )
                                            } preview: {
                                                if let data = artwork.imageData, let uiImage = UIImage(data: data) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(uiImage.size, contentMode: .fit)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, spacing)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 80 + bottomInset)
    }

    private func galleryScrollBody(width: CGFloat, bottomInset: CGFloat) -> some View {
        ScrollView {
            scrollTopTracker

            if let topContent {
                topContent
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }

            if displayedArtworks.isEmpty && showFavoritesOnly {
                emptyFavoritesState
            } else {
                galleryContent(width: width, bottomInset: bottomInset)
            }
        }
        .coordinateSpace(name: "galleryScroll")
        .safeAreaInset(edge: .top, spacing: 0) {
            galleryControls(width: width)
        }
        .onPreferenceChange(GalleryScrollOffsetKey.self) { offset in
            let shouldPin = offset < -12
            guard shouldPin != controlsArePinned else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                controlsArePinned = shouldPin
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let bottomInset = geo.safeAreaInsets.bottom

            galleryScrollBody(width: width, bottomInset: bottomInset)
                .ignoresSafeArea(edges: .bottom)
                .gesture(
                    MagnifyGesture()
                        .onEnded { value in
                            withAnimation(.snappy) {
                                let current = resolvedColumnCount(width: width)
                                if value.magnification > 1.2 {
                                    columnCount = max(columnRange.lowerBound, current - 1)
                                } else if value.magnification < 0.8 {
                                    columnCount = min(columnRange.upperBound, current + 1)
                                }
                            }
                        }
                )
        }
    }
}

// MARK: - Grouping Models

private struct YearGroup: Identifiable {
    let year: Int
    var monthGroups: [MonthGroup]
    var id: Int { year }
}

private struct MonthGroup: Identifiable {
    let month: Int
    let date: Date
    var dayGroups: [DayGroup]
    var id: Date { date }

    var displayName: String {
        date.formatted(.dateTime.month(.wide))
    }
}

private struct DayGroup: Identifiable {
    let date: Date
    let artworks: [Artwork]
    var id: Date { date }

    var displayName: String {
        date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

private struct GalleryScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Gallery Tile

/// A single image tile for the gallery grid with soft corners and warm styling.
private struct GalleryTile: View {
    let artwork: Artwork

    private var accessibilityDescription: String {
        let title = artwork.title.isEmpty ? "Untitled" : artwork.title
        let childName = artwork.child?.name.map { "by \($0)" } ?? ""
        let date = artwork.createdAt.formatted(.dateTime.month(.abbreviated).day().year())
        return [title, childName, date].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let data = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Brand.surface)
                        .overlay {
                            Image("crayon_palette")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .opacity(0.5)
                        }
                }

                // Subtle bottom gradient for depth
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Favorite badge
                if artwork.isFavorited {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Brand.dustyRose.opacity(0.85))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Brand.warmGray.opacity(0.2), lineWidth: 2)
        )
        .overlay(alignment: .bottomLeading) {
            if artwork.voiceNoteData != nil {
                Image(systemName: "mic.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(Brand.primary.opacity(0.85))
                    .clipShape(Circle())
                    .padding(4)
            }
        }
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArtworkGalleryView(artworks: PreviewSampleData.sampleArtworks)
    }
    .modelContainer(PreviewSampleData.container)
}
