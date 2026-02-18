//
//  DriftCardsView.swift
//  Little Artist
//
//  Onboarding animation: cards rise up from below with staggered delays
//  and settle into tilted positions with a gentle floating loop.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// Cards drift upward from below, staggered, then gently float in place.
struct DriftCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : -8))
                .offset(x: -70, y: show[0] ? (floating ? 17 : 23) : 100)
                .scaleEffect(show[0] ? 1 : 0.7)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 6))
                .offset(x: 75, y: show[2] ? (floating ? -12 : -4) : 80)
                .scaleEffect(show[2] ? 1 : 0.7)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 120)
                .scaleEffect(show[1] ? 1 : 0.7)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.0).delay(0.1)) { show[1] = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.35)) { show[0] = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.6)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.8)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

#Preview {
    DriftCardsView(
        icons: ["paintpalette.fill", "photo.artframe", "paintbrush.pointed.fill"],
        accentColor: .orange,
        isActive: true
    )
    .frame(height: 340)
    .background(Color.orange.opacity(0.08))
}

