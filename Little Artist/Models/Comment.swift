//
//  Comment.swift
//  Little Artist
//
//  SwiftData model representing a family member's comment on an artwork.
//

import Foundation
import SwiftData

/// A family member's comment on an artwork.
@Model final class Comment {
    var text: String
    var authorName: String
    @Attribute(.externalStorage)
    var authorAvatarData: Data?
    var createdAt: Date
    var artwork: Artwork?
    var firestoreId: String?

    init(
        text: String,
        authorName: String,
        authorAvatarData: Data? = nil,
        createdAt: Date = .now,
        artwork: Artwork? = nil,
        firestoreId: String? = nil
    ) {
        self.text = text
        self.authorName = authorName
        self.authorAvatarData = authorAvatarData
        self.createdAt = createdAt
        self.artwork = artwork
        self.firestoreId = firestoreId
    }
}
