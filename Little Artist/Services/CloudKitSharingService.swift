//
//  CloudKitSharingService.swift
//  Little Artist
//
//  Core Data + CloudKit sharing service that runs alongside SwiftData.
//  Manages NSPersistentCloudKitContainer for private/shared database sync,
//  share creation, acceptance, and revocation at the Child level.
//

import CloudKit
import CoreData
import os.log
import SwiftData
import SwiftUI

private let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "CloudKit")

/// Manages CloudKit sharing using `NSPersistentCloudKitContainer`.
///
/// SwiftData (as of iOS 18) lacks a shared-database API, so this service
/// provides a parallel Core Data stack that owns CloudKit sync for both
/// the private and shared databases. SwiftData reads from the same private
/// SQLite file with `cloudKitDatabase: .none`.
@MainActor @Observable
final class CloudKitSharingService {

    // MARK: - Singleton

    static let shared = CloudKitSharingService()

    // MARK: - Properties

    private(set) var persistentContainer: NSPersistentCloudKitContainer?
    private var privateStore: NSPersistentStore?
    private var sharedStore: NSPersistentStore?

    /// Child object URLs whose sharing was stopped locally (pending CloudKit sync).
    private var stoppedSharingURLs: Set<String> = []

    /// The CloudKit container identifier used by this app.
    let ckContainerIdentifier = "iCloud.uk.co.flutterly.Little-Artist"

    /// Whether the Core Data + CloudKit stack has been initialised.
    var isInitialised: Bool { persistentContainer != nil }

    // MARK: - Init

    private init() {}

    // MARK: - Stack Setup

    /// Initialises the `NSPersistentCloudKitContainer` with private and shared stores.
    ///
    /// Call this once from the app entry point when premium + iCloud are enabled.
    /// The private store points to the same SQLite file SwiftData uses so both
    /// stacks stay in sync via persistent history tracking.
    func setup() {
        guard persistentContainer == nil else { return }

        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [
            Child.self,
            Artwork.self,
            Tag.self
        ]) else {
            logger.error("Failed to create managed object model from SwiftData types")
            return
        }
        let entityNames = model.entities.compactMap(\.name).joined(separator: ", ")
        logger.info("Created managed object model with \(model.entities.count) entities: \(entityNames, privacy: .public)")

        let container = NSPersistentCloudKitContainer(name: "LittleArtist", managedObjectModel: model)

        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        // Private store — same file as SwiftData's default.store
        let privateURL = appSupport.appendingPathComponent("default.store")
        let privateDesc = NSPersistentStoreDescription(url: privateURL)
        privateDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: ckContainerIdentifier
        )
        privateDesc.cloudKitContainerOptions?.databaseScope = .private
        privateDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        privateDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Shared store — separate file for shared zone data
        let sharedURL = appSupport.appendingPathComponent("shared.store")
        let sharedDesc = NSPersistentStoreDescription(url: sharedURL)
        sharedDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: ckContainerIdentifier
        )
        sharedDesc.cloudKitContainerOptions?.databaseScope = .shared
        sharedDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        sharedDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [privateDesc, sharedDesc]

        var loadErrors: [String] = []

        container.loadPersistentStores { description, error in
            if let error {
                loadErrors.append("\(description.url?.lastPathComponent ?? "?"): \(error)")
                logger.error("Failed to load store \(description.url?.lastPathComponent ?? "?", privacy: .public): \(error.localizedDescription, privacy: .public)")
                return
            }
            logger.info("Loaded store: \(description.url?.lastPathComponent ?? "?", privacy: .public) scope=\(description.cloudKitContainerOptions?.databaseScope.rawValue ?? -1)")
        }

        guard loadErrors.isEmpty else {
            logger.error("Aborting setup — \(loadErrors.count) store(s) failed to load")
            return
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Assign stores by URL
        for store in container.persistentStoreCoordinator.persistentStores {
            if store.url == privateURL {
                privateStore = store
            } else if store.url == sharedURL {
                sharedStore = store
            }
        }

        persistentContainer = container

        // Force CloudKit schema initialization in debug builds
        #if DEBUG
        do {
            try container.initializeCloudKitSchema()
            logger.info("CloudKit schema initialized successfully")
        } catch {
            logger.error("Failed to initialize CloudKit schema: \(error.localizedDescription, privacy: .public)")
        }
        #endif
    }

    // MARK: - Sharing

    /// Creates or retrieves a `CKShare` for the given child, moving the child
    /// and all related artworks into a shared CloudKit zone.
    ///
    /// - Parameter child: The child profile to share.
    /// - Returns: A tuple of the share record and its CloudKit container.
    func shareChild(_ child: Child) async throws -> (CKShare, CKContainer) {
        guard let container = persistentContainer else {
            throw SharingError.notInitialised
        }

        let objectID = try managedObjectID(for: child)
        let managedObject = container.viewContext.object(with: objectID)
        let thumbnail = circularThumbnail(from: child.avatarImageData)
            ?? generateAvatarThumbnail(name: child.name, colorHex: child.avatarColor)

        // Clear any "stopped sharing" override for this child
        if let urlString = child.objectIDURL?.absoluteString {
            stoppedSharingURLs.remove(urlString)
        }

        // Check for existing share — update metadata in case it changed
        if let existingShares = try? container.fetchShares(matching: [objectID]),
           let existing = existingShares[objectID] {
            existing[CKShare.SystemFieldKey.title] = child.name
            existing[CKShare.SystemFieldKey.thumbnailImageData] = thumbnail
            if container.viewContext.hasChanges {
                try container.viewContext.save()
            }
            return (existing, CKContainer(identifier: ckContainerIdentifier))
        }

        // Create new share
        let (_, share, ckContainer) = try await container.share(
            [managedObject],
            to: nil
        )

        share[CKShare.SystemFieldKey.title] = child.name
        share[CKShare.SystemFieldKey.thumbnailImageData] = thumbnail

        // Save the context to persist the share
        if container.viewContext.hasChanges {
            try container.viewContext.save()
        }

        return (share, ckContainer)
    }

    /// Clips a photo to a circle and returns PNG data.
    private func circularThumbnail(from imageData: Data?) -> Data? {
        guard let imageData, let source = UIImage(data: imageData) else { return nil }
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        return image.pngData()
    }

    /// Generates a circular thumbnail from the child's avatar color and name initial.
    private func generateAvatarThumbnail(name: String, colorHex: String) -> Data? {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            UIColor(Color(hex: colorHex)).setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            let initial = String(name.prefix(1)).uppercased()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 52, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = initial.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            initial.draw(in: textRect, withAttributes: attrs)
        }
        return image.pngData()
    }

    /// Returns whether the given child is currently being shared.
    func isShared(_ child: Child) -> Bool {
        // Check local override first (sharing was stopped but CloudKit hasn't synced)
        if let urlString = child.objectIDURL?.absoluteString,
           stoppedSharingURLs.contains(urlString) {
            return false
        }
        guard let container = persistentContainer,
              let objectID = try? managedObjectID(for: child) else {
            return false
        }
        let shares = try? container.fetchShares(matching: [objectID])
        return shares?[objectID] != nil
    }

    /// Returns the existing `CKShare` for the given child, if one exists.
    func existingShare(for child: Child) -> CKShare? {
        guard let container = persistentContainer,
              let objectID = try? managedObjectID(for: child) else {
            return nil
        }
        let shares = try? container.fetchShares(matching: [objectID])
        return shares?[objectID]
    }

    /// Stops sharing the given child by deleting the CKShare record.
    func stopSharing(_ child: Child) async throws {
        guard let container = persistentContainer else {
            throw SharingError.notInitialised
        }

        let objectID = try managedObjectID(for: child)
        guard let existingShares = try? container.fetchShares(matching: [objectID]),
              let share = existingShares[objectID] else {
            logger.info("No share found for child — nothing to stop")
            return
        }

        logger.info("Stopping share: recordID=\(share.recordID.recordName, privacy: .public)")

        let ckContainer = CKContainer(identifier: ckContainerIdentifier)
        let database = ckContainer.privateCloudDatabase

        // Delete the share record from CloudKit
        try await database.deleteRecord(withID: share.recordID)
        logger.info("Share record deleted from CloudKit")

        // Mark locally so isShared() returns false immediately
        if let urlString = child.objectIDURL?.absoluteString {
            stoppedSharingURLs.insert(urlString)
        }

        // Save local context so Core Data picks up the change
        if container.viewContext.hasChanges {
            try container.viewContext.save()
        }
    }

    /// Accepts an incoming share invitation.
    ///
    /// Automatically initialises the CloudKit stack if needed so that
    /// share acceptance works even when the user hasn't enabled iCloud
    /// sync in Settings (e.g. recipient opening a share link for the first time).
    func acceptShare(metadata: CKShare.Metadata) {
        // Ensure the CloudKit stack is ready before accepting
        if persistentContainer == nil {
            logger.info("Initialising CloudKit stack for share acceptance")
            setup()
        }

        guard let container = persistentContainer,
              let sharedStore else {
            logger.error("Cannot accept share — CloudKit stack failed to initialise")
            return
        }

        logger.info("Accepting share invitation: \(metadata.share.recordID.recordName, privacy: .public)")

        container.acceptShareInvitations(
            from: [metadata],
            into: sharedStore
        ) { _, error in
            if let error {
                logger.error("Failed to accept share: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("Share accepted successfully")
            }
        }
    }

    // MARK: - Helpers

    /// Converts a SwiftData `Child` to a Core Data `NSManagedObjectID`.
    ///
    /// Both stacks use the same SQLite file, so the URI representation
    /// of the persistent identifier maps directly to a managed object ID.
    ///
    /// - Important: `NSPersistentStoreCoordinator.managedObjectID(forURIRepresentation:)`
    ///   raises an Objective-C `NSException` (not a Swift `Error`) when the URI's
    ///   store UUID doesn't match any loaded store. We validate the URI first to
    ///   avoid the uncatchable exception.
    private func managedObjectID(for child: Child) throws -> NSManagedObjectID {
        guard let container = persistentContainer else {
            throw SharingError.notInitialised
        }

        guard let url = child.objectIDURL else {
            logger.warning("Could not extract objectIDURL from SwiftData model")
            throw SharingError.objectIDNotFound
        }
        let coordinator = container.persistentStoreCoordinator

        // The x-coredata:// URI format is:
        //   x-coredata://<storeUUID>/<EntityName>/<primaryKey>
        // The host component is the store's UUID. Validate it matches a
        // loaded store before calling managedObjectID(forURIRepresentation:),
        // which raises an uncatchable NSException on mismatch.
        guard let storeUUID = url.host, !storeUUID.isEmpty else {
            logger.warning("objectIDURL has no store UUID: \(url.absoluteString, privacy: .public)")
            throw SharingError.objectIDNotFound
        }

        let knownStoreIDs = Set(
            coordinator.persistentStores.compactMap { $0.identifier }
        )
        guard knownStoreIDs.contains(storeUUID) else {
            logger.warning("Store UUID \(storeUUID, privacy: .public) not in loaded stores: \(knownStoreIDs.description, privacy: .public)")
            throw SharingError.objectIDNotFound
        }

        guard let objectID = coordinator.managedObjectID(
            forURIRepresentation: url
        ) else {
            throw SharingError.objectIDNotFound
        }

        return objectID
    }

    // MARK: - Errors

    enum SharingError: LocalizedError {
        case notInitialised
        case objectIDNotFound

        var errorDescription: String? {
            switch self {
            case .notInitialised:
                return "CloudKit sharing service is not initialised."
            case .objectIDNotFound:
                return "Could not find the managed object for this child."
            }
        }
    }
}

// MARK: - PersistentModel URI Helper

extension PersistentModel {
    /// Returns the Core Data object URI for this SwiftData model, or `nil`
    /// if the identifier cannot be extracted.
    ///
    /// SwiftData's `PersistentIdentifier` uses the same `x-coredata://` URI scheme
    /// as `NSManagedObjectID`, so we can bridge between the two stacks.
    var objectIDURL: URL? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(persistentModelID),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let impl = json["implementation"] as? [String: Any],
              let uriString = impl["uriRepresentation"] as? String,
              let url = URL(string: uriString),
              url.host != nil, url.host?.isEmpty == false else {
            return nil
        }
        return url
    }
}
