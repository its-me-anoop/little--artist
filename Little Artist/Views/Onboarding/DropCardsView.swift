//
//  DropCardsView.swift
//  Little Artist
//
//  Onboarding animation: cards drop in from above with a soft spring
//  bounce on landing.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Cards drop in from the top of the visible area with a soft bounce on landing.
struct DropCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : 5))
                .offset(x: -70, y: show[0] ? (floating ? 17 : 23) : -70)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : -5))
                .offset(x: 75, y: show[2] ? (floating ? -12 : -4) : -60)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : -80)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.1)) { show[1] = true }
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.4)) { show[0] = true }
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.7)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}
