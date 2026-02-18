//
//  ArtworkGalleryView.swift
//  Little Artist
//
//  A scrollable gallery that organises artworks by year and month,
//  with lazy-loaded horizontal artwork sliders per month.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// Displays a collection of artworks grouped by year and month.
///
/// Year filter chips at the top let the user jump between years.
/// Each month section shows a header with an artwork count badge
/// and a horizontally scrolling strip of ``ArtworkThumbnailView`` cards.
/// Month groups are lazily loaded in batches for performance.
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

// MARK: - Preview

#Preview {
    ArtworkGalleryView(artworks: PreviewSampleData.sampleArtworks)
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}
