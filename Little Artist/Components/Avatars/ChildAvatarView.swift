//
//  ChildAvatarView.swift
//  Little Artist
//
//  A circular avatar showing either a custom image or the child's initial
//  over a coloured background. Highlights with an orange ring when selected.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A circular avatar showing either a custom image or the child's initial
/// over a coloured background. Highlights with an orange ring when selected.
struct ChildAvatarView: View {
    /// The child whose avatar to display.
    let child: Child
    /// Whether this avatar is currently selected.
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let imageData = child.avatarImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: child.avatarColor))
                        .frame(width: 60, height: 60)

                    Text(String(child.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(Brand.primary, lineWidth: isSelected ? 3 : 0)
                    .frame(width: 68, height: 68)
            }
            .brandAvatarShadow()

            Text(child.name)
                .font(Brand.captionFont)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .frame(width: 64)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isSelected ? "\(child.name), selected" : child.name)
        .accessibilityHint(isSelected ? "Double tap to edit profile" : "Double tap to filter by this child")
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        ChildAvatarView(child: PreviewSampleData.emma, isSelected: true)
        ChildAvatarView(child: PreviewSampleData.noah, isSelected: false)
    }
    .padding()
}
