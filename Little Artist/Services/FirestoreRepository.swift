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
import FirebaseStorage
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

    /// `true` while `uploadAllLocalData` is running. Used to prevent
    /// `shareChild` from racing with the bulk upload.
    private(set) var isUploadingAll = false

    /// Whether Firestore sync is active for the current authenticated user.
    var isSyncActive: Bool {
        auth.userId != nil
    }

    /// Whether premium-only artwork authoring features are available.
    private var canUsePremiumArtworkFeatures: Bool {
        PremiumManager.isPremium
    }

    private init() {}

    // MARK: - Preferences

    /// Pushes local app preferences to Firestore so they stay in sync across devices.
    func syncUserPreferencesToFirestore() async {
        guard let userId = auth.userId else { return }

        let defaults = UserDefaults.standard
        let data: [String: Any] = [
            "aiCaptionsEnabled": defaults.bool(forKey: "aiCaptionsEnabled"),
            "defaultCameraBack": defaults.bool(forKey: "defaultCameraBack"),
            "notificationsEnabled": defaults.bool(forKey: "notificationsEnabled"),
            "hasCompletedOnboarding": defaults.bool(forKey: "hasCompletedOnboarding"),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection("users")
                .document(userId)
                .collection("meta")
                .document("preferences")
                .setData(data, merge: true)
            logger.info("Preferences synced to Firestore")
        } catch {
            logger.error("Preferences sync failed: \(error.localizedDescription, privacy: .public)")
        }
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

        // Pre-generate Firestore ID and register in localWriteIds BEFORE insert
        // to prevent the snapshot listener from creating a duplicate.
        var preGeneratedRef: DocumentReference?
        if isSyncActive, let userId = auth.userId {
            let childRef = db.collection("users").document(userId).collection("children").document()
            let childDocId = childRef.documentID
            let firestoreId = "users/\(userId)/children/\(childDocId)"
            child.firestoreId = firestoreId
            localWriteIds.insert(childDocId)
            preGeneratedRef = childRef
        }

        modelContext.insert(child)
        try? modelContext.save()

        // Async Firestore sync using the pre-generated document reference
        if let childRef = preGeneratedRef, let userId = auth.userId {
            Task {
                await syncChildToFirestore(child, userId: userId, avatarImageData: avatarImageData, docRef: childRef)
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

    /// Deletes a child and all its artworks locally and from Firestore + Storage.
    func deleteChild(_ child: Child, in modelContext: ModelContext) {
        let firestoreId = child.firestoreId
        let userId = auth.userId

        // Track the deletion so the sync listener doesn't re-create this child
        if let firestoreId {
            let childDocId = firestoreId.components(separatedBy: "/").last ?? firestoreId
            localWriteIds.insert(childDocId)
        }

        // Local delete (cascades to artworks via SwiftData relationship)
        modelContext.delete(child)

        // Firestore + Storage delete
        if isSyncActive, let userId, let firestoreId {
            Task {
                await deleteChildFromFirestore(firestoreId: firestoreId, userId: userId)
            }
        } else if firestoreId == nil {
            logger.warning("deleteChild: firestoreId is nil — skipping Firestore delete")
        }
    }

    // MARK: - Artworks

    /// Creates a new artwork locally and optionally syncs to Firestore.
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
        let sanitizedVoiceNoteData = canUsePremiumArtworkFeatures ? voiceNoteData : nil

        let artwork = Artwork(
            title: title,
            caption: caption,
            imageData: imageData,
            thumbnailData: thumbnailData,
            voiceNoteData: sanitizedVoiceNoteData,
            isFavorited: isFavorited,
            createdAt: createdAt,
            child: child,
            tags: tags
        )

        // Pre-generate Firestore ID and register in localWriteIds BEFORE insert
        // to prevent the snapshot listener from creating a duplicate.
        var preGeneratedRef: DocumentReference?
        // New artworks only sync to cloud for active premium users.
        if isSyncActive, canUsePremiumArtworkFeatures, let userId = auth.userId, let childFirestoreId = child.firestoreId {
            let childDocId = childFirestoreId.components(separatedBy: "/").last ?? childFirestoreId
            let artworkRef = db.collection("users").document(userId)
                .collection("children").document(childDocId)
                .collection("artworks").document()
            let artworkDocId = artworkRef.documentID
            let firestoreId = "users/\(userId)/children/\(childDocId)/artworks/\(artworkDocId)"
            artwork.firestoreId = firestoreId
            localWriteIds.insert(artworkDocId)
            preGeneratedRef = artworkRef
        }

        modelContext.insert(artwork)
        try? modelContext.save()

        // Async Firestore sync using the pre-generated document reference
        if let artworkRef = preGeneratedRef, let userId = auth.userId, let childFirestoreId = child.firestoreId {
            Task {
                await syncArtworkToFirestore(
                    artwork,
                    userId: userId,
                    childFirestoreId: childFirestoreId,
                    imageData: imageData,
                    voiceNoteData: sanitizedVoiceNoteData,
                    docRef: artworkRef
                )
            }
        }

        return artwork
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
        let effectiveVoiceNoteData = canUsePremiumArtworkFeatures ? voiceNoteData : nil

        // Local update
        if let title { artwork.title = title }
        if let caption { artwork.caption = caption }
        if let imageData { artwork.imageData = imageData }
        if let effectiveVoiceNoteData { artwork.voiceNoteData = effectiveVoiceNoteData }
        if let isFavorited { artwork.isFavorited = isFavorited }
        if let tags { artwork.tags = tags }
        try? modelContext.save()

        // Cloud sync edits only for artworks that are already synced.
        if isSyncActive, let userId = auth.userId, let firestoreId = artwork.firestoreId {
            Task {
                await updateArtworkInFirestore(
                    firestoreId: firestoreId,
                    userId: userId,
                    artwork: artwork,
                    newImageData: imageData,
                    newVoiceNoteData: effectiveVoiceNoteData
                )
            }
        }
    }

    /// Deletes an artwork locally and from Firestore + Storage.
    func deleteArtwork(_ artwork: Artwork, in modelContext: ModelContext) {
        let firestoreId = artwork.firestoreId
        let imageURL = artwork.imageURL
        let voiceNoteURL = artwork.voiceNoteURL
        let userId = auth.userId

        // Track the deletion so the sync listener doesn't re-create this artwork
        if let firestoreId {
            let parts = firestoreId.components(separatedBy: "/")
            if parts.count >= 6 {
                localWriteIds.insert(parts[5])
            }
        }

        modelContext.delete(artwork)

        if isSyncActive, let userId {
            if let firestoreId {
                Task {
                    await deleteArtworkFromFirestore(firestoreId: firestoreId, userId: userId)
                }
            } else {
                // Artwork was never assigned a firestoreId but may have storage URLs
                // (e.g. synced via uploadAllLocalData but firestoreId wasn't persisted).
                // Clean up any Firebase Storage files we know about.
                logger.warning("deleteArtwork: firestoreId is nil — skipping Firestore doc delete")
                if imageURL != nil || voiceNoteURL != nil {
                    Task {
                        await deleteOrphanedStorage(imageURL: imageURL, voiceNoteURL: voiceNoteURL)
                    }
                }
            }
        }
    }

    // MARK: - Initial Upload (Premium Upgrade)

    /// One-time upload of all local data to Firestore when user first enables sync.
    func uploadAllLocalData(from modelContext: ModelContext) async {
        guard let userId = auth.userId else { return }
        isUploadingAll = true
        logger.info("Starting full local → Firestore upload for \(userId, privacy: .public)")

        let descriptor = FetchDescriptor<Child>(sortBy: [SortDescriptor(\.createdAt)])
        guard let children = try? modelContext.fetch(descriptor) else {
            isUploadingAll = false
            return
        }

        for child in children where child.firestoreId == nil {
            // Check if this child already exists in Firestore (by name)
            // to avoid creating duplicate documents.
            if let existingDocId = await findExistingFirestoreChild(name: child.name, userId: userId) {
                let firestoreId = "users/\(userId)/children/\(existingDocId)"
                child.firestoreId = firestoreId
                localWriteIds.insert(existingDocId)
                try? modelContext.save()
                logger.info("Adopted existing Firestore child: \(firestoreId, privacy: .public)")
                continue
            }

            await syncChildToFirestore(child, userId: userId, avatarImageData: child.avatarImageData)

            // Upload each artwork for this child
            // New artworks are premium-only for cloud upload.
            for artwork in child.artworks ?? [] where artwork.firestoreId == nil && canUsePremiumArtworkFeatures {
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

        isUploadingAll = false
        logger.info("Full upload complete")
    }

    /// Deletes all Firebase data for a user account (children, artworks, storage, shares, preferences).
    func deleteAllUserData(userId: String) async {
        // Delete all children + nested artworks/storage.
        do {
            let childrenSnapshot = try await db.collection("users")
                .document(userId)
                .collection("children")
                .getDocuments()

            for doc in childrenSnapshot.documents {
                let firestoreId = "users/\(userId)/children/\(doc.documentID)"
                await deleteChildFromFirestore(firestoreId: firestoreId, userId: userId)
            }
        } catch {
            logger.error("Failed to enumerate children for account deletion: \(error.localizedDescription, privacy: .public)")
        }

        // Delete user preferences metadata.
        do {
            try await db.collection("users")
                .document(userId)
                .collection("meta")
                .document("preferences")
                .delete()
        } catch {
            logger.error("Failed to delete preferences metadata: \(error.localizedDescription, privacy: .public)")
        }

        // Delete shares owned by this user.
        do {
            let sharesSnapshot = try await db.collection("shares")
                .whereField("ownerUserId", isEqualTo: userId)
                .getDocuments()
            for shareDoc in sharesSnapshot.documents {
                try? await shareDoc.reference.delete()
            }
        } catch {
            logger.error("Failed to delete owned shares: \(error.localizedDescription, privacy: .public)")
        }

        // Remove this user from participant lists in shares they joined.
        do {
            let sharesSnapshot = try await db.collection("shares").getDocuments()
            for shareDoc in sharesSnapshot.documents {
                try? await shareDoc.reference
                    .collection("participants")
                    .document(userId)
                    .delete()
            }
        } catch {
            logger.error("Failed to remove participant memberships: \(error.localizedDescription, privacy: .public)")
        }

        // Finally remove root user document.
        do {
            try await db.collection("users").document(userId).delete()
        } catch {
            logger.error("Failed to delete root user document: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Sharing

    /// Creates a share for a child profile and returns the share ID for link generation.
    func shareChild(_ child: Child) async throws -> String {
        guard let userId = auth.userId else {
            throw FirestoreError.notAuthenticated
        }

        // Wait for any in-progress bulk upload to finish so firestoreId is populated
        while isUploadingAll {
            try await Task.sleep(for: .milliseconds(200))
        }

        // Ensure child is synced to Firestore first
        if child.firestoreId == nil {
            await syncChildToFirestore(child, userId: userId, avatarImageData: child.avatarImageData)
            for artwork in child.artworks ?? [] where artwork.firestoreId == nil && canUsePremiumArtworkFeatures {
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

    private func syncChildToFirestore(
        _ child: Child,
        userId: String,
        avatarImageData: Data?,
        docRef: DocumentReference? = nil
    ) async {
        // Use pre-generated reference if available, otherwise create a new one
        let childRef = docRef ?? db.collection("users").document(userId).collection("children").document()
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
            // firestoreId and localWriteIds already set upfront in createChild()
            // but ensure they're set for any legacy call path without a pre-generated ref
            if child.firestoreId == nil {
                let firestoreId = "users/\(userId)/children/\(childDocId)"
                child.firestoreId = firestoreId
            }
            localWriteIds.insert(childDocId)

            // Explicitly save so firestoreId persists even if the app is killed
            // before SwiftData auto-saves. Prevents nil firestoreId on cold restart.
            if let container = modelContainer {
                let saveContext = ModelContext(container)
                let fid = child.firestoreId
                var desc = FetchDescriptor<Child>(
                    predicate: #Predicate<Child> { $0.firestoreId == fid }
                )
                desc.fetchLimit = 1
                if let _ = try? saveContext.fetch(desc).first {
                    try? saveContext.save()
                }
            }

            logger.info("Child synced: \(childRef.path, privacy: .public)")
        } catch {
            logger.error("Child sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Checks if a child with the given name already exists in Firestore.
    /// Returns the document ID if found, nil otherwise.
    private func findExistingFirestoreChild(name: String, userId: String) async -> String? {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("children")
                .whereField("name", isEqualTo: name)
                .limit(to: 1)
                .getDocuments()
            return snapshot.documents.first?.documentID
        } catch {
            logger.error("findExistingFirestoreChild query failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Deletes an orphaned Firestore child document and its artworks subcollection.
    /// Used during dedup to clean up redundant cloud data.
    func deleteOrphanedFirestoreChild(firestoreId: String, userId: String) async {
        let childDocId = firestoreId.components(separatedBy: "/").last ?? firestoreId
        let childRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)

        do {
            // Delete any artworks in subcollection
            let artworks = try await childRef.collection("artworks").getDocuments()
            for doc in artworks.documents {
                let artworkDocId = doc.documentID
                try await doc.reference.delete()
                localWriteIds.insert(artworkDocId)
            }
            // Delete the child document itself
            try await childRef.delete()
            localWriteIds.insert(childDocId)
            logger.info("Deleted orphaned Firestore child: \(firestoreId, privacy: .public)")
        } catch {
            logger.error("Failed to delete orphaned child: \(error.localizedDescription, privacy: .public)")
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
            // Delete all artworks in subcollection + their Storage files
            let artworks = try await childRef.collection("artworks").getDocuments()
            for doc in artworks.documents {
                let artworkDocId = doc.documentID
                try await doc.reference.delete()
                localWriteIds.insert(artworkDocId)
                // Clean up Storage files for this artwork
                await storage.delete(path: StorageService.artworkImagePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
                await storage.delete(path: StorageService.voiceNotePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
            }

            // Delete child's avatar from Storage
            await storage.delete(path: StorageService.avatarPath(userId: userId, childId: childDocId))

            try await childRef.delete()
            localWriteIds.insert(childDocId)
            logger.info("Child + \(artworks.documents.count) artworks deleted from Firestore + Storage: \(childDocId, privacy: .public)")
        } catch {
            logger.error("Child delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func syncArtworkToFirestore(
        _ artwork: Artwork,
        userId: String,
        childFirestoreId: String,
        imageData: Data?,
        voiceNoteData: Data?,
        docRef: DocumentReference? = nil
    ) async {
        let childDocId = childFirestoreId.components(separatedBy: "/").last ?? childFirestoreId
        // Use pre-generated reference if available, otherwise create a new one
        let artworkRef = docRef ?? db.collection("users").document(userId)
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
            // firestoreId and localWriteIds already set upfront in createArtwork()
            // but ensure they're set for any legacy call path without a pre-generated ref
            if artwork.firestoreId == nil {
                let firestoreId = "users/\(userId)/children/\(childDocId)/artworks/\(artworkDocId)"
                artwork.firestoreId = firestoreId
            }
            artwork.imageURL = imageURL
            artwork.voiceNoteURL = voiceNoteURL
            localWriteIds.insert(artworkDocId)

            // Explicitly save so firestoreId persists even if the app is killed
            // before SwiftData auto-saves.
            if let container = modelContainer {
                let saveContext = ModelContext(container)
                let fid = artwork.firestoreId
                var desc = FetchDescriptor<Artwork>(
                    predicate: #Predicate<Artwork> { $0.firestoreId == fid }
                )
                desc.fetchLimit = 1
                if let _ = try? saveContext.fetch(desc).first {
                    try? saveContext.save()
                }
            }

            logger.info("Artwork synced: \(artworkRef.path, privacy: .public)")
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
        guard parts.count >= 6 else {
            logger.error("deleteArtworkFromFirestore: bad firestoreId format: \(firestoreId, privacy: .public)")
            return
        }
        let childDocId = parts[3]
        let artworkDocId = parts[5]

        let artworkRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)
            .collection("artworks").document(artworkDocId)

        do {
            try await artworkRef.delete()
            localWriteIds.insert(artworkDocId)
            // Also delete storage files
            await storage.delete(path: StorageService.artworkImagePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
            await storage.delete(path: StorageService.voiceNotePath(userId: userId, childId: childDocId, artworkId: artworkDocId))
            logger.info("Artwork deleted from Firestore + Storage: \(artworkDocId, privacy: .public)")
        } catch {
            logger.error("Artwork delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Deletes Firebase Storage files using their download URLs directly.
    /// Fallback for artworks missing a `firestoreId` but that have storage URLs.
    private func deleteOrphanedStorage(imageURL: String?, voiceNoteURL: String?) async {
        if let url = imageURL {
            let ref = Storage.storage().reference(forURL: url)
            try? await ref.delete()
            logger.info("Deleted orphaned image from Storage")
        }
        if let url = voiceNoteURL {
            let ref = Storage.storage().reference(forURL: url)
            try? await ref.delete()
            logger.info("Deleted orphaned voice note from Storage")
        }
    }

    // MARK: - Errors

    enum FirestoreError: LocalizedError {
        case notAuthenticated
        case syncFailed

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: "Not signed in to cloud account."
            case .syncFailed: "Failed to sync data to cloud storage."
            }
        }
    }
}
