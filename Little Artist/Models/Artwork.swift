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
    var title: String

    /// An optional longer description or caption.
    var caption: String

    /// The artwork photograph stored externally for efficient storage.
    @Attribute(.externalStorage)
    var imageData: Data?

    /// File path or URL to an associated voice-note recording (future feature).
    var voiceNoteURL: String?

    /// Whether this artwork has been starred/favourited by the user.
    var isFavorited: Bool

    /// The date this artwork was captured.
    var createdAt: Date

    /// The child who created this artwork.
    var child: Child?

    init(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
        voiceNoteURL: String? = nil,
        isFavorited: Bool = false,
        createdAt: Date = .now,
        child: Child? = nil
    ) {
        self.title = title
        self.caption = caption
        self.imageData = imageData
        self.voiceNoteURL = voiceNoteURL
        self.isFavorited = isFavorited
        self.createdAt = createdAt
        self.child = child
    }
}
