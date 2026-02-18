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
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(color)
        }
        .frame(width: cardSize, height: cardSize)
    }
}

// MARK: - Preview

#Preview {
    IconCard(icon: "paintpalette.fill", size: 56, cardSize: 90, color: .orange)
        .padding()
}
