//
//  CardAnimation.swift
//  Little Artist
//
//  Defines the entrance animation styles used on onboarding pages.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation

/// The entrance animation style applied to icon cards on each onboarding page.
enum CardAnimation {
    /// Cards drift up from below with staggered delays.
    case drift
    /// Cards fan outward from a central stack.
    case fan
    /// Cards drop in from above with a soft bounce.
    case drop
    /// Cards scale up from the centre like a heartbeat.
    case pulse
    /// Cards fly in from different screen edges.
    case scatter
}
