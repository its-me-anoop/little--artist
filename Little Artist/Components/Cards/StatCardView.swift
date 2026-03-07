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
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)
                .crayonStyle()

            Text(label)
                .font(Brand.captionFont.bold())
                .foregroundStyle(Brand.warmGray)
                .crayonStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.glass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Brand.glassStroke, lineWidth: 2)
        )
        .brandCardShadow()
        .crayonStyle()
    }
}

#Preview {
    HStack {
        StatCardView(icon: "figure.child", label: "Artists", value: "3")
        StatCardView(icon: "flame.fill", label: "Streak", value: "12 days")
    }
    .padding()
    .background(Brand.cream)
}
