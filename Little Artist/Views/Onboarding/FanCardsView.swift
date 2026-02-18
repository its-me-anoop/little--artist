//
//  FanCardsView.swift
//  Little Artist
//
//  Onboarding animation: cards start stacked on top of each other,
//  then fan outward like a hand of cards.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Cards fan outward from a central stack with a smooth easing animation.
struct FanCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var fanned = false
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(fanned ? -20 : 0))
                .offset(
                    x: fanned ? -70 : 0,
                    y: fanned ? (floating ? 17 : 23) : 10
                )
                .opacity(fanned ? 1 : 0.6)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(fanned ? 18 : 0))
                .offset(
                    x: fanned ? 75 : 0,
                    y: fanned ? (floating ? -12 : -4) : 10
                )
                .opacity(fanned ? 1 : 0.6)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: floating ? 6 : 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) { fanned = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.6)) {
                floating = true
            }
        }, onReset: {
            fanned = false
            floating = false
        }))
    }
}
