//
//  TagChipView.swift
//  Little Artist
//
//  A selectable chip for displaying and toggling tags.
//

import SwiftUI

/// A pill-shaped chip representing a tag, with selected/unselected states.
struct TagChipView: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(Brand.captionFont)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Brand.primary : Brand.surface)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Brand.primary : Brand.softTan, lineWidth: 1)
                )
        }
    }
}

#Preview {
    HStack {
        TagChipView(name: "Paint", isSelected: true) {}
        TagChipView(name: "Crayon", isSelected: false) {}
    }
    .padding()
}
