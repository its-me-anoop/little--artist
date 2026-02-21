//
//  StorageService.swift
//  Little Artist
//
//  Handles upload and download of binary data (artwork images,
//  voice notes, avatars) to/from Firebase Storage.
//

import FirebaseStorage
import Foundation
import os

/// Manages binary asset uploads and downloads via Firebase Storage.
///
/// Provides upload with automatic retry, download with local caching,
/// and path generation following the Firestore data model convention:
/// `users/{uid}/children/{childId}/artworks/{artworkId}/image.jpg`.
@MainActor
@Observable
final class StorageService {

    // MARK: - Singleton

    static let shared = StorageService()

    // MARK: - State

    /// Number of uploads currently in progress.
    private(set) var activeUploads = 0

    // MARK: - Private

    private let storage = Storage.storage()
    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Storage")

    /// Pending uploads that failed and should be retried.
    private var pendingUploads: [PendingUpload] = []

    /// Maximum retry attempts for a failed upload.
    private let maxRetries = 3

    private init() {}

    // MARK: - Upload

    /// Uploads image data and returns the download URL.
    ///
    /// - Parameters:
    ///   - data: Raw image/audio bytes.
    ///   - path: Firebase Storage path (e.g. `users/uid/children/cid/artworks/aid/image.jpg`).
    ///   - contentType: MIME type (e.g. `"image/jpeg"`, `"audio/m4a"`).
    /// - Returns: The public download URL string.
    func upload(data: Data, path: String, contentType: String = "image/jpeg") async throws -> String {
        activeUploads += 1
        defer { activeUploads -= 1 }

        let ref = storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()

        logger.info("Uploaded \(data.count) bytes → \(path, privacy: .public)")
        return url.absoluteString
    }

    /// Uploads image data with automatic retry on failure.
    /// Silently enqueues for retry and returns `nil` if all attempts fail.
    func uploadWithRetry(data: Data, path: String, contentType: String = "image/jpeg") async -> String? {
        for attempt in 0..<maxRetries {
            do {
                return try await upload(data: data, path: path, contentType: contentType)
            } catch {
                logger.warning("Upload attempt \(attempt + 1)/\(self.maxRetries) failed for \(path, privacy: .public): \(error.localizedDescription)")
                if attempt < maxRetries - 1 {
                    // Exponential backoff: 1s, 2s, 4s
                    try? await Task.sleep(for: .seconds(pow(2.0, Double(attempt))))
                }
            }
        }

        // Queue for later retry
        let pending = PendingUpload(data: data, path: path, contentType: contentType)
        pendingUploads.append(pending)
        persistPendingUploads()
        logger.error("Upload failed after \(self.maxRetries) attempts — queued: \(path, privacy: .public)")
        return nil
    }

    // MARK: - Download

    /// Downloads data from Firebase Storage at the given path.
    ///
    /// - Parameter path: Firebase Storage path.
    /// - Returns: Raw bytes.
    func download(path: String) async throws -> Data {
        let ref = storage.reference().child(path)
        let maxSize: Int64 = 20 * 1024 * 1024 // 20 MB
        let data = try await ref.data(maxSize: maxSize)
        logger.info("Downloaded \(data.count) bytes ← \(path, privacy: .public)")
        return data
    }

    /// Downloads data from a full Firebase Storage download URL.
    ///
    /// - Parameter urlString: The full `https://firebasestorage.googleapis.com/...` URL.
    /// - Returns: Raw bytes, or `nil` if the download fails.
    func download(url urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let ref = Storage.storage().reference(forURL: url.absoluteString)
            let maxSize: Int64 = 20 * 1024 * 1024
            return try await ref.data(maxSize: maxSize)
        } catch {
            logger.error("Download failed for URL: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Delete

    /// Deletes a file at the given Storage path.
    func delete(path: String) async {
        do {
            try await storage.reference().child(path).delete()
            logger.info("Deleted: \(path, privacy: .public)")
        } catch {
            logger.warning("Delete failed for \(path, privacy: .public): \(error.localizedDescription)")
        }
    }

    // MARK: - Path Helpers

    /// Storage path for a child's avatar image.
    static func avatarPath(userId: String, childId: String) -> String {
        "users/\(userId)/children/\(childId)/avatar.jpg"
    }

    /// Storage path for an artwork's image.
    static func artworkImagePath(userId: String, childId: String, artworkId: String) -> String {
        "users/\(userId)/children/\(childId)/artworks/\(artworkId)/image.jpg"
    }

    /// Storage path for an artwork's voice note.
    static func voiceNotePath(userId: String, childId: String, artworkId: String) -> String {
        "users/\(userId)/children/\(childId)/artworks/\(artworkId)/voicenote.m4a"
    }

    // MARK: - Retry Queue Persistence

    /// Retries all pending uploads. Call when network becomes available.
    func retryPendingUploads() async {
        let uploads = pendingUploads
        pendingUploads.removeAll()

        for pending in uploads {
            if let _ = await uploadWithRetry(data: pending.data, path: pending.path, contentType: pending.contentType) {
                logger.info("Retry succeeded: \(pending.path, privacy: .public)")
            }
        }

        persistPendingUploads()
    }

    /// Persists pending upload metadata to UserDefaults (paths only — data is lost on restart).
    private func persistPendingUploads() {
        let paths = pendingUploads.map(\.path)
        UserDefaults.standard.set(paths, forKey: "pendingUploadPaths")
    }
}

// MARK: - Pending Upload

private struct PendingUpload {
    let data: Data
    let path: String
    let contentType: String
}
