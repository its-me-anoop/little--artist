
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
    /// Adapts to dark mode: warm cream in light, system background in dark.
    static let cream = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 1.0, green: 0.973, blue: 0.941, alpha: 1)  // #FFF8F0
    })
    /// Slightly lighter cream – cards, sheets and elevated surfaces.
    /// Adapts to dark mode: near-white in light, dark gray in dark.
    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1)   // #2C2C2C
            : UIColor(red: 1.0, green: 0.984, blue: 0.969, alpha: 1)  // #FFFBF7
    })
    /// Dark charcoal – primary text colour.
    /// Adapts to dark mode: dark charcoal in light, light gray in dark.
    static let charcoal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1)   // #E5E5EA
            : UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1)   // #3D3D3D
    })
    /// Warm gray – secondary / caption text colour.
    /// Adapts to dark mode: warm gray in light, lighter gray in dark.
    static let warmGray = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.62, blue: 0.64, alpha: 1)   // #9E9EA3
            : UIColor(red: 0.54, green: 0.53, blue: 0.50, alpha: 1)   // #8A8680
    })
    /// Soft tan – dividers, borders and separators.
    /// Adapts to dark mode: soft tan in light, dark separator in dark.
    static let softTan = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.separator
            : UIColor(red: 0.91, green: 0.88, blue: 0.85, alpha: 1)   // #E8E0D8
    })
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

    // MARK: - Adaptive Layout

    /// Width-responsive tokens for iPad adaptation.
    enum Adaptive {
        static func screenPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : Brand.screenPadding
        }

        static func gallerySpacing(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 32 : Brand.gallerySpacing
        }

        static func sectionSpacing(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 36 : Brand.sectionSpacing
        }

        /// Maximum content width to prevent ultra-wide stretching on iPad landscape.
        static let maxContentWidth: CGFloat = 700

        /// Returns gallery column count based on available width.
        static func galleryColumns(for width: CGFloat) -> Int {
            switch width {
            case ..<400: return 3
            case ..<600: return 4
            case ..<900: return 5
            default: return 6
            }
        }

        /// Returns search result column count based on available width.
        static func searchColumns(for width: CGFloat) -> Int {
            switch width {
            case ..<500: return 2
            case ..<800: return 3
            default: return 4
            }
        }

        /// Returns stat grid column count — 2 on compact, 4 on regular.
        static func statGridColumns(for sizeClass: UserInterfaceSizeClass?) -> Int {
            sizeClass == .regular ? 4 : 2
        }

        /// Scale factor for onboarding card animations — larger on iPad.
        static func onboardingCardScale(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 1.6 : 1.0
        }
    }
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

    // MARK: - Sheet Sizing

    /// Wider sheet presentation on iPad (regular size class).
    @ViewBuilder
    func adaptiveSheetSizing(sizeClass: UserInterfaceSizeClass?) -> some View {
        if sizeClass == .regular {
            if #available(iOS 18.0, *) {
                self.presentationSizing(.page)
            } else {
                self.presentationDetents([.large])
            }
        } else {
            self
        }
    }

    /// Edit-sheet presentation: wider on iPad, half/full on iPhone.
    @ViewBuilder
    func editSheetSizing(sizeClass: UserInterfaceSizeClass?) -> some View {
        if sizeClass == .regular {
            if #available(iOS 18.0, *) {
                self.presentationSizing(.page)
            } else {
                self.presentationDetents([.large])
            }
        } else {
            self.presentationDetents([.medium, .large])
        }
    }
}
