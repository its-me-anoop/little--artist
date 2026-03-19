//
//  NoChildrenView.swift
//  Little Artist
//
//  A full-screen placeholder shown when no child profiles exist.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A full-screen placeholder shown when no child profiles exist.
///
/// Displays a friendly prompt and a button to add the first child.
struct NoChildrenView: View {
    /// Closure invoked when the user taps the "Add Child" button.
    var onAddChild: () -> Void

    var body: some View {
        ZStack {
            BrandAppBackground()

            VStack {
                Spacer()

                // MARK: Paper stack
                ZStack {
                    // Bottom card — rotated clockwise
                    RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                        .fill(Brand.sage.opacity(0.25))
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .rotationEffect(.degrees(4))
                        .brandCardShadow()

                    // Middle card — rotated counter-clockwise
                    RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                        .fill(Brand.primary.opacity(0.12))
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .rotationEffect(.degrees(-2.5))
                        .brandCardShadow()

                    // Top card — main content
                    VStack(spacing: 16) {
                        Image("LaunchFox")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)

                        Text("Add your first little artist")
                            .font(Brand.title2Font)
                            .foregroundStyle(Brand.charcoal)
                            .multilineTextAlignment(.center)

                        Text("Use Create to add a child\nand start capturing their artwork.")
                            .font(Brand.bodyFont)
                            .foregroundStyle(Brand.warmGray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        Button {
                            onAddChild()
                        } label: {
                            Text("Add Child")
                                .font(Brand.headlineFont)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Brand.buttonPadding)
                                .padding(.vertical, 14)
                                .background(Brand.primary.gradient)
                                .clipShape(Capsule())
                                .shadow(color: Brand.primary.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Brand.screenPadding)
                    .padding(.vertical, Brand.sectionSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                            .fill(Brand.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                            .stroke(Brand.softTan, lineWidth: 1)
                    )
                    .brandCardShadow()
                }
                .padding(.horizontal, Brand.screenPadding)

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NoChildrenView(onAddChild: {})
}
