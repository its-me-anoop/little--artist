//
//  OnboardingPage.swift
//  Little Artist
//
//  Data model describing a single page in the onboarding carousel.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftUI

/// Data describing a single page of the onboarding carousel.
struct OnboardingPage: Identifiable {
    let id = UUID()
    /// SF Symbol names for the three icon cards.
    let icons: [String]
    /// The first line of the page title (plain text).
    let titleTop: String
    /// The second line of the page title (highlighted in accent colour).
    let titleHighlight: String
    /// A short paragraph describing the feature.
    let description: String
    /// The card entrance animation style for this page.
    let animation: CardAnimation
    /// The accent color associated with this page
    let color: Color
    /// The video file name (without extension) to play on this page.
    let videoName: String
}
