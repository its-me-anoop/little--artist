//
//  WidgetSnapshot.swift
//  Little Artist (shared by the app and the widget extension)
//
//  A tiny, file-based hand-off between the app and its Home Screen widget.
//  The app writes a JSON manifest plus small JPEG thumbnails into the
//  shared App Group container; the widget only ever reads them. Keeping
//  the widget off the SwiftData/CloudKit store avoids sharing the database
//  across processes.
//

import Foundation

/// One artwork the widget can display.
nonisolated struct WidgetArtworkEntry: Codable, Hashable, Sendable {
    /// Why this artwork was picked — drives the widget's caption.
    enum Reason: String, Codable, Sendable {
        case onThisDay
        case favorite
        case recent
    }

    let id: String
    let title: String
    let childName: String
    let createdAt: Date
    let reason: Reason
    /// Whole years since the artwork was made (for "On This Day").
    let yearsAgo: Int
    /// File name of the thumbnail inside ``WidgetSnapshot/imagesDirectory``.
    let imageFileName: String
}

/// The manifest the app writes and the widget reads.
nonisolated struct WidgetSnapshot: Codable, Sendable {
    var generatedAt: Date
    var totalArtworks: Int
    var entries: [WidgetArtworkEntry]

    static let empty = WidgetSnapshot(generatedAt: .distantPast, totalArtworks: 0, entries: [])

    // MARK: - Storage Locations

    /// App Group shared by the app and the widget extension.
    static let appGroupID = "group.uk.co.flutterly.Little-Artist"

    /// Widget kind identifier (must match the widget's `kind`).
    static let artworkWidgetKind = "LittleArtistArtworkWidget"

    /// Root folder for snapshot files, or `nil` if the App Group is unavailable.
    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("WidgetSnapshot", isDirectory: true)
    }

    static var manifestURL: URL? {
        directory?.appendingPathComponent("snapshot.json")
    }

    static var imagesDirectory: URL? {
        directory?.appendingPathComponent("Images", isDirectory: true)
    }

    // MARK: - Reading

    /// Loads the most recent snapshot, or ``empty`` when none exists.
    static func load() -> WidgetSnapshot {
        guard let url = manifestURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder.snapshot.decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    /// The full file URL for an entry's thumbnail.
    static func imageURL(for entry: WidgetArtworkEntry) -> URL? {
        imagesDirectory?.appendingPathComponent(entry.imageFileName)
    }
}

nonisolated extension JSONEncoder {
    static var snapshot: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

nonisolated extension JSONDecoder {
    static var snapshot: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
