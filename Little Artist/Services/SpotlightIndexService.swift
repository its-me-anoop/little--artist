//
//  SpotlightIndexService.swift
//  Little Artist
//
//  Indexes children and artwork as App Entities so they appear in Spotlight
//  and Siri can find them by name ("show Mia's rocket").
//

import AppIntents
import CoreSpotlight
import Foundation
import os
import SwiftData

/// Keeps the system search index in step with the library. Abstracted so
/// the repository can be tested without Core Spotlight.
@MainActor
protocol ContentIndexing: AnyObject {
    func index(artwork: Artwork)
    func index(child: Child)
    func remove(artworkIDs: [UUID])
    func remove(childIDs: [UUID])
}

/// `ContentIndexing` backed by Core Spotlight's App Entity index.
@MainActor
final class SpotlightIndexService: ContentIndexing {

    static let shared = SpotlightIndexService()

    private let index = CSSearchableIndex.default()
    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Spotlight")

    func index(artwork: Artwork) {
        let entity = ArtworkEntity(artwork: artwork)
        Task { await submit([entity]) }
    }

    func index(child: Child) {
        let entity = ChildEntity(child: child)
        Task { await submit([entity]) }
    }

    func remove(artworkIDs: [UUID]) {
        guard !artworkIDs.isEmpty else { return }
        Task {
            do {
                try await index.deleteAppEntities(identifiedBy: artworkIDs, ofType: ArtworkEntity.self)
            } catch {
                logger.error("Spotlight delete failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func remove(childIDs: [UUID]) {
        guard !childIDs.isEmpty else { return }
        Task {
            do {
                try await index.deleteAppEntities(identifiedBy: childIDs, ofType: ChildEntity.self)
            } catch {
                logger.error("Spotlight delete failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Re-indexes everything; run once per launch so iCloud changes from
    /// other devices become searchable too.
    func reindexAll(in context: ModelContext) {
        let children = (try? context.fetch(FetchDescriptor<Child>())) ?? []
        let artworks = (try? context.fetch(FetchDescriptor<Artwork>())) ?? []
        let childEntities = children.map(ChildEntity.init)
        let artworkEntities = artworks.map(ArtworkEntity.init)
        Task {
            await submit(childEntities)
            await submit(artworkEntities)
        }
    }

    private func submit<Entity: IndexedEntity>(_ entities: [Entity]) async {
        guard !entities.isEmpty else { return }
        do {
            try await index.indexAppEntities(entities)
        } catch {
            logger.error("Spotlight index failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
