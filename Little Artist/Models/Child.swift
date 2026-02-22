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

    /// Legacy sync record name (deprecated — use `firestoreId` instead).
    /// `nil` for locally created children; set for mirrored shared children.
    /// - Note: Deprecated in V7; replaced by ``firestoreId``. Kept for migration.
    var sharedRecordName: String?

    /// Firestore document path (e.g. `"users/{uid}/children/{id}"`).
    /// `nil` for children that have not yet been synced to Firebase.
    var firestoreId: String?

    /// Whether this child profile was received via sharing (not owned by the current user).
    var isShared: Bool = false

    /// Firebase UID of the profile owner. `nil` for locally owned children.
    var ownerUserId: String?

    /// The artworks belonging to this child. Deletion cascades.
    @Relationship(deleteRule: .cascade, inverse: \Artwork.child)
    var artworks: [Artwork]?

    init(
        name: String,
        avatarColor: String,
        avatarImageData: Data? = nil,
        createdAt: Date = .now,
        firestoreId: String? = nil,
        isShared: Bool = false,
        ownerUserId: String? = nil
    ) {
        self.name = name
        self.avatarColor = avatarColor
        self.avatarImageData = avatarImageData
        self.createdAt = createdAt
        self.firestoreId = firestoreId
        self.isShared = isShared
        self.ownerUserId = ownerUserId
    }
}
