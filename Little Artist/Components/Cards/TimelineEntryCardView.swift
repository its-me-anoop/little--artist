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
                        Image("crayon_palette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: sizeClass == .regular ? 32 : 24)
                            .opacity(0.5)
                            .crayonStyle()
                    }
            }

            // Text stack
            VStack(alignment: .leading, spacing: sizeClass == .regular ? 6 : 4) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(Brand.headlineFont.bold())
                    .foregroundStyle(artwork.title.isEmpty ? Brand.warmGray : Brand.charcoal)
                    .lineLimit(1)
                    .crayonStyle()

                if let child = artwork.child {
                    Text("by \(child.name)")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                        .crayonStyle()
                }

                Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray.opacity(0.8))
                    .crayonStyle()
            }

            Spacer()

            if artwork.isFavorited {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.dustyRose)
            }
        }
        .padding(sizeClass == .regular ? 16 : 12)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? Brand.primary : Brand.warmGray.opacity(0.2), lineWidth: 2)
        }
        .crayonStyle()
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
