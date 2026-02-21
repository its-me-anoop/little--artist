//
//  TimelineEntryCardView.swift
//  Little Artist
//
//  A horizontal card for a single artwork entry in the Timeline feed.
//  Shows a small thumbnail, title, child name, and date.
//

import SwiftUI

struct TimelineEntryCardView: View {
    let artwork: Artwork
    var isSelected: Bool = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var thumbSize: CGFloat { sizeClass == .regular ? 100 : 64 }
    private var thumbRadius: CGFloat { sizeClass == .regular ? 12 : 8 }

    var body: some View {
        HStack(spacing: sizeClass == .regular ? 16 : 12) {
            // Thumbnail
            if let data = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: thumbSize, height: thumbSize)
                    .clipShape(RoundedRectangle(cornerRadius: thumbRadius))
            } else {
                RoundedRectangle(cornerRadius: thumbRadius)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: sizeClass == .regular ? 28 : 20))
                            .foregroundStyle(Brand.primary.opacity(0.3))
                    }
            }

            // Text stack
            VStack(alignment: .leading, spacing: sizeClass == .regular ? 6 : 4) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(sizeClass == .regular ? Brand.headlineFont : Brand.subheadlineFont.weight(.semibold))
                    .foregroundStyle(artwork.title.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                if let child = artwork.child {
                    Text("by \(child.name)")
                        .font(sizeClass == .regular ? Brand.captionFont : Brand.caption2Font)
                        .foregroundStyle(.secondary)
                }

                Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(sizeClass == .regular ? Brand.captionFont : Brand.caption2Font)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if artwork.isFavorited {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.dustyRose)
            }
        }
        .padding(sizeClass == .regular ? 16 : 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Brand.radiusImage)
                    .strokeBorder(Brand.primary, lineWidth: 2.5)
            }
        }
        .brandCardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(artwork.title.isEmpty ? "Untitled" : artwork.title) by \(artwork.child?.name ?? "unknown"), \(artwork.createdAt.formatted(.dateTime.month(.wide).day().year()))")
        .accessibilityHint("Double tap for details")
    }
}

#Preview {
    TimelineEntryCardView(artwork: PreviewSampleData.singleArtwork)
        .padding()
        .background(Color(.systemGroupedBackground))
}
