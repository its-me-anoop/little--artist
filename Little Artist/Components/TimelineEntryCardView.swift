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

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let data = artwork.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 20))
                            .foregroundStyle(Brand.primary.opacity(0.3))
                    }
            }

            // Text stack
            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(Brand.subheadlineFont.weight(.semibold))
                    .foregroundStyle(artwork.title.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                if let child = artwork.child {
                    Text("by \(child.name)")
                        .font(Brand.caption2Font)
                        .foregroundStyle(.secondary)
                }

                Text(artwork.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(Brand.caption2Font)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if artwork.isFavorited {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Brand.dustyRose)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
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
