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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .strokeBorder(Brand.primary.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6]))
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Brand.surface))
                    .crayonStyle()

                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.primary)
                    .crayonStyle()
            }

            Text("Add")
                .font(Brand.captionFont.bold())
                .foregroundStyle(Brand.warmGray)
                .frame(width: 64)
                .crayonStyle()
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
