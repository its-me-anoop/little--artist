//
//  AddChildButton.swift
//  Little Artist
//
//  A dashed-circle button for adding a new child profile,
//  shown at the end of the child slider strip.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A dashed-circle button for adding a new child profile.
struct AddChildButton: View {
    /// Closure invoked when the button is tapped.
    var action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: 60, height: 60)

                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Text("Add")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64)
        }
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Preview

#Preview {
    AddChildButton(action: {})
        .padding()
}
