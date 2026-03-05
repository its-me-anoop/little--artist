//
//  IconCard.swift
//  Little Artist
//
//  A single rounded card displaying an SF Symbol icon, used as the
//  animated illustration element on each onboarding page.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A single rounded card displaying an SF Symbol icon.
/// Used as the animated illustration element on each onboarding page.
struct IconCard: View {
    /// The SF Symbol name to display.
    let icon: String
    /// The font size for the icon.
    let size: CGFloat
    /// The width and height of the card.
    let cardSize: CGFloat
    /// The foreground colour applied to the icon.
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Brand.surface)
                .overlay(
                    Image("crayon_paper")
                        .resizable()
                        .opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                )
                .brandCardShadow()
            
            // Hand-drawn thicker stroke
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(color.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .padding(2)

            Image(icon)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: size * 1.5, height: size * 1.5) // Scaling up the inner image
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(width: cardSize * 1.3, height: cardSize * 1.3) // Making the cards themselves larger
        .crayonStyle() // Adding slight wobble to individual cards
    }
}

// MARK: - Preview

#Preview {
    IconCard(icon: "crayon_palette", size: 56, cardSize: 90, color: Brand.primary)
        .padding()
}
