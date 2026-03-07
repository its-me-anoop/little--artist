//
//  ArtworkComparisonView.swift
//  Little Artist
//
//  Side-by-side comparison view that lets parents compare two artworks
//  to visualise artistic progression over time.
//
//  Created by Anoop Jose on 20/02/2026.
//

import SwiftUI
import SwiftData

/// A side-by-side comparison view for two artworks from the same child.
///
/// Parents can tap each slot to pick an artwork from a grid picker sheet.
/// When both artworks are selected, they are displayed side by side with
/// their titles and dates underneath for easy comparison.
struct ArtworkComparisonView: View {
    let child: Child

    @State private var leftArtwork: Artwork?
    @State private var rightArtwork: Artwork?
    @State private var showLeftPicker = false
    @State private var showRightPicker = false

    /// Child's artworks sorted newest-first.
    private var childArtworks: [Artwork] {
        (child.artworks ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                // Instruction text
                Text("Tap each side to choose an artwork")
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.warmGray)
                    .padding(.top, 8)

                // Side-by-side comparison slots
                HStack(spacing: 12) {
                    artworkSlot(
                        artwork: leftArtwork,
                        label: "Earlier",
                        onTap: { showLeftPicker = true }
                    )

                    // Divider arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Brand.warmGray)

                    artworkSlot(
                        artwork: rightArtwork,
                        label: "Later",
                        onTap: { showRightPicker = true }
                    )
                }
                .padding(.horizontal, Brand.screenPadding)

                // Date comparison when both selected
                if let left = leftArtwork, let right = rightArtwork {
                    dateComparisonBanner(earlier: left, later: right)
                        .padding(.horizontal, Brand.screenPadding)
                }
            }
            .padding(.bottom, Brand.sectionSpacing)
        }
        .background(BrandAppBackground())
        .navigationTitle("Compare Artworks")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLeftPicker) {
            artworkPickerSheet(
                title: "Choose Earlier Artwork",
                excluding: rightArtwork
            ) { artwork in
                leftArtwork = artwork
                showLeftPicker = false
            }
        }
        .sheet(isPresented: $showRightPicker) {
            artworkPickerSheet(
                title: "Choose Later Artwork",
                excluding: leftArtwork
            ) { artwork in
                rightArtwork = artwork
                showRightPicker = false
            }
        }
    }

    // MARK: - Artwork Slot

    /// A tappable area that shows either a placeholder or the selected artwork.
    @ViewBuilder
    private func artworkSlot(
        artwork: Artwork?,
        label: String,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                Group {
                    if let artwork, let data = artwork.thumbnailData ?? artwork.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Brand.primary)
                            Text(label)
                                .font(Brand.captionFont)
                                .foregroundStyle(Brand.warmGray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Brand.surface)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusCard)
                        .strokeBorder(
                            artwork != nil ? Color.clear : Brand.softTan,
                            style: artwork != nil ? StrokeStyle() : StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
                .brandCardShadow()
            }
            .buttonStyle(.plain)

            // Title and date label
            if let artwork {
                VStack(spacing: 2) {
                    Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                        .font(Brand.subheadlineFont.weight(.medium))
                        .foregroundStyle(Brand.charcoal)
                        .lineLimit(1)

                    Text(formattedDate(artwork.createdAt))
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
            }
        }
    }

    // MARK: - Date Comparison Banner

    /// Shows the time span between the two selected artworks.
    @ViewBuilder
    private func dateComparisonBanner(earlier: Artwork, later: Artwork) -> some View {
        let span = timeSpan(from: earlier.createdAt, to: later.createdAt)

        HStack {
            Image(systemName: "calendar")
                .foregroundStyle(Brand.primary)
            Text(span)
                .font(Brand.captionFont.weight(.medium))
                .foregroundStyle(Brand.charcoal)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Brand.primaryTint)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusField))
    }

    // MARK: - Picker Sheet

    /// A modal grid of the child's artworks for selecting one.
    @ViewBuilder
    private func artworkPickerSheet(
        title: String,
        excluding: Artwork?,
        onSelect: @escaping (Artwork) -> Void
    ) -> some View {
        NavigationStack {
            ScrollView {
                if childArtworks.isEmpty {
                    ContentUnavailableView(
                        "No Artworks Yet",
                        systemImage: "paintpalette",
                        description: Text("Add some artworks for \(child.name) first.")
                    )
                } else {
                    let columns = [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ]

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(childArtworks) { artwork in
                            let isExcluded = excluding?.persistentModelID == artwork.persistentModelID

                            Button {
                                HapticService.selection()
                                onSelect(artwork)
                            } label: {
                                pickerThumbnail(artwork: artwork, isExcluded: isExcluded)
                            }
                            .buttonStyle(.plain)
                            .disabled(isExcluded)
                        }
                    }
                    .padding(Brand.screenPadding)
                }
            }
            .background(BrandAppBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Dismiss by toggling the sheet binding
                        if title.contains("Earlier") {
                            showLeftPicker = false
                        } else {
                            showRightPicker = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Picker Thumbnail

    /// A single thumbnail cell in the artwork picker grid.
    @ViewBuilder
    private func pickerThumbnail(artwork: Artwork, isExcluded: Bool) -> some View {
        VStack(spacing: 6) {
            Group {
                if let data = artwork.thumbnailData ?? artwork.imageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Brand.softTan.opacity(0.5))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Brand.warmGray)
                        }
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
            .opacity(isExcluded ? 0.4 : 1.0)
            .overlay {
                if isExcluded {
                    RoundedRectangle(cornerRadius: Brand.radiusImage)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Brand.primary)
                        }
                }
            }

            Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.charcoal)
                .lineLimit(1)

            Text(formattedDate(artwork.createdAt))
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
        }
    }

    // MARK: - Helpers

    /// Formats a date as "MMM d, yyyy" (e.g. "Feb 14, 2026").
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    /// Computes a human-readable time span between two dates.
    private func timeSpan(from start: Date, to end: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: start, to: end)

        let years = abs(components.year ?? 0)
        let months = abs(components.month ?? 0)
        let days = abs(components.day ?? 0)

        if years > 0 && months > 0 {
            return "\(years) year\(years == 1 ? "" : "s"), \(months) month\(months == 1 ? "" : "s") apart"
        } else if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s") apart"
        } else if months > 0 {
            return "\(months) month\(months == 1 ? "" : "s") apart"
        } else if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") apart"
        } else {
            return "Same day"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArtworkComparisonView(child: PreviewSampleData.emma)
    }
    .modelContainer(PreviewSampleData.container)
}
