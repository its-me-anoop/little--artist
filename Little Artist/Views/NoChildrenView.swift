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

            Image(systemName: "figure.child")
                .font(.system(size: 60, design: .rounded))
                .foregroundStyle(Brand.primary.opacity(0.6))

            Text("Add your first little artist")
                .font(.system(.title3, design: .rounded).weight(.semibold))

            Text("Tap the + button to add a child\nand start capturing their artwork.")
                .font(Brand.subheadlineFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onAddChild()
            } label: {
                Text("Add Child")
                    .font(Brand.headlineFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Brand.primary)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Preview

#Preview {
    NoChildrenView(onAddChild: {})
}
