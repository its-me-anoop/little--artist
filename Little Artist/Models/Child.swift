//
//  Child.swift
//  Little Artist
//
//  SwiftData model representing a child artist whose artwork is tracked.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftData

/// A child artist whose creations are stored in the app.
///
/// Each child has a name, an avatar colour (stored as a hex string),
/// an optional custom avatar image, and a one-to-many relationship
/// with their ``Artwork`` entries. Deleting a child cascades to
/// delete all associated artworks.
@Model
final class Child {
    /// The child's display name.
    var name: String = ""

    /// Hex colour string (e.g. `"FF8C00"`) used for the default avatar circle.
    var avatarColor: String = "F2784B"

    /// Timestamp when this profile was created.
    var createdAt: Date = Date.now

    /// Optional custom avatar photo stored externally.
    @Attribute(.externalStorage)
    var avatarImageData: Data?

    /// CloudKit record name for children received via sharing.
    /// `nil` for locally created children; set for mirrored shared children.
    var sharedRecordName: String?

    /// The artworks belonging to this child. Deletion cascades.
    @Relationship(deleteRule: .cascade, inverse: \Artwork.child)
    var artworks: [Artwork]?

    init(name: String, avatarColor: String, avatarImageData: Data? = nil, createdAt: Date = .now) {
        self.name = name
        self.avatarColor = avatarColor
        self.avatarImageData = avatarImageData
        self.createdAt = createdAt
    }
}
