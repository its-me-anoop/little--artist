//
//  Comment.swift
//  Little Artist
//
//  SwiftData model for a note the parent writes about an artwork. Kept
//  under its original name so the CloudKit schema stays compatible.
//

import Foundation
import SwiftData

/// A dated note about an artwork. `authorName` and `authorAvatarData` are
/// legacy fields from the multi-user design and are no longer shown.
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
