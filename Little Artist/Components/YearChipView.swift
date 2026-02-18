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
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(isSelected ? Color.orange : Color(.tertiarySystemFill))
                .clipShape(Capsule())
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
