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

            Image("crayon_palette")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .crayonStyle()
                .padding(.bottom, 8)

            Text("No artwork yet")
                .font(Brand.title2Font.bold())
                .foregroundStyle(Brand.charcoal)

            Text("Capture your first masterpiece\nby tapping the camera button.")
                .font(Brand.title3Font)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
                .crayonStyle()

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    NoArtworkView()
}
