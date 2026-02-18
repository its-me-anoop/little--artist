//
//  ScatterCardsView.swift
//  Little Artist
//
//  Onboarding animation: cards fly in from three different edges
//  (left, right, and bottom).
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Cards fly in from different screen edges — left, right, and bottom.
struct ScatterCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            // Enters from the left
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : -30))
                .offset(
                    x: show[0] ? -70 : -200,
                    y: show[0] ? (floating ? 17 : 23) : 23
                )
                .opacity(show[0] ? 1 : 0)

            // Enters from the right
            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 30))
                .offset(
                    x: show[2] ? 75 : 200,
                    y: show[2] ? (floating ? -12 : -4) : -4
                )
                .opacity(show[2] ? 1 : 0)

            // Enters from below
            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 180)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.1).delay(0.1)) { show[0] = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.4)) { show[1] = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.7)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}
