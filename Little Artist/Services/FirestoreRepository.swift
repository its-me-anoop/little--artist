//
//  FirestoreRepository.swift
//  Little Artist
//
//  Central write layer for all Firestore CRUD operations.
//  Every mutation in the app goes through this repository:
//  1. Optimistic write to SwiftData (immediate UI update)
//  2. Async write to Firestore (queued if offline)
//  3. Binary upload to Firebase Storage if needed
//

import FirebaseFirestore
import Foundation
import os
import SwiftData

/// All Firestore CRUD for children, artworks, and sharing.
///
/// Write methods follow a dual-write pattern:
/// - Synchronous insert/update to the local `ModelContext` (SwiftData)
/// - Asynchronous write to Firestore (via Firebase SDK offline queue)
/// - Binary data uploaded to Firebase Storage in the background
///
/// For non-premium or sync-disabled users, the Firestore writes are skipped
/// and only the local SwiftData write executes.
@MainActor
@Observable
final class FirestoreRepository {

    // MARK: - Singleton

    static let shared = FirestoreRepository()

    // MARK: - Dependencies

    var modelContainer: ModelContainer?
    private let db = Firestore.firestore()
    private let auth = FirebaseAuthService.shared
    private let storage = StorageService.shared
    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Repository")

    /// Set of Firestore document IDs written by THIS device this session.
    /// Used by `FirestoreSyncService` to skip echo writes from snapshot listeners.
    private(set) var localWriteIds: Set<String> = []

    /// Whether Firestore sync is active (premium + signed in + enabled).
    var isSyncActive: Bool {
        PremiumManager.isPremium
        && auth.isLinkedWithApple
        && UserDefaults.standard.bool(forKey: "firebaseSyncEnabled")
    }

    private init() {}

    // MARK: - Context Helper

    private var context: ModelContext? {
        guard let container = modelContainer else { return nil }
        return ModelContext(container)
    }

    // MARK: - Children

    /// Creates a new child profile locally and optionally syncs to Firestore.
    ///
    /// - Parameters:
    ///   - name: Child's display name.
    ///   - avatarColor: Hex colour string for the default avatar.
    ///   - avatarImageData: Optional custom avatar photo.
    ///   - modelContext: The view's model context for the local insert.
    /// - Returns: The created `Child` instance.
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

        // Async Firestore sync
        if isSyncActive, let userId = auth.userId {
            Task {
                await syncChildToFirestore(child, userId: userId, avatarImageData: avatarImageData)
            }
        }

        return child
    }

    /// Updates an existing child profile and syncs changes to Firestore.
    func updateChild(
        _ child: Child,
        name: String? = nil,
        avatarColor: String? = nil,
        avatarImageData: Data? = nil,
        in modelContext: ModelContext
    ) {
        // Local update
        if let name { child.name = name }
        if let avatarColor { child.avatarColor = avatarColor }
        if let avatarImageData { child.avatarImageData = avatarImageData }

        // Firestore sync
        if isSyncActive, let userId = auth.userId, let firestoreId = child.firestoreId {
            Task {
                await updateChildInFirestore(
                    firestoreId: firestoreId,
                    userId: userId,
                    child: child,
                    avatarImageData: avatarImageData
                )
            }
        }
    }

    /// Deletes a child and all its artworks locally and from Firestore.
    func deleteChild(_ child: Child, in modelContext: ModelContext) {
        let firestoreId = child.firestoreId
        let userId = auth.userId

        // Local delete (cascades to artworks via SwiftData relationship)
        modelContext.delete(child)

        // Firestore delete
        if isSyncActive, let userId, let firestoreId {
            Task {
                await deleteChildFromFirestore(firestoreId: firestoreId, userId: userId)
            }
        }
    }

    // MARK: - Artworks

    /// Creates a new artwork locally and optionally syncs to Firestore.
    @discardableResult
    func createArtwork(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
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
            voiceNoteData: voiceNoteData,
            isFavorited: isFavorited,
            createdAt: createdAt,
            child: child,
            tags: tags,
            syncIdentifier: UUID().uuidString
        )
        modelContext.insert(artwork)

        // Async Firestore sync
        if isSyncActive, let userId = auth.userId, let childFirestoreId = child.firestoreId {
            Task {
                await syncArtworkToFirestore(
                    artwork,
                    userId: userId,
                    childFirestoreId: childFirestoreId,
                    imageData: imageData,
                    voiceNoteData: voiceNoteData
                )
            }
        }

        return artwork
    }

    /// Creates multiple artworks in batch (e.g. scanner import).
    func batchCreateArtworks(
        items: [(title: String, imageData: Data?, createdAt: Date)],
        child: Child,
        in modelContext: ModelContext
    ) {
        for (index, item) in items.enumerated() {
            // Offset dates by index to avoid key collisions
            let offsetDate = item.createdAt.addingTimeInterval(TimeInterval(index))
            createArtwork(
                title: item.title,
                imageData: item.imageData,
                createdAt: offsetDate,
                child: child,
                in: modelContext
            )
        }
    }

    /// Updates an existing artwork and syncs to Firestore.
    func updateArtwork(
        _ artwork: Artwork,
        title: String? = nil,
        caption: String? = nil,
        imageData: Data? = nil,
        voiceNoteData: Data? = nil,
        isFavorited: Bool? = nil,
        tags: [Tag]? = nil,
        in modelContext: ModelContext
    ) {
        // Local update
        if let title { artwork.title = title }
        if let caption { artwork.caption = caption }
        if let imageData { artwork.imageData = imageData }
        if let voiceNoteData { artwork.voiceNoteData = voiceNoteData }
        if let isFavorited { artwork.isFavorited = isFavorited }
        if let tags { artwork.tags = tags }

        // Firestore sync
        if isSyncActive, let userId = auth.userId, let firestoreId = artwork.firestoreId {
            Task {
                await updateArtworkInFirestore(
                    firestoreId: firestoreId,
                    userId: userId,
                    artwork: artwork,
                    newImageData: imageData,
                    newVoiceNoteData: voiceNoteData
                )
            }
        }
    }

    /// Deletes an artwork locally and from Firestore.
    func deleteArtwork(_ artwork: Artwork, in modelContext: ModelContext) {
        let firestoreId = artwork.firestoreId
        let userId = auth.userId

        modelContext.delete(artwork)

        if isSyncActive, let userId, let firestoreId {
            Task {
                await deleteArtworkFromFirestore(firestoreId: firestoreId, userId: userId)
            }
        }
    }

    // MARK: - Initial Upload (Premium Upgrade)

    /// One-time upload of all local data to Firestore when user first enables sync.
    func uploadAllLocalData(from modelContext: ModelContext) async {
        guard let userId = auth.userId else { return }
        logger.info("Starting full local → Firestore upload for \(userId, privacy: .public)")

        let descriptor = FetchDescriptor<Child>(sortBy: [SortDescriptor(\.createdAt)])
        guard let children = try? modelContext.fetch(descriptor) else { return }

        for child in children where child.firestoreId == nil {
            await syncChildToFirestore(child, userId: userId, avatarImageData: child.avatarImageData)

            // Upload each artwork for this child
            for artwork in child.artworks ?? [] where artwork.firestoreId == nil {
                if let childFirestoreId = child.firestoreId {
                    await syncArtworkToFirestore(
                        artwork,
                        userId: userId,
                        childFirestoreId: childFirestoreId,
                        imageData: artwork.imageData,
                        voiceNoteData: artwork.voiceNoteData
                    )
                }
            }
        }

        logger.info("Full upload complete")
    }

    // MARK: - Sharing

    /// Creates a share for a child profile and returns the share ID for link generation.
    func shareChild(_ child: Child) async throws -> String {
        guard let userId = auth.userId else {
            throw FirestoreError.notAuthenticated
        }

        // Ensure child is synced to Firestore first
        if child.firestoreId == nil {
            await syncChildToFirestore(child, userId: userId, avatarImageData: child.avatarImageData)
            for artwork in child.artworks ?? [] where artwork.firestoreId == nil {
                if let childFirestoreId = child.firestoreId {
                    await syncArtworkToFirestore(
                        artwork,
                        userId: userId,
                        childFirestoreId: childFirestoreId,
                        imageData: artwork.imageData,
                        voiceNoteData: artwork.voiceNoteData
                    )
                }
            }
        }

        guard let childFirestoreId = child.firestoreId else {
            throw FirestoreError.syncFailed
        }

        // Extract the child document ID from the path
        let childDocId = childFirestoreId.components(separatedBy: "/").last ?? childFirestoreId

        let shareData: [String: Any] = [
            "ownerUserId": userId,
            "childId": childDocId,
            "childPath": "users/\(userId)/children/\(childDocId)",
            "status": "active",
            "createdAt": FieldValue.serverTimestamp()
        ]

        let shareRef = try await db.collection("shares").addDocument(data: shareData)
        logger.info("Share created: \(shareRef.documentID, privacy: .public)")
        return shareRef.documentID
    }

    /// Accepts a share invitation by adding the current user as a participant.
    func acceptShare(shareId: String) async throws {
        guard let userId = auth.userId else {
            throw FirestoreError.notAuthenticated
        }

        let participantData: [String: Any] = [
            "role": "editor",
            "acceptedAt": FieldValue.serverTimestamp(),
            "invitedBy": ""  // Could track who sent the invite
        ]

        try await db.collection("shares")
            .document(shareId)
            .collection("participants")
            .document(userId)
            .setData(participantData)

        logger.info("Share accepted: \(shareId, privacy: .public)")
    }

    /// Stops sharing a child profile (owner only).
    func stopSharing(shareId: String) async throws {
        try await db.collection("shares").document(shareId).updateData([
            "status": "revoked"
        ])
        logger.info("Share revoked: \(shareId, privacy: .public)")
    }

    /// Leaves a shared profile (participant only).
    func leaveShare(shareId: String) async throws {
        guard let userId = auth.userId else {
            throw FirestoreError.notAuthenticated
        }

        try await db.collection("shares")
            .document(shareId)
            .collection("participants")
            .document(userId)
            .delete()

        logger.info("Left share: \(shareId, privacy: .public)")
    }

    /// Fetches participants for a share.
    func fetchParticipants(shareId: String) async throws -> [(userId: String, role: String, acceptedAt: Date?)] {
        let snapshot = try await db.collection("shares")
            .document(shareId)
            .collection("participants")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let role = data["role"] as? String ?? "viewer"
            let acceptedAt = (data["acceptedAt"] as? Timestamp)?.dateValue()
            return (userId: doc.documentID, role: role, acceptedAt: acceptedAt)
        }
    }

    /// Finds the active share for a child, if any.
    func findShare(for child: Child) async -> (shareId: String, status: String)? {
        guard let userId = auth.userId,
              let childFirestoreId = child.firestoreId else { return nil }

        let childDocId = childFirestoreId.components(separatedBy: "/").last ?? childFirestoreId

        do {
            let snapshot = try await db.collection("shares")
                .whereField("ownerUserId", isEqualTo: userId)
                .whereField("childId", isEqualTo: childDocId)
                .whereField("status", isEqualTo: "active")
                .getDocuments()

            guard let doc = snapshot.documents.first else { return nil }
            let status = doc.data()["status"] as? String ?? "unknown"
            return (shareId: doc.documentID, status: status)
        } catch {
            logger.error("findShare failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // MARK: - Private Firestore Write Helpers

    private func syncChildToFirestore(_ child: Child, userId: String, avatarImageData: Data?) async {
        let childRef = db.collection("users").document(userId).collection("children").document()
        let childDocId = childRef.documentID

        // Upload avatar if present
        var avatarURL: String?
        if let avatarData = avatarImageData {
            avatarURL = await storage.uploadWithRetry(
                data: avatarData,
                path: StorageService.avatarPath(userId: userId, childId: childDocId),
                contentType: "image/jpeg"
            )
        }

        let data: [String: Any] = [
            "name": child.name,
            "avatarColor": child.avatarColor,
            "avatarImageURL": avatarURL as Any,
            "createdAt": Timestamp(date: child.createdAt),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await childRef.setData(data)
            let firestoreId = "users/\(userId)/children/\(childDocId)"
            child.firestoreId = firestoreId
            localWriteIds.insert(childDocId)
            logger.info("Child synced: \(firestoreId, privacy: .public)")
        } catch {
            logger.error("Child sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func updateChildInFirestore(
        firestoreId: String,
        userId: String,
        child: Child,
        avatarImageData: Data?
    ) async {
        let childDocId = firestoreId.components(separatedBy: "/").last ?? firestoreId
        let childRef = db.collection("users").document(userId).collection("children").document(childDocId)

        var updates: [String: Any] = [
            "name": child.name,
            "avatarColor": child.avatarColor,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let avatarData = avatarImageData {
            if let url = await storage.uploadWithRetry(
                data: avatarData,
                path: StorageService.avatarPath(userId: userId, childId: childDocId)
            ) {
                updates["avatarImageURL"] = url
            }
        }

        do {
            try await childRef.updateData(updates)
            localWriteIds.insert(childDocId)
        } catch {
            logger.error("Child update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteChildFromFirestore(firestoreId: String, userId: String) async {
        let childDocId = firestoreId.components(separatedBy: "/").last ?? firestoreId
        let childRef = db.collection("users").document(userId).collection("children").document(childDocId)

        do {
            // Delete all artworks in subcollection first
            let artworks = try await childRef.collection("artworks").getDocuments()
            for doc in artworks.documents {
                try await doc.reference.delete()
            }
            try await childRef.delete()
            logger.info("Child deleted from Firestore: \(childDocId, privacy: .public)")
        } catch {
            logger.error("Child delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func syncArtworkToFirestore(
        _ artwork: Artwork,
        userId: String,
        childFirestoreId: String,
        imageData: Data?,
        voiceNoteData: Data?
    ) async {
        let childDocId = childFirestoreId.components(separatedBy: "/").last ?? childFirestoreId
        let artworkRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)
            .collection("artworks").document()
        let artworkDocId = artworkRef.documentID

        // Upload binary data
        var imageURL: String?
        var voiceNoteURL: String?

        if let imgData = imageData {
            imageURL = await storage.uploadWithRetry(
                data: imgData,
                path: StorageService.artworkImagePath(userId: userId, childId: childDocId, artworkId: artworkDocId)
            )
        }

        if let audioData = voiceNoteData {
            voiceNoteURL = await storage.uploadWithRetry(
                data: audioData,
                path: StorageService.voiceNotePath(userId: userId, childId: childDocId, artworkId: artworkDocId),
                contentType: "audio/m4a"
            )
        }

        let tagNames = artwork.tags?.map(\.name) ?? []
        let data: [String: Any] = [
            "title": artwork.title,
            "caption": artwork.caption,
            "imageURL": imageURL as Any,
            "voiceNoteURL": voiceNoteURL as Any,
            "isFavorited": artwork.isFavorited,
            "createdAt": Timestamp(date: artwork.createdAt),
            "updatedAt": FieldValue.serverTimestamp(),
            "tags": tagNames
        ]

        do {
            try await artworkRef.setData(data)
            let firestoreId = "users/\(userId)/children/\(childDocId)/artworks/\(artworkDocId)"
            artwork.firestoreId = firestoreId
            artwork.imageURL = imageURL
            artwork.voiceNoteURL = voiceNoteURL
            localWriteIds.insert(artworkDocId)
            logger.info("Artwork synced: \(firestoreId, privacy: .public)")
        } catch {
            logger.error("Artwork sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func updateArtworkInFirestore(
        firestoreId: String,
        userId: String,
        artwork: Artwork,
        newImageData: Data?,
        newVoiceNoteData: Data?
    ) async {
        let parts = firestoreId.components(separatedBy: "/")
        guard parts.count >= 6 else { return }
        let childDocId = parts[3]
        let artworkDocId = parts[5]

        let artworkRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)
            .collection("artworks").document(artworkDocId)

        let tagNames = artwork.tags?.map(\.name) ?? []
        var updates: [String: Any] = [
            "title": artwork.title,
            "caption": artwork.caption,
            "isFavorited": artwork.isFavorited,
            "updatedAt": FieldValue.serverTimestamp(),
            "tags": tagNames
        ]

        if let imgData = newImageData {
            if let url = await storage.uploadWithRetry(
                data: imgData,
                path: StorageService.artworkImagePath(userId: userId, childId: childDocId, artworkId: artworkDocId)
            ) {
                updates["imageURL"] = url
                artwork.imageURL = url
            }
        }

        if let audioData = newVoiceNoteData {
            if let url = await storage.uploadWithRetry(
                data: audioData,
                path: StorageService.voiceNotePath(userId: userId, childId: childDocId, artworkId: artworkDocId),
                contentType: "audio/m4a"
            ) {
                updates["voiceNoteURL"] = url
                artwork.voiceNoteURL = url
            }
        }

        do {
            try await artworkRef.updateData(updates)
            localWriteIds.insert(artworkDocId)
        } catch {
            logger.error("Artwork update failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteArtworkFromFirestore(firestoreId: String, userId: String) async {
        let parts = firestoreId.components(separatedBy: "/")
        guard parts.count >= 6 else { return }
        let childDocId = parts[3]
        let artworkDocId = parts[5]

        let artworkRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)
            .collection("artworks").document(artworkDocId)

        do {
            try await artworkRef.delete()
            // Also delete storage files
            await storage.delete(path: StorageService.artworkImagePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
            await storage.delete(path: StorageService.voiceNotePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
            logger.info("Artwork deleted: \(artworkDocId, privacy: .public)")
        } catch {
            logger.error("Artwork delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Errors

    enum FirestoreError: LocalizedError {
        case notAuthenticated
        case syncFailed

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: "Not signed in to Firebase."
            case .syncFailed: "Failed to sync data to Firestore."
            }
        }
    }
}
