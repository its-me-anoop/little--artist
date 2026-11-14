//
//  AvatarCircleView.swift
//  Little Artist
//
//  The single way the app draws a child's avatar: their photo, or their
//  initial on their colour. Every avatar size uses this view.
//

import SwiftUI

/// A child's circular avatar at any size.
struct AvatarCircleView: View {
    let name: String
    let colorHex: String
    let imageData: Data?
    var size: CGFloat = Brand.avatarSize

    init(child: Child, size: CGFloat = Brand.avatarSize) {
        self.name = child.name
        self.colorHex = child.avatarColor
        self.imageData = child.avatarImageData
        self.size = size
    }

    init(name: String, colorHex: String, imageData: Data?, size: CGFloat = Brand.avatarSize) {
        self.name = name
        self.colorHex = colorHex
        self.imageData = imageData
        self.size = size
    }

    private var initial: String {
        name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color(hex: colorHex))
                    .overlay {
                        Text(initial)
                            // Decorative initial sized to the circle, not to
                            // Dynamic Type; the name is read out instead.
                            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(name)
    }
}

// MARK: - Preview

#Preview {
    HStack {
        AvatarCircleView(name: "Mia", colorHex: "F2784B", imageData: nil, size: 32)
        AvatarCircleView(name: "Leo", colorHex: "7EB8DA", imageData: nil)
        AvatarCircleView(name: "Zoe", colorHex: "A8C5A0", imageData: nil, size: 110)
    }
}
