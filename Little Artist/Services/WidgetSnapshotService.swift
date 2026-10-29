//
//  WidgetSnapshotService.swift
//  Little Artist
//
//  Keeps the Home Screen widget's snapshot up to date. Picks a small,
//  rotating set of artworks — "On This Day" anniversaries first, then
//  favourites, then recent pieces — and writes downscaled thumbnails into
//  the App Group container for the widget to read.
//

import Foundation
import ImageIO
import SwiftData
import UniformTypeIdentifiers
import WidgetKit

/// Writes ``WidgetSnapshot`` files and reloads widget timelines.
nonisolated enum WidgetSnapshotService {

    /// Maximum artworks kept in the widget rotation.
    static let maxEntries = 12

    /// Longest edge of widget thumbnails, in pixels. Large widgets on the
    /// biggest iPads are ~1,000pt wide at 2x, but artwork is shown with
    /// `scaledToFill`, so 900px keeps it crisp while staying small on disk.
    static let thumbnailMaxPixels = 900

    /// Rebuilds the snapshot in the background. Safe to call often; a
    /// newer call simply overwrites the previous result.
    static func refresh(container: ModelContainer) {
        Task.detached(priority: .utility) {
            do {
                try write(container: container)
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.artworkWidgetKind)
            } catch {
                // The widget keeps showing its last snapshot; nothing to surface.
            }
        }
    }

    // MARK: - Selection

    /// Lightweight description of an artwork used for picking entries.
    struct Candidate {
        let id: String
        let createdAt: Date
        let isFavorited: Bool
    }

    /// Chooses which artworks appear in the widget, in display order.
    static func select(
        _ candidates: [Candidate],
        today: Date = .now,
        calendar: Calendar = .current,
        limit: Int = maxEntries
    ) -> [(id: String, reason: WidgetArtworkEntry.Reason, yearsAgo: Int)] {
        let todayParts = calendar.dateComponents([.year, .month, .day], from: today)
        var picked: [(id: String, reason: WidgetArtworkEntry.Reason, yearsAgo: Int)] = []
        var seen = Set<String>()

        func add(_ candidate: Candidate, _ reason: WidgetArtworkEntry.Reason) {
            guard picked.count < limit, seen.insert(candidate.id).inserted else { return }
            let years = calendar.dateComponents([.year], from: candidate.createdAt, to: today).year ?? 0
            picked.append((candidate.id, reason, max(years, 0)))
        }

        // 1. Anniversaries (same month and day, at least a year ago).
        for candidate in candidates.sorted(by: { $0.createdAt < $1.createdAt }) {
            let parts = calendar.dateComponents([.year, .month, .day], from: candidate.createdAt)
            if parts.month == todayParts.month, parts.day == todayParts.day,
               let year = parts.year, let thisYear = todayParts.year, year < thisYear {
                add(candidate, .onThisDay)
            }
        }
        // 2. Favourites, newest first.
        for candidate in candidates.filter(\.isFavorited).sorted(by: { $0.createdAt > $1.createdAt }) {
            add(candidate, .favorite)
        }
        // 3. Recent artwork.
        for candidate in candidates.sorted(by: { $0.createdAt > $1.createdAt }) {
            add(candidate, .recent)
        }
        return picked
    }

    // MARK: - Writing

    private static func write(container: ModelContainer) throws {
        guard let directory = WidgetSnapshot.directory,
              let imagesDirectory = WidgetSnapshot.imagesDirectory,
              let manifestURL = WidgetSnapshot.manifestURL else { return }

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let context = ModelContext(container)
        let artworks = try context.fetch(FetchDescriptor<Artwork>())

        var byID: [String: Artwork] = [:]
        var candidates: [Candidate] = []
        for artwork in artworks where artwork.thumbnailData != nil || artwork.imageData != nil {
            let id = stableID(for: artwork)
            byID[id] = artwork
            candidates.append(Candidate(id: id, createdAt: artwork.createdAt, isFavorited: artwork.isFavorited))
        }

        var entries: [WidgetArtworkEntry] = []
        for pick in select(candidates) {
            guard let artwork = byID[pick.id],
                  let source = artwork.imageData ?? artwork.thumbnailData,
                  let jpeg = downscaledJPEG(source) else { continue }
            let fileName = "\(pick.id).jpg"
            try jpeg.write(to: imagesDirectory.appendingPathComponent(fileName), options: .atomic)
            entries.append(WidgetArtworkEntry(
                id: pick.id,
                title: artwork.title,
                childName: artwork.child?.name ?? "",
                createdAt: artwork.createdAt,
                reason: pick.reason,
                yearsAgo: pick.yearsAgo,
                imageFileName: fileName
            ))
        }

        let snapshot = WidgetSnapshot(generatedAt: .now, totalArtworks: artworks.count, entries: entries)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder.snapshot.encode(snapshot).write(to: manifestURL, options: .atomic)

        // Remove thumbnails no longer referenced.
        let keep = Set(entries.map(\.imageFileName))
        for file in (try? fileManager.contentsOfDirectory(atPath: imagesDirectory.path)) ?? [] where !keep.contains(file) {
            try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(file))
        }
    }

    /// A file-name-safe identifier that is stable across launches.
    private static func stableID(for artwork: Artwork) -> String {
        let raw = (try? JSONEncoder().encode(artwork.persistentModelID))
            .map { $0.base64EncodedString() } ?? "\(artwork.createdAt.timeIntervalSince1970)"
        // Hash to a short hex string so it is safe as a file name.
        var hash: UInt64 = 1469598103934665603
        for byte in raw.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1099511628211
        }
        return String(hash, radix: 16)
    }

    /// Downscales image data with ImageIO (memory-efficient, thread-safe).
    static func downscaledJPEG(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaxPixels,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.75] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
