//
//  BentoArtworkCardView.swift
//  Little Artist
//
//  A paper-stack style artwork card for bento grid layouts.
//

import SwiftUI
import SwiftData

/// A paper-stack style artwork card for bento grid layouts.
///
/// Displays the artwork image with an optional voice memo indicator pill,
/// title, and date. Supports rotation for a playful stacked-paper effect.
struct BentoArtworkCardView: View {

    // MARK: - Properties

    /// The artwork to display.
    let artwork: Artwork
    /// Rotation angle for the paper-stack effect.
    var rotation: Double = 0
    /// Whether to show the artwork title below the image.
    var showTitle: Bool = true
    /// Whether to show the voice memo indicator pill when a voice note exists.
    var showVoiceMemoIndicator: Bool = true

    // MARK: - Private Helpers

    private var displayImage: UIImage? {
        if let data = artwork.thumbnailData ?? artwork.imageData {
            return UIImage(data: data)
        }
        return nil
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: artwork.createdAt)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: Image Area
            ZStack(alignment: .bottomLeading) {
                if let uiImage = displayImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: Brand.radiusImage, style: .continuous)
                        .fill(Brand.softTan.opacity(0.5))
                        .overlay {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundStyle(Brand.warmGray)
                        }
                }

                // Voice Memo Indicator
                if showVoiceMemoIndicator, artwork.voiceNoteData != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Story")
                            .font(Brand.caption2Font)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage, style: .continuous))

            // MARK: Title
            if showTitle, !artwork.title.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(artwork.title)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.charcoal)
                    .lineLimit(1)
            }

            // MARK: Date
            Text(dateText)
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
        }
        .padding(6)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .brandCardShadow()
        .rotationEffect(.degrees(rotation))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel({
            let title = artwork.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : artwork.title
            let childPart = artwork.child.map { "by \($0.name)" } ?? ""
            let datePart = artwork.createdAt.formatted(.dateTime.month(.abbreviated).day().year())
            return [title, childPart, datePart].filter { !$0.isEmpty }.joined(separator: ", ")
        }())
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        BentoArtworkCardView(
            artwork: PreviewSampleData.singleArtwork,
            rotation: -3
        )
        BentoArtworkCardView(
            artwork: PreviewSampleData.artworkWithVoiceMemo,
            rotation: 2
        )
    }
    .padding()
    .background(Brand.cream)
}
