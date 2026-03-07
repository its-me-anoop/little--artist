//
//  YearChipView.swift
//  Little Artist
//
//  A small capsule-shaped chip button used to filter artworks by year.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A capsule-shaped year filter chip used in the artwork gallery.
///
/// Displays a year label with a highlighted state when selected.
struct YearChipView: View {
    /// The text to display (typically a four-digit year).
    let label: String
    /// Whether this chip is currently selected.
    let isSelected: Bool
    /// Closure invoked when the chip is tapped.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Brand.captionFont.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : Brand.charcoal)
                .background(isSelected ? Brand.primary.gradient : Brand.softTan.opacity(0.5).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Brand.glassStrokeSoft : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? Brand.primary.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                .crayonStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        YearChipView(label: "2026", isSelected: true, action: {})
        YearChipView(label: "2025", isSelected: false, action: {})
    }
    .padding()
}
