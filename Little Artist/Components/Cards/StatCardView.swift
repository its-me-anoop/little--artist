//
//  StatCardView.swift
//  Little Artist
//
//  A compact card displaying a single statistic with an icon, label, and value.
//

import SwiftUI

struct StatCardView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Brand.primary)

            Text(value)
                .font(Brand.title2Font)
                .foregroundStyle(.primary)

            Text(label)
                .font(Brand.caption2Font)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
        .brandCardShadow()
    }
}

#Preview {
    HStack {
        StatCardView(icon: "figure.child", label: "Artists", value: "3")
        StatCardView(icon: "flame.fill", label: "Streak", value: "12 days")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
