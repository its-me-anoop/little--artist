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

                // MARK: Paper stack
                ZStack {
                    // Bottom card — rotated clockwise
                    RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                        .fill(Brand.lavender.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .rotationEffect(.degrees(4))
                        .brandCardShadow()

                    // Middle card — rotated counter-clockwise
                    RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                        .fill(Brand.sky.opacity(0.22))
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .rotationEffect(.degrees(-2.5))
                        .brandCardShadow()

                    // Top card — main content
                    VStack(spacing: 16) {
                        Image("LaunchFox")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)

                        Text("No artwork yet")
                            .font(Brand.title1Font)
                            .foregroundStyle(Brand.charcoal)
                            .multilineTextAlignment(.center)

                        Text("Capture your first masterpiece with Create in the toolbar.")
                            .font(Brand.bodyFont)
                            .foregroundStyle(Brand.warmGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Your gallery will appear here")
                            .font(Brand.captionFont)
                            .foregroundStyle(Brand.warmGray.opacity(0.9))
                            .padding(.horizontal, Brand.fieldPadding)
                            .padding(.vertical, 8)
                            .background(Brand.softTan.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Brand.screenPadding)
                    .padding(.vertical, Brand.sectionSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                            .fill(Brand.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                            .stroke(Brand.softTan, lineWidth: 1)
                    )
                    .brandCardShadow()
                }
                .padding(.horizontal, Brand.screenPadding)

                Spacer()
            }
        }
    }

    // MARK: - Background

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
