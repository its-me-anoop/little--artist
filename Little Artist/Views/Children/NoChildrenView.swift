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
        VStack(spacing: 16) {
            Spacer()

            Image("LaunchFox")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text("Add your first little artist")
                .font(Brand.title2Font.bold())
                .foregroundStyle(Brand.charcoal)

            Text("Tap the + button to add a child\nand start capturing their artwork.")
                .font(Brand.title3Font)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
                .crayonStyle()
                .padding(.bottom, 16)

            Button {
                onAddChild()
            } label: {
                Text("Add Child")
                    .font(Brand.title3Font.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Brand.primary.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    )
                    .shadow(color: Brand.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    .crayonStyle()
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.cream)
    }
}

// MARK: - Preview

#Preview {
    NoChildrenView(onAddChild: {})
}
