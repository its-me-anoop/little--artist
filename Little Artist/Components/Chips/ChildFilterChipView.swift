//
//  ChildFilterChipView.swift
//  Little Artist
//
//  A toggleable filter chip showing a child's avatar and name,
//  used in the Gallery tab's horizontal filter bar.
//

import SwiftUI
import SwiftData

struct ChildFilterChipView: View {
    let child: Child
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                // Mini avatar circle
                Circle()
                    .fill(Color(hex: child.avatarColor))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if let data = child.avatarImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }

                Text(child.name)
                    .font(Brand.captionFont.bold())
                    .crayonStyle()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Brand.primary.gradient : Color(.tertiarySystemFill).gradient)
            .foregroundStyle(isSelected ? .white : Brand.charcoal)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? Brand.primary.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(child.name), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to filter")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
