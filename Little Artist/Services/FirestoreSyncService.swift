//
//  FirestoreSyncService.swift
//  Little Artist
//
//  Manages Firestore snapshot listeners that pull remote changes
//  into SwiftData.
//
//  Architecture:
//  - Listens to users/{uid}/children collection for child changes
//  - Listens to each children/{cid}/artworks subcollection
//  - Reconciles remote changes into SwiftData via firestoreId matching
//  - Skips writes originated by this device (tracked via localWriteIds)
//

import FirebaseFirestore
import Foundation
import os
import SwiftData

/// Listens to Firestore snapshot changes and reconciles them into SwiftData.
///
/// This is the read path of the Firebase sync — the counterpart to
/// ``FirestoreRepository`` which handles writes.
@MainActor
@Observable
final class FirestoreSyncService {

    // MARK: - Singleton

    static let shared = FirestoreSyncService()

    // MARK: - Dependencies

    var modelContainer: ModelContainer?

    // MARK: - State

    /// Whether the sync service is currently listening.
    private(set) var isListening = false

    /// Last time a remote change was processed.
    private(set) var lastSyncDate: Date?

    /// Diagnostic log (last 50 entries).
    private(set) var diagnosticLog: [String] = []

    // MARK: - Private

    private let db = Firestore.firestore()
    private let auth = FirebaseAuthService.shared
    private let repository = FirestoreRepository.shared
    private let storage = StorageService.shared
    private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Sync")

    /// Active snapshot listener registrations.
    private var childrenListener: ListenerRegistration?
    private var artworkListeners: [String: ListenerRegistration] = [:]
    private var sharedChildrenListeners: [String: ListenerRegistration] = [:]

    private init() {}

    // MARK: - Lifecycle

    /// Starts listening for remote changes. Call after auth is ready and sync is enabled.
    func start() {
        guard let userId = auth.userId else {
            diag("Cannot start sync — no authenticated user")
            return
        }
        guard !isListening else { return }

        isListening = true
        diag("Sync started for user \(userId)")

        listenToChildren(userId: userId)
        listenToShares(userId: userId)
    }

    /// Stops all listeners. Call when user disables sync or signs out.
    func stop() {
        childrenListener?.remove()
        childrenListener = nil

        for (_, listener) in artworkListeners {
            listener.remove()
        }
        artworkListeners.removeAll()

        for (_, listener) in sharedChildrenListeners {
            listener.remove()
        }
        sharedChildrenListeners.removeAll()

        isListening = false
        diag("Sync stopped")
    }

    // MARK: - Children Listener

    private func listenToChildren(userId: String) {
        let childrenRef = db.collection("users").document(userId).collection("children")

        childrenListener = childrenRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.diag("Children listener error: \(error.localizedDescription)")
                    return
                }

                guard let snapshot else { return }

                for change in snapshot.documentChanges {
                    let docId = change.document.documentID
                    let firestoreId = "users/\(userId)/children/\(docId)"

                    // Skip writes originated by this device
                    if self.repository.localWriteIds.contains(docId) {
                        continue
                    }

                    switch change.type {
                    case .added, .modified:
                        await self.upsertChild(
                            from: change.document,
                            firestoreId: firestoreId,
                            isShared: false,
                            ownerUserId: nil
                        )
                    case .removed:
                        self.removeChild(firestoreId: firestoreId)
                    }
                }

                // Attach artwork listeners for each child
                for doc in snapshot.documents {
                    let childDocId = doc.documentID
                    let firestoreId = "users/\(userId)/children/\(childDocId)"
                    if self.artworkListeners[firestoreId] == nil {
                        self.listenToArtworks(userId: userId, childDocId: childDocId, firestoreId: firestoreId)
                    }
                }

                self.lastSyncDate = Date()
            }
        }
    }

    // MARK: - Artworks Listener

    private func listenToArtworks(userId: String, childDocId: String, firestoreId childFirestoreId: String) {
        let artworksRef = db.collection("users").document(userId)
            .collection("children").document(childDocId)
            .collection("artworks")

        let listener = artworksRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.diag("Artworks listener error: \(error.localizedDescription)")
                    return
                }

                guard let snapshot else { return }

                for change in snapshot.documentChanges {
                    let docId = change.document.documentID

                    // Skip writes originated by this device
                    if self.repository.localWriteIds.contains(docId) {
                        continue
                    }

                    let artworkFirestoreId = "\(childFirestoreId)/artworks/\(docId)"

                    switch change.type {
                    case .added, .modified:
                        await self.upsertArtwork(
                            from: change.document,
                            firestoreId: artworkFirestoreId,
                            childFirestoreId: childFirestoreId
                        )
                    case .removed:
                        self.removeArtwork(firestoreId: artworkFirestoreId)
                    }
                }

                self.lastSyncDate = Date()
            }
        }

        artworkListeners[childFirestoreId] = listener
    }

    // MARK: - Shares Listener

    private func listenToShares(userId: String) {
        // Listen for shares where current user is a participant
        // We query all shares and then check the participants subcollection
        let sharesRef = db.collection("shares")
            .whereField("status", isEqualTo: "active")

        sharesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.diag("Shares listener error: \(error.localizedDescription)")
                    return
                }

                guard let snapshot else { return }

                for doc in snapshot.documents {
                    let shareId = doc.documentID
                    let data = doc.data()
                    let ownerUserId = data["ownerUserId"] as? String ?? ""
                    let childId = data["childId"] as? String ?? ""

                    // Skip shares we own
                    if ownerUserId == userId { continue }

                    // Check if we're a participant
                    await self.checkAndListenToSharedChild(
                        shareId: shareId,
                        ownerUserId: ownerUserId,
                        childId: childId,
                        currentUserId: userId
                    )
                }
            }
        }
    }

    private func checkAndListenToSharedChild(
        shareId: String,
        ownerUserId: String,
        childId: String,
        currentUserId: String
    ) async {
        do {
            let participantDoc = try await db.collection("shares")
                .document(shareId)
                .collection("participants")
                .document(currentUserId)
                .getDocument()

            guard participantDoc.exists else { return }

            let childFirestoreId = "users/\(ownerUserId)/children/\(childId)"

            // Skip if already listening
            if sharedChildrenListeners[childFirestoreId] != nil { return }

            // Listen to the shared child document
            let childRef = db.collection("users").document(ownerUserId)
                .collection("children").document(childId)

            let childListener = childRef.addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot, error == nil else { return }
                Task { @MainActor in
                    await self.upsertChild(
                        from: snapshot,
                        firestoreId: childFirestoreId,
                        isShared: true,
                        ownerUserId: ownerUserId
                    )
                }
            }
            sharedChildrenListeners[childFirestoreId] = childListener

            // Listen to shared child's artworks
            listenToArtworks(userId: ownerUserId, childDocId: childId, firestoreId: childFirestoreId)

            diag("Listening to shared child: \(childFirestoreId)")
        } catch {
            diag("Failed to check share participation: \(error.localizedDescription)")
        }
    }

    // MARK: - SwiftData Reconciliation

    private func upsertChild(
        from document: DocumentSnapshot,
        firestoreId: String,
        isShared: Bool,
        ownerUserId: String?
    ) async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        let data = document.data() ?? [:]
        let name = data["name"] as? String ?? ""
        let avatarColor = data["avatarColor"] as? String ?? "F2784B"
        let avatarImageURL = data["avatarImageURL"] as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        // Find existing child by firestoreId
        var descriptor = FetchDescriptor<Child>(
            predicate: #Predicate<Child> { $0.firestoreId == firestoreId }
        )
        descriptor.fetchLimit = 1

        let existing = try? context.fetch(descriptor).first

        if let child = existing {
            // Update existing
            child.name = name
            child.avatarColor = avatarColor
            child.isShared = isShared
            child.ownerUserId = ownerUserId
        } else {
            // Insert new
            let child = Child(
                name: name,
                avatarColor: avatarColor,
                createdAt: createdAt,
                firestoreId: firestoreId,
                isShared: isShared,
                ownerUserId: ownerUserId
            )
            context.insert(child)
        }

        // Download avatar if URL is present and we don't have local data
        if let avatarURL = avatarImageURL {
            let targetChild = existing ?? (try? context.fetch(descriptor).first)
            if targetChild?.avatarImageData == nil {
                if let avatarData = await storage.download(url: avatarURL) {
                    targetChild?.avatarImageData = avatarData
                }
            }
        }

        try? context.save()
        diag("Upserted child: \(name) (\(firestoreId))")
    }

    private func removeChild(firestoreId: String) {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<Child>(
            predicate: #Predicate<Child> { $0.firestoreId == firestoreId }
        )
        descriptor.fetchLimit = 1

        if let child = try? context.fetch(descriptor).first {
            context.delete(child)
            try? context.save()
            diag("Removed child: \(firestoreId)")
        }
    }

    private func upsertArtwork(
        from document: QueryDocumentSnapshot,
        firestoreId: String,
        childFirestoreId: String
    ) async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        let data = document.data()
        let title = data["title"] as? String ?? ""
        let caption = data["caption"] as? String ?? ""
        let isFavorited = data["isFavorited"] as? Bool ?? false
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let imageURL = data["imageURL"] as? String
        let voiceNoteURL = data["voiceNoteURL"] as? String
        let tagNames = data["tags"] as? [String] ?? []

        // Find the parent child
        var childDescriptor = FetchDescriptor<Child>(
            predicate: #Predicate<Child> { $0.firestoreId == childFirestoreId }
        )
        childDescriptor.fetchLimit = 1
        guard let child = try? context.fetch(childDescriptor).first else {
            diag("Cannot upsert artwork — parent child not found: \(childFirestoreId)")
            return
        }

        // Find or create tags
        let tags = tagNames.compactMap { name -> Tag? in
            var tagDescriptor = FetchDescriptor<Tag>(
                predicate: #Predicate<Tag> { $0.name == name }
            )
            tagDescriptor.fetchLimit = 1
            if let existing = try? context.fetch(tagDescriptor).first {
                return existing
            }
            let tag = Tag(name: name)
            context.insert(tag)
            return tag
        }

        // Find existing artwork by firestoreId
        var artworkDescriptor = FetchDescriptor<Artwork>(
            predicate: #Predicate<Artwork> { $0.firestoreId == firestoreId }
        )
        artworkDescriptor.fetchLimit = 1

        let existing = try? context.fetch(artworkDescriptor).first

        if let artwork = existing {
            // Update existing
            artwork.title = title
            artwork.caption = caption
            artwork.isFavorited = isFavorited
            artwork.imageURL = imageURL
            artwork.voiceNoteURL = voiceNoteURL
            artwork.tags = tags
        } else {
            // Insert new
            let artwork = Artwork(
                title: title,
                caption: caption,
                isFavorited: isFavorited,
                createdAt: createdAt,
                child: child,
                tags: tags,
                firestoreId: firestoreId,
                imageURL: imageURL,
                voiceNoteURL: voiceNoteURL
            )
            context.insert(artwork)
        }

        // Download image/voice note if we don't have local data
        let targetArtwork = existing ?? (try? context.fetch(artworkDescriptor).first)
        if let imgURL = imageURL, targetArtwork?.imageData == nil {
            if let imgData = await storage.download(url: imgURL) {
                targetArtwork?.imageData = imgData
                // Generate thumbnail from downloaded image
                if targetArtwork?.thumbnailData == nil {
                    targetArtwork?.thumbnailData = ImageProcessingService.generateThumbnail(from: imgData)
                }
            }
        }
        if let audioURL = voiceNoteURL, targetArtwork?.voiceNoteData == nil {
            if let audioData = await storage.download(url: audioURL) {
                targetArtwork?.voiceNoteData = audioData
            }
        }

        try? context.save()
    }

    private func removeArtwork(firestoreId: String) {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<Artwork>(
            predicate: #Predicate<Artwork> { $0.firestoreId == firestoreId }
        )
        descriptor.fetchLimit = 1

        if let artwork = try? context.fetch(descriptor).first {
            context.delete(artwork)
            try? context.save()
            diag("Removed artwork: \(firestoreId)")
        }
    }

    // MARK: - Diagnostics

    /// Appends a timestamped entry to the diagnostic log.
    func diag(_ message: String) {
        let entry = "[\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))] \(message)"
        diagnosticLog.append(entry)
        if diagnosticLog.count > 50 { diagnosticLog.removeFirst() }
        logger.info("\(message, privacy: .public)")
    }

    /// Returns a snapshot of the sync state for diagnostics display.
    func diagnosticSnapshot() -> [String: String] {
        [
            "Listening": isListening ? "Yes" : "No",
            "User": auth.userId ?? "None",
            "Linked with Apple": auth.isLinkedWithApple ? "Yes" : "No",
            "Children listeners": "\(artworkListeners.count)",
            "Shared listeners": "\(sharedChildrenListeners.count)",
            "Last sync": lastSyncDate.map { DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .medium) } ?? "Never",
            "Active uploads": "\(storage.activeUploads)"
        ]
    }
}
