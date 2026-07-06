//
//  Comment.swift
//  Little Artist
//
//  SwiftData model representing a family member's comment on an artwork.
//

import Foundation
import SwiftData

/// A family member's comment on an artwork.
///
/// Attributes carry defaults as required for CloudKit-backed SwiftData.
@Model final class Comment {
    var text: String = ""
    var authorName: String = ""
    @Attribute(.externalStorage)
    var authorAvatarData: Data?
    var createdAt: Date = Date.now
    var artwork: Artwork?

    init(
        text: String,
        authorName: String,
        authorAvatarData: Data? = nil,
        createdAt: Date = .now,
        artwork: Artwork? = nil
    ) {
        self.text = text
        self.authorName = authorName
        self.authorAvatarData = authorAvatarData
        self.createdAt = createdAt
        self.artwork = artwork
    }
}
