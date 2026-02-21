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

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var columnCount: Int?
    @State private var sortNewestFirst = true
    @State private var showFavoritesOnly = false
    @State private var availableWidth: CGFloat = 390

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
        let sorted = displayedArtworks

        // Group by year-month-day
        var yearMap: [Int: [Int: [Int: [Artwork]]]] = [:]
        for artwork in sorted {
            let comps = calendar.dateComponents([.year, .month, .day], from: artwork.createdAt)
            let y = comps.year ?? 0
            let m = comps.month ?? 0
            let d = comps.day ?? 0
            yearMap[y, default: [:]][m, default: [:]][d, default: []].append(artwork)
        }

        let descending: (Int, Int) -> Bool = { $0 > $1 }
        let ascending: (Int, Int) -> Bool = { $0 < $1 }
        let yearSort = sortNewestFirst ? descending : ascending
        let monthSort = yearSort
        let daySort = yearSort

        return yearMap.keys.sorted(by: yearSort).map { year in
            let months = yearMap[year, default: [:]]
            let monthGroups = months.keys.sorted(by: monthSort).map { month in
                let days = months[month, default: [:]]
                let dayGroups = days.keys.sorted(by: daySort).map { day in
                    DayGroup(day: day, artworks: days[day, default: []])
                }
                return MonthGroup(month: month, year: year, dayGroups: dayGroups)
            }
            return YearGroup(year: year, monthGroups: monthGroups)
        }
    }

    private var adaptivePadding: CGFloat {
        Brand.Adaptive.screenPadding(for: sizeClass)
    }

    var body: some View {
        ScrollView {
            // Toolbar — separated icon groups
            HStack(spacing: 12) {
                // Count badge
                Text("\(displayedArtworks.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                Spacer()

                // Favorites filter
                Button {
                    withAnimation(.snappy) { showFavoritesOnly.toggle() }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(showFavoritesOnly ? Brand.dustyRose : .secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showFavoritesOnly ? "Show all" : "Show favorites only")

                // Sort toggle
                Menu {
                    Button {
                        withAnimation(.snappy) { sortNewestFirst = true }
                    } label: {
                        Label("Newest First", systemImage: sortNewestFirst ? "checkmark" : "")
                    }

                    Button {
                        withAnimation(.snappy) { sortNewestFirst = false }
                    } label: {
                        Label("Oldest First", systemImage: sortNewestFirst ? "" : "checkmark")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Sort order")

                // Grid size group
                HStack(spacing: 6) {
                    Button {
                        let current = resolvedColumnCount(width: availableWidth)
                        withAnimation(.snappy) { columnCount = min(columnRange.upperBound, current + 1) }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(resolvedColumnCount(width: availableWidth) >= columnRange.upperBound ? Brand.disabled.opacity(0.4) : .secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(resolvedColumnCount(width: availableWidth) >= columnRange.upperBound)
                    .accessibilityLabel("Smaller thumbnails")

                    Button {
                        let current = resolvedColumnCount(width: availableWidth)
                        withAnimation(.snappy) { columnCount = max(columnRange.lowerBound, current - 1) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(resolvedColumnCount(width: availableWidth) <= columnRange.lowerBound ? Brand.disabled.opacity(0.4) : .secondary)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(resolvedColumnCount(width: availableWidth) <= columnRange.lowerBound)
                    .accessibilityLabel("Larger thumbnails")
                }
            }
            .padding(.horizontal, adaptivePadding)
            .padding(.vertical, 8)

            if displayedArtworks.isEmpty && showFavoritesOnly {
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
            } else {
                // Sectioned grid grouped by year / month / date
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedSections) { yearGroup in
                        // Year header with accent underline
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(yearGroup.year))
                                .font(Brand.title1Font)
                                .foregroundStyle(Brand.charcoal)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Brand.primary)
                                .frame(width: 32, height: 3)
                        }
                        .padding(.horizontal, adaptivePadding)
                        .padding(.top, 8)

                        ForEach(yearGroup.monthGroups) { monthGroup in
                            // Month header with colored dot
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Brand.primary.opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text(monthGroup.displayName)
                                    .font(Brand.headlineFont)
                                    .foregroundStyle(Brand.warmGray)
                            }
                            .padding(.horizontal, adaptivePadding)

                            ForEach(monthGroup.dayGroups) { dayGroup in
                                VStack(alignment: .leading, spacing: spacing) {
                                    // Date header
                                    Text(dayGroup.displayName(month: monthGroup.month, year: monthGroup.year))
                                        .font(Brand.captionFont)
                                        .foregroundStyle(Brand.warmGray.opacity(0.7))
                                        .padding(.horizontal, adaptivePadding)

                                    LazyVGrid(columns: columns(for: availableWidth), spacing: spacing) {
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
                .padding(.bottom, 80)
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in availableWidth = newWidth }
            }
        )
        .gesture(
            MagnifyGesture()
                .onEnded { value in
                    withAnimation(.snappy) {
                        let current = resolvedColumnCount(width: availableWidth)
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

// MARK: - Grouping Models

private struct YearGroup: Identifiable {
    let year: Int
    let monthGroups: [MonthGroup]
    var id: Int { year }
}

private struct MonthGroup: Identifiable {
    let month: Int
    let year: Int
    let dayGroups: [DayGroup]
    var id: String { "\(year)-\(month)" }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var comps = DateComponents()
        comps.month = month
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return formatter.string(from: date)
    }
}

private struct DayGroup: Identifiable {
    let day: Int
    let artworks: [Artwork]
    var id: Int { day }

    func displayName(month: Int, year: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        guard let date = Calendar.current.date(from: comps) else { return "" }
        return formatter.string(from: date)
    }
}

// MARK: - Gallery Tile

/// A single image tile for the gallery grid with soft corners and warm styling.
private struct GalleryTile: View {
    let artwork: Artwork

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
                            Image(systemName: "paintpalette")
                                .font(.system(size: 24, design: .rounded))
                                .foregroundStyle(Brand.primary.opacity(0.25))
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
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
        .accessibilityLabel("\(artwork.title.isEmpty ? "Untitled" : artwork.title) by \(artwork.child?.name ?? "unknown")")
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
