//
//  Artwork.swift
//  Little Artist
//
//  SwiftData model representing a single piece of child artwork.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftData

/// A single piece of artwork created by a ``Child``.
///
/// Stores the artwork image (externally via SwiftData), a title, caption,
/// optional voice-note URL, and a back-reference to its owning child.
@Model
final class Artwork {
    /// A short title for the artwork (may be empty).
    var title: String = ""

    /// An optional longer description or caption.
    var caption: String = ""

    /// The artwork photograph stored externally for efficient storage.
    @Attribute(.externalStorage)
    var imageData: Data?

    /// Optional voice memo audio data stored externally for efficient storage.
    @Attribute(.externalStorage)
    var voiceNoteData: Data?

    /// Whether this artwork has been starred/favourited by the user.
    var isFavorited: Bool = false

    /// The date this artwork was captured.
    var createdAt: Date = Date.now

    /// The child who created this artwork.
    var child: Child?

    /// Tags applied to this artwork for categorization.
    var tags: [Tag]?

    /// Stable identifier for CloudKit sync matching. Set to the CloudKit
    /// record name for shared artworks, or a UUID for locally created ones.
    /// Used instead of title+date to match artworks across devices so that
    /// editing title or date doesn't create duplicates.
    var syncIdentifier: String?

    init(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
        voiceNoteData: Data? = nil,
        isFavorited: Bool = false,
        createdAt: Date = .now,
        child: Child? = nil,
        tags: [Tag]? = nil,
        syncIdentifier: String? = nil
    ) {
        self.title = title
        self.caption = caption
        self.imageData = imageData
        self.voiceNoteData = voiceNoteData
        self.isFavorited = isFavorited
        self.createdAt = createdAt
        self.child = child
        self.tags = tags
        self.syncIdentifier = syncIdentifier
    }
}
