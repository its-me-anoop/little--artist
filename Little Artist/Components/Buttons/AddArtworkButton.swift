//
//  AddArtworkButton.swift
//  Little Artist
//
//  A floating action button used to initiate artwork capture.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// An orange circular floating action button (FAB) displayed at the bottom-right
/// of the gallery. Triggers the artwork capture flow when tapped.
struct AddArtworkButton: View {
    /// Closure invoked when the button is tapped.
    var action: () -> Void

    var body: some View {
        Button {
            HapticService.medium()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(Brand.primary.gradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: Brand.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                Circle()
                    .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 64, height: 64)
                    .padding(2)

                Image(systemName: "plus")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
            }
            .crayonStyle()
        }
        .accessibilityLabel("Add new artwork")
        .accessibilityHint("Double tap to capture artwork")
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    AddArtworkButton(action: {})
}
