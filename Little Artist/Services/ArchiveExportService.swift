//
//  ArchiveExportService.swift
//  Little Artist
//
//  "Your art is always yours." Exports the whole collection — every image,
//  every voice memo, plus a spreadsheet-friendly index — as a ZIP, or saves
//  every artwork straight into the Photos library. Free for everyone,
//  including people whose subscription has ended: no lock-in, ever.
//

import Foundation
import Photos
import SwiftData
import UIKit

/// Builds full-collection exports off the main thread.
nonisolated enum ArchiveExportService {

    /// Progress reported while an export runs (0...1).
    typealias ProgressHandler = @MainActor @Sendable (Double) -> Void

    enum ExportError: LocalizedError {
        case nothingToExport
        case photosAccessDenied
        case zipFailed

        var errorDescription: String? {
            switch self {
            case .nothingToExport:
                return "There's no artwork to export yet."
            case .photosAccessDenied:
                return "Little Artist needs permission to add photos. You can allow it in Settings › Privacy & Security › Photos."
            case .zipFailed:
                return "The archive couldn't be created. Please try again."
            }
        }
    }

    // MARK: - ZIP Archive

    /// Exports every artwork into a ZIP laid out as
    /// `Little Artist Archive/<Child>/<date> <title>.jpg` (+ `.m4a` voice
    /// memos) with an `index.csv` at the root. Returns the ZIP's file URL.
    static func exportZIP(
        container: ModelContainer,
        progress: @escaping ProgressHandler
    ) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            let artworks = try context.fetch(
                FetchDescriptor<Artwork>(sortBy: [SortDescriptor(\.createdAt)])
            )
            guard !artworks.isEmpty else { throw ExportError.nothingToExport }

            let fileManager = FileManager.default
            let stamp = Self.fileDateFormatter.string(from: .now)
            let workDir = fileManager.temporaryDirectory
                .appendingPathComponent("archive-\(UUID().uuidString)", isDirectory: true)
            let root = workDir.appendingPathComponent("Little Artist Archive \(stamp)", isDirectory: true)
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? fileManager.removeItem(at: workDir) }

            var csv = "Artist,Date,Title,Caption,Tags,Favourite,Image,Voice Memo\n"
            var usedNames = Set<String>()

            for (index, artwork) in artworks.enumerated() {
                let childName = artwork.child?.name.nonEmpty ?? "Unassigned"
                let childDir = root.appendingPathComponent(Self.sanitized(childName), isDirectory: true)
                try fileManager.createDirectory(at: childDir, withIntermediateDirectories: true)

                let date = Self.fileDateFormatter.string(from: artwork.createdAt)
                let title = artwork.title.nonEmpty ?? "Artwork"
                let base = Self.uniqueName(
                    "\(date) \(Self.sanitized(title))",
                    in: Self.sanitized(childName),
                    used: &usedNames
                )

                var imagePath = ""
                if let data = artwork.imageData ?? artwork.thumbnailData {
                    let url = childDir.appendingPathComponent(base).appendingPathExtension("jpg")
                    try data.write(to: url)
                    imagePath = "\(Self.sanitized(childName))/\(url.lastPathComponent)"
                }

                var voicePath = ""
                if let voice = artwork.voiceNoteData {
                    let url = childDir.appendingPathComponent(base).appendingPathExtension("m4a")
                    try voice.write(to: url)
                    voicePath = "\(Self.sanitized(childName))/\(url.lastPathComponent)"
                }

                let tags = (artwork.tags ?? []).map(\.name).sorted().joined(separator: "; ")
                csv += [
                    childName, date, artwork.title, artwork.caption, tags,
                    artwork.isFavorited ? "Yes" : "No", imagePath, voicePath,
                ].map(Self.csvField).joined(separator: ",") + "\n"

                let fraction = Double(index + 1) / Double(artworks.count) * 0.9
                await progress(fraction)
            }

            try csv.write(to: root.appendingPathComponent("index.csv"), atomically: true, encoding: .utf8)

            let zipURL = try Self.zip(directory: root)
            await progress(1)
            return zipURL
        }.value
    }

    /// Zips a directory using the system file coordinator (no third-party
    /// code). Returns a stable copy in the temporary directory.
    private static func zip(directory: URL) throws -> URL {
        var coordinatorError: NSError?
        var result: Result<URL, Error> = .failure(ExportError.zipFailed)

        NSFileCoordinator().coordinate(
            readingItemAt: directory,
            options: [.forUploading],
            error: &coordinatorError
        ) { zippedURL in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(directory.lastPathComponent)
                .appendingPathExtension("zip")
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: zippedURL, to: destination)
                result = .success(destination)
            } catch {
                result = .failure(error)
            }
        }

        if let coordinatorError { throw coordinatorError }
        return try result.get()
    }

    // MARK: - Save to Photos

    /// Saves every artwork image to the Photos library, keeping each
    /// artwork's original date. Returns the number of images saved.
    static func saveAllToPhotos(
        container: ModelContainer,
        progress: @escaping ProgressHandler
    ) async throws -> Int {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.photosAccessDenied
        }

        return try await Task.detached(priority: .userInitiated) {
            let context = ModelContext(container)
            let artworks = try context.fetch(
                FetchDescriptor<Artwork>(sortBy: [SortDescriptor(\.createdAt)])
            )
            let items: [(Data, Date)] = artworks.compactMap { artwork in
                guard let data = artwork.imageData ?? artwork.thumbnailData else { return nil }
                return (data, artwork.createdAt)
            }
            guard !items.isEmpty else { throw ExportError.nothingToExport }

            // Save in small batches so memory stays flat on big collections.
            let batchSize = 20
            var saved = 0
            for start in stride(from: 0, to: items.count, by: batchSize) {
                let batch = Array(items[start..<min(start + batchSize, items.count)])
                try await PHPhotoLibrary.shared().performChanges {
                    for (data, date) in batch {
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, data: data, options: nil)
                        request.creationDate = date
                    }
                }
                saved += batch.count
                await progress(Double(saved) / Double(items.count))
            }
            return saved
        }.value
    }

    // MARK: - Helpers

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Makes a string safe to use as a file or folder name.
    static func sanitized(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.newlines).union(.controlCharacters)
        let cleaned = name.components(separatedBy: invalid).joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)
        let trimmed = String(cleaned.prefix(80))
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    /// Appends " (2)", " (3)" … when a name already exists in a folder.
    private static func uniqueName(_ base: String, in folder: String, used: inout Set<String>) -> String {
        var candidate = base
        var counter = 2
        while used.contains("\(folder)/\(candidate)") {
            candidate = "\(base) (\(counter))"
            counter += 1
        }
        used.insert("\(folder)/\(candidate)")
        return candidate
    }

    /// Quotes a CSV field per RFC 4180.
    static func csvField(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

private extension String {
    /// `nil` when the string is empty or only whitespace.
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
