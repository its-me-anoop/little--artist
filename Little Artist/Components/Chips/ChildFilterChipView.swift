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
                    .font(Brand.caption2Font.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Brand.primary : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(child.name), \(isSelected ? "selected" : "not selected")")
        .accessibilityHint("Double tap to filter")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
