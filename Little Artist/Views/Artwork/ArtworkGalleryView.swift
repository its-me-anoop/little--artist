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

    @State private var columnCount: Int = 3
    @State private var sortNewestFirst = true
    @State private var showFavoritesOnly = false

    private let spacing: CGFloat = 3
    private let columnRange = 2...5
    private let tileRadius: CGFloat = 4

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
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
            let months = yearMap[year]!
            let monthGroups = months.keys.sorted(by: monthSort).map { month in
                let days = months[month]!
                let dayGroups = days.keys.sorted(by: daySort).map { day in
                    DayGroup(day: day, artworks: days[day]!)
                }
                return MonthGroup(month: month, year: year, dayGroups: dayGroups)
            }
            return YearGroup(year: year, monthGroups: monthGroups)
        }
    }

    var body: some View {
        ScrollView {
            // Floating toolbar pill
            HStack(spacing: 8) {
                Text("\(displayedArtworks.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Brand.primaryTint)
                    .clipShape(Capsule())

                Spacer()

                // Favorites filter
                Button {
                    withAnimation(.snappy) { showFavoritesOnly.toggle() }
                } label: {
                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundStyle(showFavoritesOnly ? Brand.dustyRose : Brand.warmGray)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showFavoritesOnly ? "Show all" : "Show favorites only")

                // Sort toggle
                Menu {
                    Button {
                        withAnimation(.snappy) { sortNewestFirst = true }
                    } label: {
                        Label("Newest First", systemImage: "arrow.down")
                    }
                    .disabled(sortNewestFirst)

                    Button {
                        withAnimation(.snappy) { sortNewestFirst = false }
                    } label: {
                        Label("Oldest First", systemImage: "arrow.up")
                    }
                    .disabled(!sortNewestFirst)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15))
                        .foregroundStyle(Brand.warmGray)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Sort order")

                // Grid size controls
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.snappy) { columnCount = min(columnRange.upperBound, columnCount + 1) }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(columnCount >= columnRange.upperBound ? Brand.disabled : Brand.warmGray)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(columnCount >= columnRange.upperBound)
                    .accessibilityLabel("Smaller thumbnails")

                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 14))
                        .foregroundStyle(Brand.warmGray)

                    Button {
                        withAnimation(.snappy) { columnCount = max(columnRange.lowerBound, columnCount - 1) }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(columnCount <= columnRange.lowerBound ? Brand.disabled : Brand.warmGray)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(columnCount <= columnRange.lowerBound)
                    .accessibilityLabel("Larger thumbnails")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Brand.surface)
                    .shadow(color: Brand.charcoal.opacity(0.06), radius: 8, y: 2)
            )
            .padding(.horizontal, Brand.screenPadding)
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
                        .padding(.horizontal, Brand.screenPadding)
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
                            .padding(.horizontal, Brand.screenPadding)

                            ForEach(monthGroup.dayGroups) { dayGroup in
                                VStack(alignment: .leading, spacing: spacing) {
                                    // Date header
                                    Text(dayGroup.displayName(month: monthGroup.month, year: monthGroup.year))
                                        .font(Brand.captionFont)
                                        .foregroundStyle(Brand.warmGray.opacity(0.7))
                                        .padding(.horizontal, Brand.screenPadding)

                                    LazyVGrid(columns: columns, spacing: spacing) {
                                        ForEach(dayGroup.artworks) { artwork in
                                            NavigationLink {
                                                ArtworkDetailView(artwork: artwork)
                                            } label: {
                                                GalleryTile(artwork: artwork)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button {
                                                    artwork.isFavorited.toggle()
                                                } label: {
                                                    Label(
                                                        artwork.isFavorited ? "Unfavorite" : "Favorite",
                                                        systemImage: artwork.isFavorited ? "heart.slash" : "heart"
                                                    )
                                                }
                                                Button("Share", systemImage: "square.and.arrow.up") {}
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
        .gesture(
            MagnifyGesture()
                .onEnded { value in
                    withAnimation(.snappy) {
                        if value.magnification > 1.2 {
                            columnCount = max(columnRange.lowerBound, columnCount - 1)
                        } else if value.magnification < 0.8 {
                            columnCount = min(columnRange.upperBound, columnCount + 1)
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
                if let data = artwork.imageData, let uiImage = UIImage(data: data) {
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
