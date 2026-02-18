//
//  PulseCardsView.swift
//  Little Artist
//
//  Onboarding animation: cards scale up from tiny at centre, one by one,
//  like a heartbeat pulse.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Cards scale up from the centre one by one, like a heartbeat pulse.
struct PulseCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : 0))
                .offset(
                    x: show[0] ? -70 : 0,
                    y: show[0] ? (floating ? 17 : 23) : 10
                )
                .scaleEffect(show[0] ? 1 : 0.1)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 0))
                .offset(
                    x: show[2] ? 75 : 0,
                    y: show[2] ? (floating ? -12 : -4) : 10
                )
                .scaleEffect(show[2] ? 1 : 0.1)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 10)
                .scaleEffect(show[1] ? 1 : 0.1)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.1)) { show[1] = true }
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.45)) { show[0] = true }
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.8)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

#Preview {
    PulseCardsView(
        icons: ["brain.head.profile.fill", "text.bubble.fill", "lightbulb.fill"],
        accentColor: .green,
        isActive: true
    )
    .frame(height: 340)
    .background(Color.green.opacity(0.08))
}
