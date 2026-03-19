//
//  PDFPreviewView.swift
//  Little Artist
//
//  Magazine-style preview of a generated PDF portfolio with alternating
//  art + story spreads and a share button.
//

import SwiftUI

/// A magazine-style preview of a generated PDF portfolio.
///
/// Displays alternating art-left/story-right and story-left/art-right spreads
/// for the child's artworks, with a Share PDF button in the bottom bar.
struct PDFPreviewView: View {

    // MARK: - Properties

    /// The raw PDF data to share.
    let pdfData: Data
    /// The child whose portfolio is being previewed.
    let child: Child

    // MARK: - State

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    // MARK: - Computed

    private var previewArtworks: [Artwork] {
        Array((child.artworks ?? [])
            .sorted { $0.createdAt < $1.createdAt }
            .prefix(8))
    }

    private var editionYear: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date.now)
        return "\(year)"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            BrandAppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Brand.gallerySpacing) {
                    heroHeader
                    spreadsSection
                }
                .padding(.horizontal, Brand.screenPadding)
                .padding(.top, Brand.screenPadding)
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                shareBar
            }
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [pdfData])
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 6) {
            Text(child.name)
                .font(.system(.largeTitle, design: .serif).italic())
                .foregroundStyle(Brand.sky)

            Text("\(editionYear) Digital Edition")
                .font(Brand.caption2Font.bold())
                .tracking(3)
                .foregroundStyle(Brand.warmGray)
                .textCase(.uppercase)

            Divider()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    // MARK: - Spreads Section

    private var spreadsSection: some View {
        VStack(spacing: Brand.sectionSpacing + 8) {
            if previewArtworks.isEmpty {
                emptyState
            } else {
                ForEach(Array(previewArtworks.enumerated()), id: \.offset) { index, artwork in
                    if index.isMultiple(of: 2) {
                        artLeftStoryRight(artwork: artwork, pageNumber: index + 1)
                    } else {
                        storyLeftArtRight(artwork: artwork, pageNumber: index + 1)
                    }

                    if index < previewArtworks.count - 1 {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(Brand.softTan)

            Text("No artworks in this collection yet.")
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Art Left, Story Right

    /// A spread with the artwork on the left and the story text on the right.
    private func artLeftStoryRight(artwork: Artwork, pageNumber: Int) -> some View {
        HStack(alignment: .top, spacing: Brand.sectionSpacing) {
            artworkFrame(artwork)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 16) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(.system(.title, design: .serif).italic())
                    .foregroundStyle(Brand.primary)

                Text(artwork.caption.isEmpty ? "A creative masterpiece." : artwork.caption)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                    .lineSpacing(3)

                Spacer()

                Text("PAGE \(String(format: "%02d", pageNumber))")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Story Left, Art Right

    /// A spread with the story text on the left and the artwork on the right.
    private func storyLeftArtRight(artwork: Artwork, pageNumber: Int) -> some View {
        HStack(alignment: .top, spacing: Brand.sectionSpacing) {
            VStack(alignment: .leading, spacing: 16) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(.system(.title, design: .serif).italic())
                    .foregroundStyle(Brand.primary)

                Text(artwork.caption.isEmpty ? "A creative masterpiece." : artwork.caption)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                    .lineSpacing(3)

                Spacer()

                Text("PAGE \(String(format: "%02d", pageNumber))")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
            .frame(maxWidth: .infinity)

            artworkFrame(artwork)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Artwork Frame

    /// A paper-frame styled artwork card with padding, shadow, and a subtle rotation.
    @ViewBuilder
    private func artworkFrame(_ artwork: Artwork) -> some View {
        let rotationDegrees = artworkRotation(for: artwork)

        VStack(spacing: 0) {
            if let thumbnailData = artwork.thumbnailData, let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
            } else if let imageData = artwork.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
            } else {
                RoundedRectangle(cornerRadius: Brand.radiusImage)
                    .fill(Brand.primaryTint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Brand.primary.opacity(0.4))
                    }
            }

            Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
                .lineLimit(1)
                .padding(.top, 8)
        }
        .padding(12)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
        .rotationEffect(.degrees(rotationDegrees))
        .padding(.vertical, 6)
    }

    /// A deterministic rotation derived from the artwork title to add visual variety.
    private func artworkRotation(for artwork: Artwork) -> Double {
        let hash = artwork.title.unicodeScalars.reduce(0) { $0 &+ $1.value }
        let normalised = Double(hash % 100) / 100.0
        return (normalised - 0.5) * 3.0  // -1.5° … +1.5°
    }

    // MARK: - Share Bar

    private var shareBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.4)

            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share PDF")
                        .font(Brand.headlineFont)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Brand.primary))
                .brandFABShadow()
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PDFPreviewView(
            pdfData: Data(),
            child: PreviewSampleData.emma
        )
    }
    .modelContainer(PreviewSampleData.container)
}
