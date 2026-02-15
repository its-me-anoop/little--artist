//
//  EmptyStateViews.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

// MARK: - No Children Empty State

struct NoChildrenView: View {
    var onAddChild: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "figure.child")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.6))

            Text("Add your first little artist")
                .font(.title3.weight(.semibold))

            Text("Tap the + button to add a child\nand start capturing their artwork.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onAddChild()
            } label: {
                Text("Add Child")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - No Artwork Empty State

struct NoArtworkView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "paintpalette")
                .font(.system(size: 60))
                .foregroundStyle(.orange.opacity(0.6))

            Text("No artwork yet")
                .font(.title3.weight(.semibold))

            Text("Capture your first masterpiece\nby tapping the camera button.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview("No Children") {
    NoChildrenView(onAddChild: {})
}

#Preview("No Artwork") {
    NoArtworkView()
}
