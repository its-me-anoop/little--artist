
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
import UIKit

// MARK: - Brand

/// Single source of truth for all Little Artist design tokens.
enum Brand {

    // MARK: - Colors

    /// Coral Orange – primary action colour.
    static let primary = Color(hex: "F2784B")
    /// Light tint of primary for backgrounds & highlights.
    static let primaryTint = Color(hex: "F2784B").opacity(0.12)
    /// Cream-to-peach launch gradient used in light appearance.
    static let splashLightStart = Color(hex: "FFF8F0")
    static let splashLightEnd = Color(hex: "F6E5D6")
    /// Deep brown launch gradient used in dark appearance.
    static let splashDarkStart = Color(hex: "120B08")
    static let splashDarkEnd = Color(hex: "4A2B1E")
    /// Warm cream – main background colour.
    /// Adapts to dark mode: warm cream in light, system background in dark.
    static let cream = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 1.0, green: 0.973, blue: 0.941, alpha: 1)  // #FFF8F0
    })
    /// Base background tone used for bars and solid surfaces over the app gradient.
    static let backgroundBase = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.10, blue: 0.08, alpha: 1)
            : UIColor(red: 1.0, green: 0.973, blue: 0.941, alpha: 1)
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
    /// Warm translucent card fill used by chips and floating surfaces.
    static let glass = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.18, blue: 0.15, alpha: 0.94) // warm espresso
            : UIColor(red: 1.0, green: 0.984, blue: 0.969, alpha: 0.90) // #FFFBF7
    })
    /// Stronger warm surface for empty states and input controls.
    static let glassStrong = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.27, green: 0.22, blue: 0.19, alpha: 0.97)
            : UIColor(red: 1.0, green: 0.992, blue: 0.984, alpha: 0.96)
    })
    /// Subtle warm placeholder surface.
    static let glassSubtle = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.15, blue: 0.13, alpha: 0.90)
            : UIColor(red: 0.98, green: 0.95, blue: 0.92, alpha: 0.82)
    })
    /// Muted fill for disabled states that still reads in dark mode.
    static let glassMuted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.14, blue: 0.12, alpha: 0.82)
            : UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 0.82)
    })
    /// Warm border for elevated surfaces in both appearances.
    static let glassStroke = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.53, green: 0.44, blue: 0.37, alpha: 0.55)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.78)
    })
    /// Softer border used over accent-filled controls.
    static let glassStrokeSoft = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.83, green: 0.74, blue: 0.66, alpha: 0.22)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.40)
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

    static let radiusCard: CGFloat = 18
    static let radiusButton: CGFloat = 16
    static let radiusField: CGFloat = 14
    static let radiusImage: CGFloat = 12

    // MARK: - Spacing

    static let screenPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let buttonPadding: CGFloat = 18
    static let fieldPadding: CGFloat = 14

    // MARK: - Adaptive Layout

    /// Width-responsive tokens for iPad adaptation.
    enum Adaptive {
        static func screenPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 40 : Brand.screenPadding
        }

        static func sectionSpacing(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
            sizeClass == .regular ? 36 : Brand.sectionSpacing
        }

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

struct BrandAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [Brand.splashDarkStart, Color(hex: "2B1911"), Brand.splashDarkEnd]
        }

        return [Brand.splashLightStart, Color(hex: "FBEFDF"), Brand.splashLightEnd]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Brand.primary.opacity(colorScheme == .dark ? 0.14 : 0.12))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 64)
                    .offset(x: -geo.size.width * 0.28, y: -geo.size.height * 0.18)

                Circle()
                    .fill((colorScheme == .dark ? Color(hex: "6C4A37") : Brand.sky).opacity(colorScheme == .dark ? 0.16 : 0.10))
                    .frame(width: geo.size.width * 1.1, height: geo.size.width * 1.1)
                    .blur(radius: 78)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Appearance

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
