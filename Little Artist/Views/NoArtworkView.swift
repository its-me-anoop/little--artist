//
//  NoArtworkView.swift
//  Little Artist
//
//  A full-screen placeholder shown when the selected child has no artworks.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A full-screen placeholder shown when the selected child has no artworks.
///
/// Prompts the user to capture their first masterpiece using the camera button.
struct NoArtworkView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "paintpalette")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.6))

            Text("No artwork yet")
                .font(.title3.weight(.semibold))

            Text("Capture your first masterpiece\nby tapping the camera button.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    NoArtworkView()
}
