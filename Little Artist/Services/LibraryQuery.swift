//
//  LibraryQuery.swift
//  Little Artist
//
//  Pure, side-effect-free lookups over children and artwork, shared by the
//  gallery, search, Siri, Shortcuts and Spotlight.
//

import Foundation
import SwiftData

/// A single "On This Day" memory: one artwork and how many years ago it was made.
struct MemoryEntry: Identifiable {
    let artwork: Artwork
    let yearsAgo: Int
    var id: PersistentIdentifier { artwork.persistentModelID }
}

enum LibraryQuery {

    private static let compareOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    /// Children whose name contains `name`. An empty query returns everyone.
    static func children(matching name: String, in children: [Child]) -> [Child] {
        let query = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return children }
        return children.filter { $0.name.range(of: query, options: compareOptions) != nil }
    }

    /// Artworks whose title, caption or tags contain `text`.
    static func artworks(matching text: String, in artworks: [Artwork]) -> [Artwork] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return artworks }
        func matches(_ value: String) -> Bool { value.range(of: query, options: compareOptions) != nil }
        return artworks.filter { artwork in
            matches(artwork.title)
                || matches(artwork.caption)
                || (artwork.tags ?? []).contains { matches($0.name) }
        }
    }

    /// The most recent artwork, optionally limited to one child.
    static func latestArtwork(in artworks: [Artwork], childID: UUID? = nil) -> Artwork? {
        artworks
            .filter { childID == nil || $0.child?.uuid == childID }
            .max { $0.createdAt < $1.createdAt }
    }

    /// Artwork made on today's month and day in earlier years, newest first.
    static func onThisDay(in artworks: [Artwork], now: Date = .now, calendar: Calendar = .current) -> [MemoryEntry] {
        let today = calendar.dateComponents([.year, .month, .day], from: now)
        guard let year = today.year else { return [] }

        return artworks.compactMap { artwork -> MemoryEntry? in
            let made = calendar.dateComponents([.year, .month, .day], from: artwork.createdAt)
            guard made.month == today.month, made.day == today.day, let madeYear = made.year else { return nil }
            let yearsAgo = year - madeYear
            return yearsAgo >= 1 ? MemoryEntry(artwork: artwork, yearsAgo: yearsAgo) : nil
        }
        .sorted { $0.yearsAgo < $1.yearsAgo }
    }
}
