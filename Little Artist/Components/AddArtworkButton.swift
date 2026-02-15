//
//  AddArtworkButton.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

struct AddArtworkButton: View {
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
