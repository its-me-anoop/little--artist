//
//  LibraryEntities.swift
//  Little Artist
//
//  App Entities that expose children and artwork to Siri, Shortcuts,
//  Spotlight and Apple Intelligence. Indexed entities are searchable in
//  Spotlight and let Siri resolve names like "Mia" or "the rocket".
//

import AppIntents
import CoreSpotlight
import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Child Entity

struct ChildEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Child",
        numericFormat: "\(placeholder: .int) children"
    )
    static let defaultQuery = ChildEntityQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Artwork Count")
    var artworkCount: Int

    let avatarData: Data?

    init(child: Child) {
        id = child.uuid
        avatarData = child.avatarImageData
        name = child.name
        artworkCount = child.artworks?.count ?? 0
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(artworkCount) artworks",
            image: avatarData.map { .init(data: $0) } ?? .init(systemName: "figure.child")
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.contentDescription = String(localized: "\(name)'s art collection")
        attributes.keywords = ["art", "drawings", "gallery", name]
        attributes.thumbnailData = avatarData
        return attributes
    }
}

struct ChildEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ChildEntity] {
        try LibraryStore.children().filter { identifiers.contains($0.uuid) }.map(ChildEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [ChildEntity] {
        LibraryQuery.children(matching: string, in: try LibraryStore.children()).map(ChildEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ChildEntity] {
        try LibraryStore.children().map(ChildEntity.init)
    }
}

// MARK: - Artwork Entity

struct ArtworkEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Artwork",
        numericFormat: "\(placeholder: .int) artworks"
    )
    static let defaultQuery = ArtworkEntityQuery()

    let id: UUID

    @Property(title: "Title")
    var title: String

    @Property(title: "Caption")
    var caption: String

    @Property(title: "Artist")
    var childName: String

    @Property(title: "Date Created")
    var createdAt: Date

    @Property(title: "Favorite")
    var isFavorite: Bool

    let thumbnailData: Data?

    init(artwork: Artwork) {
        id = artwork.uuid
        thumbnailData = artwork.thumbnailData
        title = artwork.title.isEmpty ? String(localized: "Untitled") : artwork.title
        caption = artwork.caption
        childName = artwork.child?.name ?? ""
        createdAt = artwork.createdAt
        isFavorite = artwork.isFavorited
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: childName.isEmpty ? nil : "by \(childName)",
            image: thumbnailData.map { .init(data: $0) } ?? .init(systemName: "paintpalette.fill")
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.contentDescription = caption.isEmpty ? String(localized: "Artwork by \(childName)") : caption
        attributes.contentCreationDate = createdAt
        attributes.thumbnailData = thumbnailData
        attributes.keywords = ["art", "drawing", childName]
        return attributes
    }
}

extension ArtworkEntity: Transferable {
    /// Lets Siri and Apple Intelligence pass the picture to other apps,
    /// for example "send this to Grandma".
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { entity in
            try await MainActor.run {
                guard let data = try LibraryStore.artwork(id: entity.id)?.imageData else {
                    throw CocoaError(.fileNoSuchFile)
                }
                return data
            }
        }
    }
}

struct ArtworkEntityQuery: EntityStringQuery {

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ArtworkEntity] {
        try LibraryStore.artworks().filter { identifiers.contains($0.uuid) }.map(ArtworkEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [ArtworkEntity] {
        LibraryQuery.artworks(matching: string, in: try LibraryStore.artworks()).prefix(20).map(ArtworkEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [ArtworkEntity] {
        try LibraryStore.artworks().prefix(10).map(ArtworkEntity.init)
    }
}

// MARK: - Store Access

/// Errors raised when intents run before the library is ready.
enum LibraryStoreError: Error, CustomLocalizedStringResourceConvertible {
    case unavailable

    var localizedStringResource: LocalizedStringResource {
        "Open Little Artist once to set up your gallery."
    }
}

/// Read access to the library for intents, which run outside SwiftUI.
/// Uses the app's main context so changes (e.g. favoriting) show up in
/// the UI immediately.
@MainActor
enum LibraryStore {

    static var context: ModelContext {
        get throws {
            guard let container = ArtworkRepository.shared.modelContainer else {
                throw LibraryStoreError.unavailable
            }
            return container.mainContext
        }
    }

    static func children() throws -> [Child] {
        try context.fetch(FetchDescriptor<Child>(sortBy: [SortDescriptor(\.createdAt)]))
    }

    static func artworks() throws -> [Artwork] {
        try context.fetch(FetchDescriptor<Artwork>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    static func child(id: UUID) throws -> Child? {
        var descriptor = FetchDescriptor<Child>(predicate: #Predicate { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    static func artwork(id: UUID) throws -> Artwork? {
        var descriptor = FetchDescriptor<Artwork>(predicate: #Predicate { $0.uuid == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
