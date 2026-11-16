//
//  LibraryQueryTests.swift
//  Little ArtistTests
//
//  Pure lookups shared by the gallery, search, Siri and Shortcuts.
//

import Foundation
import SwiftData
import Testing
@testable import Little_Artist

struct LibraryQueryTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // MARK: Children

    @Test("Child lookup ignores case and accents")
    func childLookup() {
        let children = [Child(name: "Zoë", avatarColor: "F2784B"), Child(name: "Leo", avatarColor: "F2784B")]

        #expect(LibraryQuery.children(matching: "zoe", in: children).map(\.name) == ["Zoë"])
        #expect(LibraryQuery.children(matching: "LE", in: children).map(\.name) == ["Leo"])
        #expect(LibraryQuery.children(matching: "", in: children).count == 2)
    }

    // MARK: Artwork search

    @Test("Text search matches title, caption and tags")
    func textSearch() {
        let rocket = Artwork(title: "Rocket", caption: "Blast off")
        let cat = Artwork(title: "Kitty", caption: "Sleepy")
        cat.tags = [Tag(name: "Animals")]
        let all = [rocket, cat]

        #expect(LibraryQuery.artworks(matching: "rock", in: all) == [rocket])
        #expect(LibraryQuery.artworks(matching: "blast", in: all) == [rocket])
        #expect(LibraryQuery.artworks(matching: "animal", in: all) == [cat])
        #expect(LibraryQuery.artworks(matching: "  ", in: all).count == 2)
    }

    // MARK: Latest

    @Test("Latest artwork is the most recent, optionally for one child")
    func latest() {
        let mia = Child(name: "Mia", avatarColor: "F2784B")
        let old = Artwork(title: "Old", createdAt: date(2024, 1, 1), child: mia)
        let newest = Artwork(title: "New", createdAt: date(2025, 6, 1))
        let all = [old, newest]

        #expect(LibraryQuery.latestArtwork(in: all) === newest)
        #expect(LibraryQuery.latestArtwork(in: all, childID: mia.uuid) === old)
    }

    // MARK: On This Day

    @Test("On This Day finds artwork from the same date in earlier years")
    func onThisDay() {
        let now = date(2026, 11, 14)
        let lastYear = Artwork(title: "Last year", createdAt: date(2025, 11, 14))
        let twoYears = Artwork(title: "Two years", createdAt: date(2024, 11, 14))
        let today = Artwork(title: "Today", createdAt: date(2026, 11, 14))
        let otherDay = Artwork(title: "Other", createdAt: date(2025, 11, 13))

        let memories = LibraryQuery.onThisDay(in: [twoYears, today, otherDay, lastYear], now: now, calendar: calendar)

        #expect(memories.map(\.artwork.title) == ["Last year", "Two years"])
        #expect(memories.map(\.yearsAgo) == [1, 2])
    }
}

// MARK: - Identifier Backfill

struct IdentifierBackfillTests {

    @Test("Duplicate identifiers are replaced, keeping the first")
    func reassignsDuplicates() {
        let shared = UUID()
        let first = Child(name: "A", avatarColor: "F2784B")
        let second = Child(name: "B", avatarColor: "F2784B")
        let third = Child(name: "C", avatarColor: "F2784B")
        [first, second, third].forEach { $0.uuid = shared }

        let repaired = IdentifierBackfill.reassignDuplicates([first, second, third], id: \.uuid)

        #expect(repaired == 2)
        #expect(first.uuid == shared)
        #expect(Set([first.uuid, second.uuid, third.uuid]).count == 3)
    }

    @Test("Unique identifiers are left alone")
    func leavesUniqueAlone() {
        let artworks = [Artwork(title: "A"), Artwork(title: "B")]
        let before = artworks.map(\.uuid)

        #expect(IdentifierBackfill.reassignDuplicates(artworks, id: \.uuid) == 0)
        #expect(artworks.map(\.uuid) == before)
    }
}

// MARK: - Spotlight Indexing Hooks

@MainActor
final class SpyIndexer: ContentIndexing {
    var indexedArtworks: [UUID] = []
    var indexedChildren: [UUID] = []
    var removedArtworks: [UUID] = []
    var removedChildren: [UUID] = []

    func index(artwork: Artwork) { indexedArtworks.append(artwork.uuid) }
    func index(child: Child) { indexedChildren.append(child.uuid) }
    func remove(artworkIDs: [UUID]) { removedArtworks += artworkIDs }
    func remove(childIDs: [UUID]) { removedChildren += childIDs }
}

@MainActor
@Suite(.serialized)
struct RepositoryIndexingTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test("Creating and deleting keeps Spotlight in step")
    func indexesWrites() throws {
        let context = try makeContext()
        let spy = SpyIndexer()
        let repo = ArtworkRepository.shared
        repo.indexer = spy
        defer { repo.indexer = nil }

        let child = repo.createChild(name: "Mia", avatarColor: "F2784B", in: context)
        let artwork = repo.createArtwork(title: "Rocket", child: child, in: context)
        #expect(spy.indexedChildren.contains(child.uuid))
        #expect(spy.indexedArtworks == [artwork.uuid])

        let artworkID = artwork.uuid
        let childID = child.uuid
        repo.deleteChild(child, in: context)
        #expect(spy.removedArtworks == [artworkID])
        #expect(spy.removedChildren == [childID])
    }
}

// MARK: - Deleted Model Safety

@MainActor
struct PersistentModelLivenessTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @Test("An inserted artwork is live; after deletion it is not")
    func deletedArtworkIsNotLive() throws {
        let context = try makeContext()
        let artwork = Artwork(title: "Sun")
        context.insert(artwork)
        try context.save()
        #expect(artwork.isLive)

        context.delete(artwork)
        try context.save()
        #expect(!artwork.isLive)
    }

    @Test("Deleting a child makes its cascaded artwork not live")
    func cascadeDeletedArtworkIsNotLive() throws {
        let context = try makeContext()
        let child = ArtworkRepository.shared.createChild(name: "Ivy", avatarColor: "A8C5A0", in: context)
        let artwork = ArtworkRepository.shared.createArtwork(title: "Moon", child: child, in: context)

        ArtworkRepository.shared.deleteChild(child, in: context)

        #expect(!child.isLive)
        #expect(!artwork.isLive)
    }
}

// MARK: - Card Date Label Tests

struct CardDateLabelTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let locale = Locale(identifier: "en_US")

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test("Dates in the current year leave the year out")
    func currentYearOmitsYear() {
        let label = date(2026, 11, 15).cardLabel(relativeTo: date(2026, 12, 1), calendar: calendar, locale: locale)
        #expect(label == "Nov 15")
    }

    @Test("Dates from an earlier year include the year")
    func earlierYearIncludesYear() {
        let label = date(2025, 11, 15).cardLabel(relativeTo: date(2026, 12, 1), calendar: calendar, locale: locale)
        #expect(label.contains("2025"))
        #expect(label.contains("Nov"))
    }
}
