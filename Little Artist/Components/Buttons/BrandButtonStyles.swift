//
//  BrandButtonStyles.swift
//  Little Artist
//
//  The app's shared button styles, so every call to action looks and
//  behaves the same: one primary style, one secondary style.
//

import SwiftUI

/// Filled capsule for the main action on a screen ("Save to Gallery",
/// "Add Child", "Start 30-Day Free Trial"). Greys out when disabled.
struct BrandPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    /// Stretch to the available width (sheet CTAs) or hug the label.
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.headlineFont)
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, fullWidth ? Brand.buttonPadding : 12)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(isEnabled ? Brand.primary : Brand.disabled, in: Capsule())
            .shadow(color: isEnabled ? Brand.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

/// Outlined capsule for an alternative action next to a primary one.
struct BrandSecondaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.subheadlineFont.weight(.semibold))
            .foregroundStyle(Brand.primary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .overlay(Capsule().strokeBorder(Brand.primary, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == BrandPrimaryButtonStyle {
    /// The app's primary call-to-action style.
    static var brandPrimary: BrandPrimaryButtonStyle { BrandPrimaryButtonStyle() }
    /// A compact primary button that hugs its label.
    static var brandPrimaryCompact: BrandPrimaryButtonStyle { BrandPrimaryButtonStyle(fullWidth: false) }
}

extension ButtonStyle where Self == BrandSecondaryButtonStyle {
    /// The app's secondary action style.
    static var brandSecondary: BrandSecondaryButtonStyle { BrandSecondaryButtonStyle() }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Button("Save to Gallery") {}.buttonStyle(.brandPrimary)
        Button("Disabled") {}.buttonStyle(.brandPrimary).disabled(true)
        Button("Add Child") {}.buttonStyle(.brandPrimaryCompact)
        Button("Buy Lifetime Now") {}.buttonStyle(.brandSecondary)
    }
    .padding()
}
