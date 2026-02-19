//
//  AnimationTrigger.swift
//  Little Artist
//
//  A shared view modifier that resets and replays card entrance animations
//  as the user swipes between onboarding pages.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import UIKit

/// A view modifier that resets animation state instantly and replays
/// the entrance animation when `isActive` becomes `true`.
///
/// Used by all card animation views (Drift, Fan, Drop, Pulse, Scatter)
/// to ensure animations replay correctly when the user navigates pages.
/// Respects the Reduce Motion accessibility setting.
struct AnimationTrigger: ViewModifier {
    /// Whether this page is currently visible.
    let isActive: Bool
    /// Closure called to start the entrance animation.
    let onPlay: () -> Void
    /// Closure called to reset state to its pre-animation values.
    let onReset: () -> Void

    private func playAnimation() {
        if UIAccessibility.isReduceMotionEnabled {
            // Instant state with minimal animation for accessibility
            withAnimation(.easeIn(duration: 0.2)) {
                onPlay()
            }
        } else {
            onPlay()
        }
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    // Reset instantly, then play after a tick
                    onReset()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        playAnimation()
                    }
                } else {
                    onReset()
                }
            }
            .onAppear {
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        playAnimation()
                    }
                }
            }
    }
}
