//
//  MemoryCardView.swift
//  Little Artist
//
//  A card showing an artwork from a previous year on this date.
//

import SwiftUI

/// A card displaying an "On This Day" memory with artwork thumbnail.
struct MemoryCardView: View {
    let artwork: Artwork
    let yearsAgo: Int
    var cardWidth: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Artwork thumbnail
            if let imageData = artwork.thumbnailData ?? artwork.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardWidth, height: cardWidth * 0.75)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage))
            }

            // Title
            Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                .font(Brand.captionFont.weight(.medium))
                .foregroundStyle(Brand.charcoal)
                .lineLimit(1)

            // Years ago label
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                Text(yearsAgo == 1 ? "1 year ago" : "\(yearsAgo) years ago")
                    .font(Brand.caption2Font)
            }
            .foregroundStyle(Brand.primary)

            // Child name
            if let childName = artwork.child?.name, !childName.isEmpty {
                Text("by \(childName)")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
        }
        .frame(width: cardWidth)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusCard)
                .fill(Brand.surface)
        )
        .brandCardShadow()
    }
}
