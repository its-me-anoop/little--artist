//
//  ArtworkThumbnailView.swift
//  Little Artist
//
//  A compact card displaying an artwork image, title, and creation date.
//  Used inside the horizontal gallery scrollers on the home screen.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// A thumbnail card for a single ``Artwork``.
///
/// Displays the artwork image (or a placeholder), its title, and a
/// formatted creation date. Adapts shadow and border styling for
/// both light and dark colour schemes.
struct ArtworkThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let artwork: Artwork

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: artwork.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Artwork image — fixed size, clipped
            if let data = artwork.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 164, height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 164, height: 180)
                    .overlay {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange.opacity(0.3))
                    }
            }

            // Info section
            VStack(alignment: .leading, spacing: 5) {
                Text(artwork.title.isEmpty ? "Untitled" : artwork.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(artwork.title.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(formattedDate)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : .clear, lineWidth: 1)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 1, x: 0, y: 1)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.10), radius: 14, x: 0, y: 6)
        }
    }
}

// MARK: - Previews

#Preview("Light") {
    ArtworkThumbnailView(artwork: PreviewSampleData.singleArtwork)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

#Preview("Dark") {
    ArtworkThumbnailView(artwork: PreviewSampleData.singleArtwork)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
        .modelContainer(for: [Child.self, Artwork.self], inMemory: true)
}

