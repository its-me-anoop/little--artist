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
        ZStack {
            backgroundLayer

            VStack {
                Spacer()

                VStack(spacing: 14) {
                    Image("LaunchFox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)

                    Text("No artwork yet")
                        .font(Brand.title1Font)
                        .foregroundStyle(Brand.charcoal)
                        .multilineTextAlignment(.center)

                    Text("Capture your first masterpiece by tapping the + button.")
                        .font(Brand.title3Font)
                        .foregroundStyle(Brand.warmGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Your gallery will appear here")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray.opacity(0.9))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Brand.glassStrong)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Brand.glass)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Brand.glassStroke, lineWidth: 2)
                )
                .brandCardShadow()
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    private var backgroundLayer: some View {
        GeometryReader { geo in
            ZStack {
                BrandAppBackground()

                Circle()
                    .fill(Brand.sky.opacity(0.12))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 58)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.22)

                Circle()
                    .fill(Brand.primary.opacity(0.12))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 66)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.28)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NoArtworkView()
}
