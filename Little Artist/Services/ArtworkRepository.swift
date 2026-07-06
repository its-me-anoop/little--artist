//
//  ArtworkRepository.swift
//  Little Artist
//
//  Central SwiftData CRUD for children and artwork. The CloudKit-backed
//  ModelContainer mirrors every write to the user's private iCloud
//  database automatically — no explicit sync code needed.
//

import Foundation
import SwiftData

/// Central store for creating, updating, and deleting children and
/// artworks. All writes land in SwiftData; iCloud sync is automatic.
@MainActor
@Observable
final class ArtworkRepository {

    /// Singleton shared instance.
    static let shared = ArtworkRepository()

    /// The app's model container, set once at launch. Used by App
    /// Intents that need data access outside the SwiftUI environment.
    var modelContainer: ModelContainer?

    private init() {}

    /// Whether voice notes may be attached (premium feature).
    private var canUsePremiumArtworkFeatures: Bool {
        PremiumManager.isPremium
    }

    // MARK: - Children

    /// Creates a new child profile.
    @discardableResult
    func createChild(
        name: String,
        avatarColor: String,
        avatarImageData: Data? = nil,
        in modelContext: ModelContext
    ) -> Child {
        let child = Child(
            name: name,
            avatarColor: avatarColor,
            avatarImageData: avatarImageData
        )
        modelContext.insert(child)
        try? modelContext.save()
        return child
    }

    /// Updates an existing child profile.
    func updateChild(
        _ child: Child,
        name: String? = nil,
        avatarColor: String? = nil,
        avatarImageData: Data? = nil,
        in modelContext: ModelContext
    ) {
        if let name { child.name = name }
        if let avatarColor { child.avatarColor = avatarColor }
        if let avatarImageData { child.avatarImageData = avatarImageData }
        try? modelContext.save()
    }

    /// Deletes a child and all their artworks (cascade).
    func deleteChild(_ child: Child, in modelContext: ModelContext) {
        modelContext.delete(child)
        try? modelContext.save()
    }

    // MARK: - Artworks

    /// Creates a new artwork for a child.
    @discardableResult
    func createArtwork(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        voiceNoteData: Data? = nil,
        isFavorited: Bool = false,
        createdAt: Date = .now,
        child: Child,
        tags: [Tag]? = nil,
        in modelContext: ModelContext
    ) -> Artwork {
        let artwork = Artwork(
            title: title,
            caption: caption,
            imageData: imageData,
            thumbnailData: thumbnailData,
            voiceNoteData: canUsePremiumArtworkFeatures ? voiceNoteData : nil,
            isFavorited: isFavorited,
            createdAt: createdAt,
            child: child,
            tags: tags
        )
        modelContext.insert(artwork)
        try? modelContext.save()
        return artwork
    }

    /// Updates an existing artwork.
    func updateArtwork(
        _ artwork: Artwork,
        title: String? = nil,
        caption: String? = nil,
        imageData: Data? = nil,
        voiceNoteData: Data? = nil,
        isFavorited: Bool? = nil,
        createdAt: Date? = nil,
        tags: [Tag]? = nil,
        in modelContext: ModelContext
    ) {
        if let title { artwork.title = title }
        if let caption { artwork.caption = caption }
        if let imageData { artwork.imageData = imageData }
        if let voiceNoteData, canUsePremiumArtworkFeatures {
            artwork.voiceNoteData = voiceNoteData
        }
        if let isFavorited { artwork.isFavorited = isFavorited }
        if let createdAt { artwork.createdAt = createdAt }
        if let tags { artwork.tags = tags }
        try? modelContext.save()
    }

    /// Deletes an artwork.
    func deleteArtwork(_ artwork: Artwork, in modelContext: ModelContext) {
        modelContext.delete(artwork)
        try? modelContext.save()
    }
}
