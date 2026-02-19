//
//  ArtworkGalleryView.swift
//  Little Artist
//
//  A scrollable gallery that organises artworks by year and month
//  in a 2-column vertical grid layout.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// Displays a collection of artworks grouped by year and month
/// in a 2-column `LazyVGrid` layout.
struct ArtworkGalleryView: View {
    let artworks: [Artwork]

    @State private var selectedYear: Int? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(artworks.map { calendar.component(.year, from: $0.createdAt) })
        return years.sorted(by: >)
    }

    private var selectedYearArtworks: [Artwork] {
        guard let selectedYear else { return [] }
        let calendar = Calendar.current
        return artworks.filter { calendar.component(.year, from: $0.createdAt) == selectedYear }
    }

    private var groupedMonths: [(month: Int, artworks: [Artwork])] {
        let calendar = Calendar.current
        var monthMap: [Int: [Artwork]] = [:]

        for artwork in selectedYearArtworks {
            let month = calendar.component(.month, from: artwork.createdAt)
            monthMap[month, default: []].append(artwork)
        }

        return monthMap
            .sorted { $0.key > $1.key }
            .map { (month: $0.key, artworks: $0.value.sorted { $0.createdAt > $1.createdAt }) }
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
        if let selectedYear, availableYears.contains(selectedYear) { return }
        selectedYear = availableYears.first
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Brand.gallerySpacing) {
                // Year filter chips
                if availableYears.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableYears, id: \.self) { year in
                                YearChipView(label: String(year), isSelected: selectedYear == year) {
                                    withAnimation(.snappy) {
                                        selectedYear = year
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }

                // Month sections with 2-column grid
                ForEach(groupedMonths, id: \.month) { monthGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        // Month header with count
                        HStack(alignment: .firstTextBaseline) {
                            Text(monthName(monthGroup.month))
                                .font(Brand.headlineFont)
                            Text("\(monthGroup.artworks.count)")
                                .font(Brand.caption2Font.weight(.medium))
                                .foregroundStyle(Brand.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Brand.primaryTint)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, Brand.screenPadding)

                        // 2-column grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(monthGroup.artworks) { artwork in
                                NavigationLink {
                                    ArtworkDetailView(artwork: artwork)
                                } label: {
                                    ArtworkThumbnailView(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Share", systemImage: "square.and.arrow.up") {}
                                    Button("Edit", systemImage: "pencil") {}
                                    Divider()
                                    Button("Delete", systemImage: "trash", role: .destructive) {}
                                }
                            }
                        }
                        .padding(.horizontal, Brand.screenPadding)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .onAppear { ensureValidSelectedYear() }
        .onChange(of: availableYears) { _, _ in ensureValidSelectedYear() }
    }
}

#Preview {
    NavigationStack {
        ArtworkGalleryView(artworks: PreviewSampleData.sampleArtworks)
    }
    .modelContainer(PreviewSampleData.container)
}
