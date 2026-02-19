
//
//  BrandTokens.swift
//  Little Artist
//
//  Centralised design tokens for the Little Artist brand identity.
//  Every colour, font, radius, spacing and size constant lives here
//  so that the rest of the app can reference Brand.* consistently.
//
//  Created by Anoop Jose on 19/02/2026.
//

import SwiftUI

// MARK: - Brand

/// Single source of truth for all Little Artist design tokens.
enum Brand {

    // MARK: - Colors

    /// Coral Orange – primary action colour.
    static let primary = Color(hex: "F2784B")
    /// Light tint of primary for backgrounds & highlights.
    static let primaryTint = Color(hex: "F2784B").opacity(0.12)
    /// Warm cream – main background colour.
    static let cream = Color(hex: "FFF8F0")
    /// Slightly lighter cream – cards, sheets and elevated surfaces.
    static let surface = Color(hex: "FFFBF7")
    /// Dark charcoal – primary text colour.
    static let charcoal = Color(hex: "3D3D3D")
    /// Warm gray – secondary / caption text colour.
    static let warmGray = Color(hex: "8A8680")
    /// Soft tan – dividers, borders and separators.
    static let softTan = Color(hex: "E8E0D8")
    /// Sage green – accent 1.
    static let sage = Color(hex: "A8C5A0")
    /// Sky blue – accent 2.
    static let sky = Color(hex: "7EB8DA")
    /// Lavender – accent 3.
    static let lavender = Color(hex: "B8A9D4")
    /// Dusty rose – danger / destructive actions.
    static let dustyRose = Color(hex: "D4736C")
    /// Disabled state colour.
    static let disabled = Color(hex: "8A8680")

    // MARK: - Avatar Palette

    /// Hex strings for child avatar backgrounds.
    static let avatarColors = ["F2784B", "A8C5A0", "7EB8DA", "B8A9D4", "E8C94A", "D4928A", "7BC8B5"]
    /// Default avatar hex when no colour has been chosen.
    static let defaultAvatarColor = "F2784B"

    // MARK: - Typography

    /// Display – SF Rounded, large title, bold.
    static let displayFont = Font.system(.largeTitle, design: .rounded).bold()
    /// Title 1 – SF Rounded, title, bold.
    static let title1Font = Font.system(.title, design: .rounded).bold()
    /// Title 2 – SF Rounded, title2, semibold.
    static let title2Font = Font.system(.title2, design: .rounded).weight(.semibold)
    /// Title 3 – SF Rounded, title3, medium.
    static let title3Font = Font.system(.title3, design: .rounded).weight(.medium)
    /// Headline – SF Rounded.
    static let headlineFont = Font.system(.headline, design: .rounded)
    /// Body – SF Pro (system default).
    static let bodyFont = Font.body
    /// Subheadline – SF Pro (system default).
    static let subheadlineFont = Font.subheadline
    /// Caption – SF Pro (system default).
    static let captionFont = Font.caption
    /// Caption 2 – SF Pro (system default).
    static let caption2Font = Font.caption2

    // MARK: - Corner Radii

    static let radiusOnboarding: CGFloat = 40
    static let radiusSheet: CGFloat = 20
    static let radiusCard: CGFloat = 18
    static let radiusButton: CGFloat = 16
    static let radiusField: CGFloat = 14
    static let radiusImage: CGFloat = 12

    // MARK: - Spacing

    static let screenPadding: CGFloat = 20
    static let formPadding: CGFloat = 32
    static let sectionSpacing: CGFloat = 28
    static let gallerySpacing: CGFloat = 24
    static let buttonPadding: CGFloat = 18
    static let fieldPadding: CGFloat = 14

    // MARK: - Component Sizes

    static let avatarSize: CGFloat = 60
    static let avatarRingSize: CGFloat = 68
    static let avatarRingStroke: CGFloat = 3
    static let avatarPreviewSize: CGFloat = 110
    static let sourceButtonSize: CGFloat = 56
    static let thumbnailWidth: CGFloat = 164
    static let thumbnailHeight: CGFloat = 180
    static let fabSize: CGFloat = 60
    static let onboardingCardHeight: CGFloat = 340
    static let colorCircleSize: CGFloat = 40
}

// MARK: - Shadow View Modifiers

/// Subtle shadow for card-style surfaces.
private struct ShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: 0, y: y)
    }
}

/// Coloured glow shadow for the floating action button.
private struct FABShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: Brand.primary.opacity(0.40), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View Extensions

extension View {
    /// Card shadow – charcoal 8 % opacity, 12 pt blur, 6 pt y-offset.
    func brandCardShadow() -> some View {
        modifier(ShadowModifier(color: Brand.charcoal.opacity(0.08), radius: 12, y: 6))
    }

    /// Avatar shadow – charcoal 6 % opacity, 6 pt blur, 3 pt y-offset.
    func brandAvatarShadow() -> some View {
        modifier(ShadowModifier(color: Brand.charcoal.opacity(0.06), radius: 6, y: 3))
    }

    /// FAB shadow – primary colour 40 % opacity, 10 pt blur, 4 pt y-offset.
    func brandFABShadow() -> some View {
        modifier(FABShadowModifier())
    }
}
