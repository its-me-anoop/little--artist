//
//  StatPillView.swift
//  Little Artist
//
//  A rotatable stat pill card displaying a value and label for bento grid layouts.
//

import SwiftUI

/// A rotatable stat pill card displaying a single statistic.
///
/// Shows a prominent value in primary color above an uppercase label,
/// styled as a card with optional rotation for bento grid layouts.
struct StatPillView: View {

    // MARK: - Properties

    /// The statistic value to display prominently.
    let value: String
    /// A short label describing the statistic.
    let label: String
    /// Rotation angle for bento grid placement.
    var rotation: Double = 0

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.title2Font)
                .foregroundStyle(Brand.primary)

            Text(label.uppercased())
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(Brand.fieldPadding)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .brandCardShadow()
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        StatPillView(value: "47", label: "Artworks", rotation: -2)
        StatPillView(value: "3", label: "Artists", rotation: 1.5)
        StatPillView(value: "12", label: "Months", rotation: -1)
    }
    .padding()
    .background(Brand.cream)
}
