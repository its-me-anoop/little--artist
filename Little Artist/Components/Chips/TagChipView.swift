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
                .font(Brand.captionFont.bold())
                .foregroundStyle(isSelected ? .white : Brand.charcoal)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Brand.primary.gradient : Brand.surface.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Brand.glassStrokeSoft : Brand.softTan, lineWidth: 2)
                )
                .shadow(color: isSelected ? Brand.primary.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                .crayonStyle()
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
