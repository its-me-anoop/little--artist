//
//  FamilyCommentView.swift
//  Little Artist
//
//  Displays a single family member's comment on an artwork.
//

import SwiftUI

/// A card displaying a family member's comment with author avatar and timestamp.
struct FamilyCommentView: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Author avatar
            if let avatarData = comment.authorAvatarData, let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Brand.lavender.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(comment.authorName.prefix(1)).uppercased())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.charcoal)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(Brand.captionFont.weight(.semibold))
                        .foregroundStyle(Brand.charcoal)

                    Spacer()

                    Text(comment.createdAt, format: .dateTime.month(.abbreviated).day())
                        .font(Brand.caption2Font)
                        .foregroundStyle(Brand.warmGray)
                }

                Text(comment.text)
                    .font(Brand.bodyFont)
                    .foregroundStyle(Brand.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Brand.radiusField, style: .continuous)
                .fill(Brand.surface.opacity(0.6))
        )
    }
}
