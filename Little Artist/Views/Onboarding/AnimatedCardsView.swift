//
//  AnimatedCardsView.swift
//  Little Artist
//
//  Dispatcher that routes each onboarding page to its corresponding
//  card entrance animation view based on the CardAnimation style.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Routes each onboarding page to its corresponding card entrance animation view.
struct AnimatedCardsView: View {
    /// SF Symbol names for the three icon cards.
    let icons: [String]
    /// The accent colour applied to the cards.
    let accentColor: Color
    /// The animation style to use.
    let style: CardAnimation
    /// Whether this page is currently active (visible to the user).
    let isActive: Bool

    var body: some View {
        switch style {
        case .drift:
            DriftCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .fan:
            FanCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .drop:
            DropCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .pulse:
            PulseCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .scatter:
            ScatterCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        }
    }
}
