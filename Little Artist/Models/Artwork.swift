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

    /// A smaller version of the artwork image for gallery/card views.
    /// Generated at ingest time. `nil` for artworks created before this feature.
    @Attribute(.externalStorage)
    var thumbnailData: Data?

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

    /// Comments left by family members on this artwork.
    @Relationship(deleteRule: .cascade, inverse: \Comment.artwork)
    var comments: [Comment]?

    /// Legacy sync identifier (deprecated — use `firestoreId` instead).
    /// - Note: Deprecated in V7; replaced by ``firestoreId``. Kept for migration.
    var syncIdentifier: String?

    /// Firestore document path (e.g. `"users/{uid}/children/{cid}/artworks/{id}"`).
    /// `nil` for artworks that have not yet been synced to Firebase.
    var firestoreId: String?

    /// Firebase Storage download URL for the artwork image.
    /// Used by shared-device recipients to download the image from Firebase.
    var imageURL: String?

    /// Firebase Storage download URL for the voice note.
    /// Used by shared-device recipients to download the voice note from Firebase.
    var voiceNoteURL: String?

    init(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        voiceNoteData: Data? = nil,
        isFavorited: Bool = false,
        createdAt: Date = .now,
        child: Child? = nil,
        tags: [Tag]? = nil,
        syncIdentifier: String? = nil,
        firestoreId: String? = nil,
        imageURL: String? = nil,
        voiceNoteURL: String? = nil
    ) {
        self.title = title
        self.caption = caption
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.voiceNoteData = voiceNoteData
        self.isFavorited = isFavorited
        self.createdAt = createdAt
        self.child = child
        self.tags = tags
        self.syncIdentifier = syncIdentifier
        self.firestoreId = firestoreId
        self.imageURL = imageURL
        self.voiceNoteURL = voiceNoteURL
    }
}

enum ArtworkDate {
    /// Anchor day-only artwork dates to midday so timezone changes don't shift them across days.
    static func dayAnchored(
        _ date: Date,
        calendar: Calendar = .current,
        offsetSeconds: TimeInterval = 0
    ) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0

        let baseDate = calendar.date(from: components) ?? date
        return baseDate.addingTimeInterval(offsetSeconds)
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: dayAnchored(date, calendar: calendar))
    }
}
