//
//  ArtworkGalleryView.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

struct ArtworkGalleryView: View {
    let artworks: [Artwork]

    @State private var selectedYear: Int? = nil
    @State private var visibleMonthCount: Int = 3

    private let monthBatchSize = 3

    /// All distinct years present in artworks, sorted newest first
    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(artworks.map { calendar.component(.year, from: $0.createdAt) })
        return years.sorted(by: >)
    }

    /// Artworks for the selected year only
    private var selectedYearArtworks: [Artwork] {
        guard let selectedYear else { return [] }
        let calendar = Calendar.current
        return artworks.filter { calendar.component(.year, from: $0.createdAt) == selectedYear }
    }

    /// Artworks for the selected year grouped by month, sorted newest first
    private var groupedMonths: [(month: Int, artworks: [Artwork])] {
        let calendar = Calendar.current
        var monthMap: [Int: [Artwork]] = [:]

        for artwork in selectedYearArtworks {
            let components = calendar.dateComponents([.year, .month], from: artwork.createdAt)
            let month = components.month ?? 0
            monthMap[month, default: []].append(artwork)
        }

        return monthMap
            .sorted { $0.key > $1.key }
            .map { (month, artworks) in
                (month: month, artworks: artworks.sorted { $0.createdAt > $1.createdAt })
            }
    }

    private var visibleMonthGroups: [(month: Int, artworks: [Artwork])] {
        Array(groupedMonths.prefix(visibleMonthCount))
    }

    private var hasMoreMonthsToLoad: Bool {
        visibleMonthCount < groupedMonths.count
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }

    private func ensureValidSelectedYear() {
        if let selectedYear, availableYears.contains(selectedYear) {
            return
        }
        selectedYear = availableYears.first
    }

    private func resetMonthLoading() {
        visibleMonthCount = monthBatchSize
    }

    private func loadMoreMonthsIfNeeded(currentMonth: Int) {
        guard hasMoreMonthsToLoad else { return }
        guard let lastVisibleMonth = visibleMonthGroups.last?.month else { return }
        guard currentMonth == lastVisibleMonth else { return }

        visibleMonthCount = min(visibleMonthCount + monthBatchSize, groupedMonths.count)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Year filter chips
                if !availableYears.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableYears, id: \.self) { year in
                                YearChipView(label: String(year), isSelected: selectedYear == year) {
                                    withAnimation(.snappy) {
                                        selectedYear = year
                                        resetMonthLoading()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                if let selectedYear {
                    // Year header
                    Text(String(selectedYear))
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    ForEach(visibleMonthGroups, id: \.month) { monthGroup in
                        VStack(alignment: .leading, spacing: 12) {
                            // Month header with count
                            HStack(alignment: .firstTextBaseline) {
                                Text(monthName(monthGroup.month))
                                    .font(.headline)
                                Text("\(monthGroup.artworks.count)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 20)

                            // Horizontal artwork slider
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 16) {
                                    ForEach(monthGroup.artworks) { artwork in
                                        NavigationLink {
                                            ArtworkDetailView(artwork: artwork)
                                        } label: {
                                            ArtworkThumbnailView(artwork: artwork)
                                                .frame(width: 180)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            }
                        }
                        .onAppear {
                            loadMoreMonthsIfNeeded(currentMonth: monthGroup.month)
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 80) // space for FAB
        }
        .onAppear {
            ensureValidSelectedYear()
            resetMonthLoading()
        }
        .onChange(of: availableYears) { _, _ in
            ensureValidSelectedYear()
            resetMonthLoading()
        }
    }
}

private struct YearChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(isSelected ? Color.orange : Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let sampleArtworks: [Artwork] = {
        let calendar = Calendar.current

        // Helper to create a date for a given year/month/day
        func date(year: Int, month: Int, day: Int) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
        }

        return [
            // February 2026
            Artwork(title: "Rainbow House", caption: "My dream house with a rainbow", createdAt: date(year: 2026, month: 2, day: 14)),
            Artwork(title: "Snowy Mountain", caption: "Winter wonderland", createdAt: date(year: 2026, month: 2, day: 10)),
            Artwork(title: "Valentine Card", caption: "For mom and dad", createdAt: date(year: 2026, month: 2, day: 5)),

            // January 2026
            Artwork(title: "New Year Fireworks", caption: "Happy new year!", createdAt: date(year: 2026, month: 1, day: 1)),
            Artwork(title: "Snowman", caption: "Frosty the snowman", createdAt: date(year: 2026, month: 1, day: 15)),

            // December 2025
            Artwork(title: "Christmas Tree", caption: "With ornaments and a star", createdAt: date(year: 2025, month: 12, day: 25)),
            Artwork(title: "Gingerbread House", caption: "Yummy!", createdAt: date(year: 2025, month: 12, day: 20)),
            Artwork(title: "Reindeer", caption: "Rudolph with a red nose", createdAt: date(year: 2025, month: 12, day: 10)),

            // October 2025
            Artwork(title: "Pumpkin Patch", caption: "So many pumpkins", createdAt: date(year: 2025, month: 10, day: 28)),
            Artwork(title: "Spooky Ghost", caption: "Boo!", createdAt: date(year: 2025, month: 10, day: 31)),

            // June 2025
            Artwork(title: "Beach Day", caption: "Sun, sand, and waves", createdAt: date(year: 2025, month: 6, day: 15)),
            Artwork(title: "Butterfly Garden", caption: "Colorful butterflies everywhere", createdAt: date(year: 2025, month: 6, day: 8)),
        ]
    }()

    ArtworkGalleryView(artworks: sampleArtworks)
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
