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
import SwiftData
import SwiftUI

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
            print("[CloudKitSharingService] Failed to create managed object model from SwiftData types")
            return
        }

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

        container.loadPersistentStores { description, error in
            if let error {
                print("[CloudKitSharingService] Failed to load store at \(description.url?.lastPathComponent ?? "?"): \(error)")
                return
            }
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

        // Check for existing share
        if let existingShares = try? container.fetchShares(matching: [objectID]),
           let existing = existingShares[objectID] {
            return (existing, CKContainer(identifier: ckContainerIdentifier))
        }

        // Create new share
        let (_, share, ckContainer) = try await container.share(
            [managedObject],
            to: nil
        )

        share[CKShare.SystemFieldKey.title] = child.name

        // Save the context to persist the share
        if container.viewContext.hasChanges {
            try container.viewContext.save()
        }

        return (share, ckContainer)
    }

    /// Returns whether the given child is currently being shared.
    func isShared(_ child: Child) -> Bool {
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

    /// Stops sharing the given child by purging the share zone.
    func stopSharing(_ child: Child) async throws {
        guard let share = existingShare(for: child) else { return }

        let ckContainer = CKContainer(identifier: ckContainerIdentifier)
        let database = ckContainer.privateCloudDatabase

        let operation = CKModifyRecordsOperation(
            recordsToSave: nil,
            recordIDsToDelete: [share.recordID]
        )
        operation.qualityOfService = QualityOfService.userInitiated

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { (result: Result<Void, Error>) in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    /// Accepts an incoming share invitation.
    func acceptShare(metadata: CKShare.Metadata) {
        guard let container = persistentContainer,
              let sharedStore else {
            return
        }
        container.acceptShareInvitations(
            from: [metadata],
            into: sharedStore
        ) { _, error in
            if let error {
                print("[CloudKitSharingService] Failed to accept share: \(error)")
            }
        }
    }

    // MARK: - Helpers

    /// Converts a SwiftData `Child` to a Core Data `NSManagedObjectID`.
    ///
    /// Both stacks use the same SQLite file, so the URI representation
    /// of the persistent identifier maps directly to a managed object ID.
    private func managedObjectID(for child: Child) throws -> NSManagedObjectID {
        guard let container = persistentContainer else {
            throw SharingError.notInitialised
        }

        let coordinator = container.persistentStoreCoordinator

        // PersistentIdentifier uses the same x-coredata:// URI scheme
        // as NSManagedObjectID, so we can bridge between the two stacks.
        guard let objectID = coordinator.managedObjectID(
            forURIRepresentation: child.objectIDURL
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
    /// Returns the Core Data object URI for this SwiftData model.
    ///
    /// SwiftData's `PersistentIdentifier` uses the same x-coredata:// URI scheme
    /// as `NSManagedObjectID`, so we can bridge between the two stacks.
    var objectIDURL: URL {
        // PersistentIdentifier stores its URI in the id property.
        // Mirror or Codable can extract it, but the simplest approach is
        // encoding the identifier to JSON and parsing the URI string.
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(persistentModelID),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let impl = json["implementation"] as? [String: Any],
           let uriString = impl["uriRepresentation"] as? String,
           let url = URL(string: uriString) {
            return url
        }
        // Fallback: construct from the entity name
        return URL(string: "x-coredata:///\(type(of: self))")!
    }
}
