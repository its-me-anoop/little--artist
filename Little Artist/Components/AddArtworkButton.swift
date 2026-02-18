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
            action()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.orange)
                .clipShape(Circle())
                .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    AddArtworkButton(action: {})
}
