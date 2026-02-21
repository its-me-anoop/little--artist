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

// MARK: - Sync Engine Protocol

/// Abstraction for the sync engine so the service can be tested
/// and its responsibilities are clearly separated (Dependency Inversion).
protocol CloudKitSyncEngine: Sendable {
    @MainActor func refreshSwiftDataContext()
    @MainActor func syncSharedDataToSwiftData()
}

// MARK: - Artwork Matching Strategy

/// Encapsulates the logic for matching artworks across stacks (Single Responsibility).
/// Used by both the shared-data mirror and the deduplication passes.
enum ArtworkMatchStrategy {
    /// Legacy key for an artwork: title + creation date rounded to the
    /// nearest second. Used as a fallback when `syncIdentifier` is not
    /// available (pre-V6 artworks).
    static func legacyKey(for artwork: Artwork) -> String {
        "\(artwork.title)|\(Int(artwork.createdAt.timeIntervalSince1970))"
    }

    /// Builds a legacy key from raw managed-object values (shared store mirroring).
    static func legacyKey(title: String, createdAt: Date) -> String {
        "\(title)|\(Int(createdAt.timeIntervalSince1970))"
    }

    /// Returns the stable sync key when a `syncIdentifier` is available.
    static func stableKey(for artwork: Artwork) -> String? {
        guard let id = artwork.syncIdentifier, !id.isEmpty else { return nil }
        return "sync:\(id)"
    }

    /// Score indicating how much data an artwork carries — higher is better.
    /// Used to decide which duplicate to keep when merging.
    static func dataScore(for artwork: Artwork) -> Int {
        var score = 0
        if artwork.imageData != nil { score += 10 }
        score += artwork.caption.count
        if artwork.voiceNoteData != nil { score += 5 }
        if artwork.isFavorited { score += 1 }
        return score
    }

    /// Returns true when two artworks with the same legacy key are genuinely
    /// duplicates rather than distinct artworks that happen to share a
    /// title and creation second (e.g. batch imports with different images).
    static func areLikelyDuplicates(_ a: Artwork, _ b: Artwork) -> Bool {
        // If either is missing image data, fall back to key-only matching
        guard let aSize = a.imageData?.count, let bSize = b.imageData?.count else {
            return true
        }
        // Images within 1 KB are considered the same (compression variance)
        return abs(aSize - bSize) <= 1024
    }
}

/// Manages CloudKit sharing using `NSPersistentCloudKitContainer`.
///
/// SwiftData (as of iOS 18) lacks a shared-database API, so this service
/// provides a parallel Core Data stack that owns CloudKit sync for both
/// the private and shared databases. SwiftData reads from the same private
/// SQLite file with `cloudKitDatabase: .none`.
///
/// ## Architecture
///
/// ```
/// SwiftData (.none)  ──writes──>  default.store  <──reads/writes──  NSPersistentCloudKitContainer
///                                                                        │
///                                shared.store   <────────────────────────┘
///                                (shared zone)       (private + shared zones)
///                                     │
///                             syncSharedDataToSwiftData()
///                                     │
///                                     v
///                              SwiftData @Query
/// ```
///
/// **Private sync:** Core Data writes CloudKit data to `default.store`.
/// SwiftData reads the same file but needs an explicit refresh to pick up
/// external writes (see ``refreshSwiftDataContext()``).
///
/// **Shared sync:** Shared-zone data lands in `shared.store`. This service
/// mirrors it into SwiftData via ``syncSharedDataToSwiftData()``.
@MainActor @Observable
final class CloudKitSharingService: CloudKitSyncEngine {

    // MARK: - Singleton

    static let shared = CloudKitSharingService()

    // MARK: - Properties

    private(set) var persistentContainer: NSPersistentCloudKitContainer?
    private var privateStore: NSPersistentStore?
    private var sharedStore: NSPersistentStore?

    /// SwiftData model container for mirroring shared data.
    var modelContainer: ModelContainer?

    /// Child object URLs whose sharing was stopped locally (pending CloudKit sync).
    private var stoppedSharingURLs: Set<String> = []

    /// Throttle: last time `syncSharedDataToSwiftData` actually executed.
    private var lastSyncDate: Date = .distantPast

    /// Throttle: last time `refreshSwiftDataContext` actually executed.
    private var lastRefreshDate: Date = .distantPast

    /// Minimum interval between successive shared-store syncs (seconds).
    private let syncThrottleInterval: TimeInterval = 5.0

    /// Minimum interval between successive SwiftData refreshes (seconds).
    private let refreshThrottleInterval: TimeInterval = 2.0

    /// Whether a throttled sync is already scheduled.
    private var pendingThrottledSync = false

    /// Whether a throttled refresh is already scheduled.
    private var pendingThrottledRefresh = false

    /// Whether sync operations should run. Set to `false` when the user
    /// disables iCloud Sync in Settings (Open/Closed principle — the stack
    /// stays alive but sync is paused, avoiding a risky teardown).
    var isSyncEnabled: Bool = true

    /// The CloudKit container identifier used by this app.
    let ckContainerIdentifier = "iCloud.uk.co.flutterly.Little-Artist"

    /// Whether the Core Data + CloudKit stack has been initialised.
    var isInitialised: Bool { persistentContainer != nil }

    // MARK: - Diagnostics

    /// Rolling log of sharing events for on-device diagnosis.
    var diagnosticLog: [String] = []

    /// Records a timestamped diagnostic entry visible in Settings.
    func diag(_ message: String) {
        let ts = DateFormatter.localizedString(from: .now, dateStyle: .none, timeStyle: .medium)
        let entry = "[\(ts)] \(message)"
        diagnosticLog.append(entry)
        // Keep last 50 entries
        if diagnosticLog.count > 50 { diagnosticLog.removeFirst(diagnosticLog.count - 50) }
        logger.info("\(entry, privacy: .public)")
    }

    /// Returns a snapshot of the current sharing stack state for display in Settings.
    func diagnosticSnapshot() -> [String: String] {
        var info: [String: String] = [:]
        info["Container"] = persistentContainer != nil ? "Ready" : "Not initialised"
        info["Private Store"] = privateStore != nil ? "Loaded" : "Missing"
        info["Shared Store"] = sharedStore != nil ? "Loaded" : "Missing"
        info["Model Container"] = modelContainer != nil ? "Set" : "Missing"
        info["Sync Enabled"] = isSyncEnabled ? "Yes" : "Paused"

        // Count children in shared Core Data store
        if let container = persistentContainer, let sharedStore {
            let req = NSFetchRequest<NSManagedObject>(entityName: "Child")
            req.affectedStores = [sharedStore]
            let count = (try? container.viewContext.count(for: req)) ?? -1
            info["Shared Store Children"] = "\(count)"
        } else {
            info["Shared Store Children"] = "N/A"
        }

        // Count mirrored children in SwiftData
        if let mc = modelContainer {
            let desc = FetchDescriptor<Child>(
                predicate: #Predicate<Child> { $0.sharedRecordName != nil }
            )
            let count = (try? mc.mainContext.fetchCount(desc)) ?? -1
            info["Mirrored Children"] = "\(count)"
        } else {
            info["Mirrored Children"] = "N/A"
        }

        return info
    }

    // MARK: - Init

    private init() {}

    // MARK: - Stack Setup

    /// Initialises the `NSPersistentCloudKitContainer` with private and shared stores.
    ///
    /// Call this once from the app entry point when premium + iCloud are enabled.
    /// The private store points to the same SQLite file SwiftData uses so both
    /// stacks stay in sync via persistent history tracking.
    func setup() {
        guard persistentContainer == nil else {
            diag("setup: already initialised — skipping")
            return
        }
        diag("setup: starting CloudKit stack init")

        guard let model = NSManagedObjectModel.makeManagedObjectModel(for: [
            Child.self,
            Artwork.self,
            Tag.self
        ]) else {
            diag("setup: FAILED — could not create managed object model")
            return
        }
        let entityNames = model.entities.compactMap(\.name).joined(separator: ", ")
        logger.info("Created managed object model with \(model.entities.count) entities: \(entityNames, privacy: .public)")

        // Log full model details for diagnostics — helps identify relationship mismatches
        for entity in model.entities {
            let attrNames = entity.attributesByName.keys.sorted().joined(separator: ", ")
            let relDetails = entity.relationshipsByName.map { name, rel in
                "\(name)→\(rel.destinationEntity?.name ?? "?")(toMany=\(rel.isToMany), inverse=\(rel.inverseRelationship?.name ?? "nil"))"
            }.joined(separator: ", ")
            logger.info("  Entity '\(entity.name ?? "?", privacy: .public)': attrs=[\(attrNames, privacy: .public)] rels=[\(relDetails, privacy: .public)]")
        }
        diag("setup: model has \(model.entities.count) entities: \(entityNames)")

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
        privateDesc.shouldMigrateStoreAutomatically = true
        privateDesc.shouldInferMappingModelAutomatically = true

        // Shared store — separate file for shared zone data
        let sharedURL = appSupport.appendingPathComponent("shared.store")
        let sharedDesc = NSPersistentStoreDescription(url: sharedURL)
        sharedDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: ckContainerIdentifier
        )
        sharedDesc.cloudKitContainerOptions?.databaseScope = .shared
        sharedDesc.shouldMigrateStoreAutomatically = true
        sharedDesc.shouldInferMappingModelAutomatically = true
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
            diag("setup: FAILED — \(loadErrors.count) store(s) failed to load: \(loadErrors.joined(separator: "; "))")
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
        isSyncEnabled = true
        diag("setup: stores loaded — private=\(privateStore != nil) shared=\(sharedStore != nil)")

        // Listen for remote changes from CloudKit on EITHER store.
        // - Private store changes → refresh SwiftData so @Query picks up new data
        // - Shared store changes  → mirror shared children/artworks into SwiftData
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isSyncEnabled else { return }
                // Refresh SwiftData context so @Query sees private-zone changes
                self.scheduleThrottledRefresh()
                // Mirror shared-zone data into SwiftData
                self.scheduleThrottledSync()
            }
        }

        // Force CloudKit schema initialization in debug builds
        #if DEBUG
        do {
            try container.initializeCloudKitSchema()
            logger.info("CloudKit schema initialized successfully")
        } catch {
            logger.error("Failed to initialize CloudKit schema: \(error.localizedDescription, privacy: .public)")
        }
        #endif

        // Defer initial sync to next run loop to avoid issues during setup
        DispatchQueue.main.async { [weak self] in
            self?.backfillSyncIdentifiers()
            self?.refreshSwiftDataContext()
            self?.syncSharedDataToSwiftData()
        }
    }

    // MARK: - SwiftData Refresh (Private Sync)

    /// Forces SwiftData to process persistent history written by the Core Data
    /// coordinator, ensuring `@Query` results reflect CloudKit private-zone changes.
    ///
    /// When `NSPersistentCloudKitContainer` writes remote data to `default.store`,
    /// SwiftData's `ModelContext` doesn't automatically pick it up because it uses
    /// a separate `NSPersistentStoreCoordinator`. Performing a fetch triggers
    /// SwiftData to read the latest persistent history and update live queries.
    func refreshSwiftDataContext() {
        lastRefreshDate = .now

        guard let modelContainer else {
            diag("refresh: SKIP — no model container")
            return
        }

        let context = modelContainer.mainContext
        // Fetch forces SwiftData to process persistent history transactions
        // from the Core Data coordinator, causing @Query to refresh.
        var childFetch = FetchDescriptor<Child>()
        childFetch.fetchLimit = 1
        let _ = try? context.fetch(childFetch)
        var artworkFetch = FetchDescriptor<Artwork>()
        artworkFetch.fetchLimit = 1
        let _ = try? context.fetch(artworkFetch)
        diag("refresh: SwiftData context refreshed for private-zone changes")
    }

    /// Schedules a throttled SwiftData refresh — prevents excessive re-fetching
    /// when multiple remote change notifications arrive in quick succession.
    private func scheduleThrottledRefresh() {
        let elapsed = Date.now.timeIntervalSince(lastRefreshDate)
        if elapsed >= refreshThrottleInterval {
            refreshSwiftDataContext()
        } else if !pendingThrottledRefresh {
            pendingThrottledRefresh = true
            let remaining = refreshThrottleInterval - elapsed
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                self?.pendingThrottledRefresh = false
                self?.refreshSwiftDataContext()
            }
        }
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

        // Check for existing share — update metadata and ensure new artworks are included
        if let existingShares = try? container.fetchShares(matching: [objectID]),
           let existing = existingShares[objectID] {
            existing[CKShare.SystemFieldKey.title] = child.name
            existing[CKShare.SystemFieldKey.thumbnailImageData] = thumbnail

            // Ensure any artworks added AFTER the original share are also shared.
            // Artworks not yet in the shared zone need to be explicitly added.
            try await ensureArtworksInShare(for: managedObject, share: existing, container: container)

            if container.viewContext.hasChanges {
                try container.viewContext.save()
            }
            return (existing, CKContainer(identifier: ckContainerIdentifier))
        }

        // Collect the child AND all its artworks for explicit sharing.
        // Core Data should follow relationships automatically, but being
        // explicit ensures artworks are always included in the shared zone.
        var objectsToShare: [NSManagedObject] = [managedObject]

        if let artworkSet = managedObject.value(forKey: "artworks") as? NSSet {
            let artworkMOs = artworkSet.compactMap { $0 as? NSManagedObject }
            objectsToShare.append(contentsOf: artworkMOs)
            diag("shareChild: explicitly including \(artworkMOs.count) artwork(s) in share")
        } else {
            // Relationship may be nil — log available relationship names for debugging
            let relNames = managedObject.entity.relationshipsByName.keys.sorted()
            diag("shareChild: WARNING — 'artworks' relationship returned nil. Available: \(relNames)")
        }

        // Create new share with child + all artworks
        let (sharedIDs, share, ckContainer) = try await container.share(
            objectsToShare,
            to: nil
        )

        diag("shareChild: shared \(sharedIDs.count) object(s) total (child + \(sharedIDs.count - 1) related)")

        share[CKShare.SystemFieldKey.title] = child.name
        share[CKShare.SystemFieldKey.thumbnailImageData] = thumbnail

        // Save the context to persist the share
        if container.viewContext.hasChanges {
            try container.viewContext.save()
        }

        // Record that this child is now shared so dedup can identify it
        if let recordID = container.recordID(for: managedObject.objectID) {
            child.sharedRecordName = recordID.recordName
            diag("shareChild: set sharedRecordName=\(recordID.recordName.prefix(30))...")
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

    /// Ensures all artworks belonging to a shared child are in the shared zone.
    ///
    /// When new artworks are added to a child AFTER the initial share was created,
    /// they live in the private zone by default. This method moves any un-shared
    /// artworks into the existing share so the recipient can see them.
    private func ensureArtworksInShare(
        for managedChild: NSManagedObject,
        share: CKShare,
        container: NSPersistentCloudKitContainer
    ) async throws {
        guard let artworkSet = managedChild.value(forKey: "artworks") as? NSSet else {
            diag("ensureArtworksInShare: no artworks relationship — skipping")
            return
        }

        var unsharedArtworks: [NSManagedObject] = []
        for case let artwork as NSManagedObject in artworkSet {
            // Check if this artwork already has a share
            let artworkShares = try? container.fetchShares(matching: [artwork.objectID])
            if artworkShares?[artwork.objectID] == nil {
                unsharedArtworks.append(artwork)
            }
        }

        guard !unsharedArtworks.isEmpty else {
            diag("ensureArtworksInShare: all \(artworkSet.count) artworks already shared")
            return
        }

        diag("ensureArtworksInShare: adding \(unsharedArtworks.count) new artwork(s) to existing share")
        let (sharedIDs, _, _) = try await container.share(unsharedArtworks, to: share)
        diag("ensureArtworksInShare: \(sharedIDs.count) object(s) added to share")
    }

    /// Accepts an incoming share invitation.
    ///
    /// Automatically initialises the CloudKit stack if needed so that
    /// share acceptance works even when the user hasn't enabled iCloud
    /// sync in Settings (e.g. recipient opening a share link for the first time).
    func acceptShare(metadata: CKShare.Metadata) {
        diag("acceptShare: CALLED with record=\(metadata.share.recordID.recordName)")

        // Ensure the CloudKit stack is ready before accepting
        if persistentContainer == nil {
            diag("acceptShare: container nil — calling setup()")
            setup()
        }

        guard let container = persistentContainer,
              let sharedStore else {
            diag("acceptShare: FAILED — stack not initialised")
            return
        }

        diag("acceptShare: calling acceptShareInvitations")

        container.acceptShareInvitations(
            from: [metadata],
            into: sharedStore
        ) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.diag("acceptShare: FAILED — \(error.localizedDescription)")
                    return
                }
                self.diag("acceptShare: SUCCESS — scheduling sync retries")
                // CloudKit needs time to download shared records after
                // acceptance. Retry with increasing delays, checking if data
                // has actually appeared in the shared store each time.
                for delay in [2.0, 5.0, 10.0, 20.0, 40.0, 60.0] {
                    guard !Task.isCancelled else { break }
                    try? await Task.sleep(for: .seconds(delay))

                    // Check if shared data has appeared
                    var sharedChildCount = 0
                    var sharedArtworkCount = 0
                    if let container = self.persistentContainer, let sharedStore = self.sharedStore {
                        container.viewContext.refreshAllObjects()
                        let childReq = NSFetchRequest<NSManagedObject>(entityName: "Child")
                        childReq.affectedStores = [sharedStore]
                        sharedChildCount = (try? container.viewContext.count(for: childReq)) ?? 0

                        let artReq = NSFetchRequest<NSManagedObject>(entityName: "Artwork")
                        artReq.affectedStores = [sharedStore]
                        sharedArtworkCount = (try? container.viewContext.count(for: artReq)) ?? 0
                    }

                    self.diag("acceptShare: retry after \(Int(delay))s — \(sharedChildCount) children, \(sharedArtworkCount) artworks in shared store")

                    self.refreshSwiftDataContext()
                    self.syncSharedDataToSwiftData()

                    // If we found data, run one final sync after a short delay and stop
                    if sharedChildCount > 0 {
                        try? await Task.sleep(for: .seconds(3))
                        self.syncSharedDataToSwiftData()
                        self.diag("acceptShare: shared data found — sync complete")
                        break
                    }
                }
            }
        }
    }

    /// Manually triggers a full sync — available for diagnostic use.
    func runManualSync() {
        diag("manual sync: triggered by user")
        refreshSwiftDataContext()
        syncSharedDataToSwiftData()
    }

    // MARK: - Shared Data Sync

    /// Schedules a throttled sync — prevents the sync from running more
    /// than once every `syncThrottleInterval` seconds.
    private func scheduleThrottledSync() {
        let elapsed = Date.now.timeIntervalSince(lastSyncDate)
        if elapsed >= syncThrottleInterval {
            // Enough time has passed — sync immediately
            syncSharedDataToSwiftData()
        } else if !pendingThrottledSync {
            // Schedule a deferred sync
            pendingThrottledSync = true
            let remaining = syncThrottleInterval - elapsed
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                self?.pendingThrottledSync = false
                self?.syncSharedDataToSwiftData()
            }
        }
        // else: a throttled sync is already pending — ignore
    }

    /// Mirrors children and artworks from the Core Data shared store into
    /// SwiftData so they appear alongside locally created data.
    ///
    /// Deduplication strategy (in order):
    /// 1. Match by `sharedRecordName` — already mirrored, update fields
    /// 2. Match by name (case-insensitive) — local child on same-account device,
    ///    adopt it as mirror rather than creating a duplicate
    /// 3. No match — create a new mirror
    ///
    /// Called automatically when remote change notifications arrive on the
    /// shared store, and once at startup. Wrapped in error handling to
    /// prevent crashes from propagating.
    func syncSharedDataToSwiftData() {
        lastSyncDate = .now

        guard isSyncEnabled else {
            diag("sync: SKIP — sync is paused")
            return
        }
        guard let container = persistentContainer else {
            diag("sync: SKIP — no container")
            return
        }
        guard let sharedStore else {
            diag("sync: SKIP — no shared store")
            return
        }
        guard let modelContainer else {
            diag("sync: SKIP — no model container")
            return
        }

        do {
            let context = container.viewContext
            // Refresh context to pick up any new CloudKit imports
            context.refreshAllObjects()

            // Fetch all Child objects from the shared store
            let childRequest = NSFetchRequest<NSManagedObject>(entityName: "Child")
            childRequest.affectedStores = [sharedStore]

            let sharedChildren = try context.fetch(childRequest)

            diag("sync: \(sharedChildren.count) children in shared store")

            // Also count artworks in shared store for diagnostics
            let artworkReq = NSFetchRequest<NSManagedObject>(entityName: "Artwork")
            artworkReq.affectedStores = [sharedStore]
            let sharedArtworkCount = (try? context.count(for: artworkReq)) ?? -1
            diag("sync: \(sharedArtworkCount) artworks in shared store")

            let modelContext = modelContainer.mainContext

            // Always run dedup even if shared store is empty — catches
            // duplicates created by private CloudKit sync (same-account).
            if sharedChildren.isEmpty {
                removeDuplicateMirrors(modelContext: modelContext)
                deduplicateArtworks(modelContext: modelContext)
                if modelContext.hasChanges {
                    try modelContext.save()
                    diag("sync: dedup-only pass saved")
                }
                return
            }

            // Track artwork changes per child for notifications
            var artworkChanges: [(childName: String, inserted: Int, updated: Int)] = []

            for managedChild in sharedChildren {
                let recordName = container.recordID(for: managedChild.objectID)?.recordName
                    ?? managedChild.objectID.uriRepresentation().absoluteString
                let childName = managedChild.value(forKey: "name") as? String ?? "?"

                diag("sync: processing '\(childName)' record=\(recordName.prefix(30))...")

                // --- Dedup Step 1: match by sharedRecordName ---
                var byRecord = FetchDescriptor<Child>(
                    predicate: #Predicate { $0.sharedRecordName == recordName }
                )
                byRecord.fetchLimit = 1
                if let found = try? modelContext.fetch(byRecord), let mirror = found.first {
                    mirror.name = managedChild.value(forKey: "name") as? String ?? mirror.name
                    mirror.avatarColor = managedChild.value(forKey: "avatarColor") as? String ?? mirror.avatarColor
                    mirror.avatarImageData = managedChild.value(forKey: "avatarImageData") as? Data
                    let counts = syncArtworks(for: managedChild, into: mirror, modelContext: modelContext)
                    artworkChanges.append((mirror.name, counts.inserted, counts.updated))
                    diag("sync: updated existing mirror for '\(mirror.name)'")
                    continue
                }

                // --- Dedup Step 2: match by name (catches same-account duplicates) ---
                let nameToMatch = childName.lowercased()
                let byName = FetchDescriptor<Child>(
                    predicate: #Predicate { child in
                        child.sharedRecordName == nil
                    }
                )
                let localChildren = (try? modelContext.fetch(byName)) ?? []
                if let match = localChildren.first(where: { $0.name.lowercased() == nameToMatch }) {
                    // Adopt the existing local child as the mirror
                    match.sharedRecordName = recordName
                    match.avatarColor = managedChild.value(forKey: "avatarColor") as? String ?? match.avatarColor
                    match.avatarImageData = managedChild.value(forKey: "avatarImageData") as? Data
                    let counts = syncArtworks(for: managedChild, into: match, modelContext: modelContext)
                    artworkChanges.append((match.name, counts.inserted, counts.updated))
                    diag("sync: adopted local '\(match.name)' as mirror (same name)")
                    continue
                }

                // --- Step 3: create new mirror ---
                let newChild = Child(
                    name: childName == "?" ? "Shared Child" : childName,
                    avatarColor: managedChild.value(forKey: "avatarColor") as? String ?? Brand.defaultAvatarColor,
                    avatarImageData: managedChild.value(forKey: "avatarImageData") as? Data,
                    createdAt: managedChild.value(forKey: "createdAt") as? Date ?? .now
                )
                newChild.sharedRecordName = recordName
                modelContext.insert(newChild)

                let counts = syncArtworks(for: managedChild, into: newChild, modelContext: modelContext)
                artworkChanges.append((newChild.name, counts.inserted, counts.updated))

                diag("sync: CREATED new mirror for '\(newChild.name)'")
            }

            // --- Dedup pass: remove stale duplicates ---
            removeDuplicateMirrors(modelContext: modelContext)
            deduplicateArtworks(modelContext: modelContext)

            // --- Orphan cleanup: remove mirrors whose shared records are gone ---
            cleanupOrphanedMirrors(
                sharedChildren: sharedChildren,
                container: container,
                modelContext: modelContext
            )

            try modelContext.save()
            diag("sync: SAVED to SwiftData successfully")

            // Send notifications for shared artwork changes
            for change in artworkChanges where change.inserted > 0 || change.updated > 0 {
                NotificationService.notifySharedArtworkChanges(
                    childName: change.childName,
                    insertedCount: change.inserted,
                    updatedCount: change.updated
                )
            }
        } catch {
            diag("sync: FAILED — \(error.localizedDescription)")
        }
    }

    // MARK: - Deduplication

    /// Removes duplicate children across three scenarios:
    /// 1. Same `sharedRecordName` — exact mirror duplicates
    /// 2. Mirror + local with same name — adopt local into mirror
    /// 3. Two+ locals with same name — merge into one (same-account sync dupes)
    private func removeDuplicateMirrors(modelContext: ModelContext) {
        guard let allChildren = try? modelContext.fetch(FetchDescriptor<Child>()) else { return }

        // --- Pass 1: same sharedRecordName duplicates ---
        var seenRecords: [String: Child] = [:]
        for child in allChildren {
            guard let rn = child.sharedRecordName else { continue }
            if let existing = seenRecords[rn] {
                let existingCount = existing.artworks?.count ?? 0
                let thisCount = child.artworks?.count ?? 0
                if thisCount > existingCount {
                    diag("dedup: removing duplicate mirror '\(existing.name)' (fewer artworks)")
                    transferArtworks(from: existing, to: child, modelContext: modelContext)
                    modelContext.delete(existing)
                    seenRecords[rn] = child
                } else {
                    diag("dedup: removing duplicate mirror '\(child.name)' (fewer artworks)")
                    transferArtworks(from: child, to: existing, modelContext: modelContext)
                    modelContext.delete(child)
                }
            } else {
                seenRecords[rn] = child
            }
        }

        // --- Pass 2: group ALL remaining children by name ---
        // Re-fetch to ensure we only see live (non-deleted) objects.
        let remaining = (try? modelContext.fetch(FetchDescriptor<Child>())) ?? []
        var byName: [String: [Child]] = [:]
        for child in remaining {
            let key = child.name.lowercased().trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty else { continue }
            byName[key, default: []].append(child)
        }

        for (name, group) in byName where group.count > 1 {
            let mirrors = group.filter { $0.sharedRecordName != nil }
            let locals = group.filter { $0.sharedRecordName == nil }

            // Pick the "keeper": prefer a mirror, otherwise the local with the most artworks
            let keeper: Child
            if let mirror = mirrors.first {
                keeper = mirror
            } else {
                keeper = locals.sorted { ($0.artworks?.count ?? 0) > ($1.artworks?.count ?? 0) }.first!
            }

            // Merge all others into the keeper
            for child in group where child !== keeper {
                transferArtworks(from: child, to: keeper, modelContext: modelContext)
                diag("dedup: merged '\(child.name)' into keeper (shared=\(keeper.sharedRecordName != nil)) and deleted duplicate")
                modelContext.delete(child)
            }

            if group.count > 1 {
                diag("dedup: '\(name)' — kept 1, removed \(group.count - 1) duplicate(s)")
            }
        }
    }

    /// Transfers artworks from `source` to `target` that don't already
    /// exist on the target (matched by syncIdentifier first, then legacy key).
    private func transferArtworks(from source: Child, to target: Child, modelContext: ModelContext) {
        guard let sourceArtworks = source.artworks, !sourceArtworks.isEmpty else { return }
        let targetArtworks = target.artworks ?? []

        // Build lookup sets for target
        var targetSyncIds = Set<String>()
        var targetLegacyKeys = Set<String>()
        for art in targetArtworks {
            if let stableKey = ArtworkMatchStrategy.stableKey(for: art) {
                targetSyncIds.insert(stableKey)
            }
            targetLegacyKeys.insert(ArtworkMatchStrategy.legacyKey(for: art))
        }

        for art in sourceArtworks {
            // Check stable key first
            if let stableKey = ArtworkMatchStrategy.stableKey(for: art),
               targetSyncIds.contains(stableKey) {
                continue
            }
            // Fallback to legacy key
            if targetLegacyKeys.contains(ArtworkMatchStrategy.legacyKey(for: art)) {
                continue
            }
            art.child = target
        }
    }

    /// Removes duplicate artworks within each child profile.
    ///
    /// Two-pass deduplication:
    /// - Pass 1: Group by `syncIdentifier` (stable, authoritative)
    /// - Pass 2: Group remaining (no syncId) by legacy key (title + date)
    ///
    /// To avoid false positives (e.g. batch imports with different images
    /// but the same title and timestamp), we additionally check that the
    /// image data sizes are similar before treating two artworks as duplicates.
    private func deduplicateArtworks(modelContext: ModelContext) {
        guard let allChildren = try? modelContext.fetch(FetchDescriptor<Child>()) else { return }

        var totalRemoved = 0
        for child in allChildren {
            guard let artworks = child.artworks, artworks.count > 1 else { continue }

            // Pass 1: dedup by syncIdentifier (authoritative)
            var seenBySyncId: [String: Artwork] = [:]
            var remainingArtworks: [Artwork] = []

            for art in artworks {
                if let syncId = art.syncIdentifier, !syncId.isEmpty {
                    if let existing = seenBySyncId[syncId] {
                        let existingScore = ArtworkMatchStrategy.dataScore(for: existing)
                        let thisScore = ArtworkMatchStrategy.dataScore(for: art)
                        if thisScore > existingScore {
                            modelContext.delete(existing)
                            seenBySyncId[syncId] = art
                        } else {
                            modelContext.delete(art)
                        }
                        totalRemoved += 1
                    } else {
                        seenBySyncId[syncId] = art
                    }
                } else {
                    remainingArtworks.append(art)
                }
            }

            // Pass 2: dedup remaining (no syncId) by legacy key
            var seenByLegacy: [String: Artwork] = [:]
            for art in remainingArtworks {
                let key = ArtworkMatchStrategy.legacyKey(for: art)
                if let existing = seenByLegacy[key] {
                    guard ArtworkMatchStrategy.areLikelyDuplicates(existing, art) else {
                        continue
                    }
                    let existingScore = ArtworkMatchStrategy.dataScore(for: existing)
                    let thisScore = ArtworkMatchStrategy.dataScore(for: art)
                    if thisScore > existingScore {
                        modelContext.delete(existing)
                        seenByLegacy[key] = art
                    } else {
                        modelContext.delete(art)
                    }
                    totalRemoved += 1
                } else {
                    seenByLegacy[key] = art
                }
            }
        }
        if totalRemoved > 0 {
            diag("dedup: removed \(totalRemoved) duplicate artwork(s)")
        }
    }

    // MARK: - Orphan Cleanup

    /// Removes SwiftData mirror children whose shared-store records no longer exist.
    ///
    /// This handles two scenarios:
    /// 1. Owner stopped sharing — participant's shared records disappear
    /// 2. Owner deleted the child — shared records are removed from CloudKit
    private func cleanupOrphanedMirrors(
        sharedChildren: [NSManagedObject],
        container: NSPersistentCloudKitContainer,
        modelContext: ModelContext
    ) {
        // Build set of active shared record names
        let activeRecordNames = Set(
            sharedChildren.compactMap { container.recordID(for: $0.objectID)?.recordName }
        )

        // Fetch all SwiftData mirrors (have sharedRecordName)
        let mirrorDescriptor = FetchDescriptor<Child>(
            predicate: #Predicate<Child> { $0.sharedRecordName != nil }
        )
        guard let mirrors = try? modelContext.fetch(mirrorDescriptor) else { return }

        var orphansRemoved = 0
        for mirror in mirrors {
            guard let recordName = mirror.sharedRecordName else { continue }

            // Skip if this mirror is for a child in the private store (owner's child)
            // — owners have children in both stores
            if let _ = try? managedObjectID(for: mirror) {
                continue
            }

            // If the record is no longer in the shared store, it's an orphan
            if !activeRecordNames.contains(recordName) {
                diag("orphan: removing mirror '\(mirror.name)' — shared record gone")
                modelContext.delete(mirror)
                orphansRemoved += 1
            }
        }

        if orphansRemoved > 0 {
            diag("orphan: removed \(orphansRemoved) orphaned mirror(s)")
        }
    }

    // MARK: - Artwork Sync (Shared Store → SwiftData)

    /// Mirrors artworks from a shared Core Data child into a SwiftData child.
    ///
    /// Matching priority:
    /// 1. `syncIdentifier` matches CloudKit record name (stable, survives edits)
    /// 2. Legacy key (title + rounded date) as fallback for pre-V6 artworks
    ///
    /// On match: updates fields + backfills `syncIdentifier` if nil.
    /// No match: inserts with `syncIdentifier = recordName ?? UUID()`.
    ///
    /// Uses a two-pass strategy for fetching:
    /// 1. Access artworks via the Core Data relationship (`child.artworks`)
    /// 2. Fallback: query all artworks in the shared store and match by child
    ///    object ID — catches cases where the relationship isn't populated yet
    ///
    /// - Returns: Tuple of `(inserted, updated)` counts for notification triggering.
    @discardableResult
    private func syncArtworks(
        for managedChild: NSManagedObject,
        into swiftDataChild: Child,
        modelContext: ModelContext
    ) -> (inserted: Int, updated: Int) {
        // --- Pass 1: try the Core Data relationship ---
        var artworkObjects: [NSManagedObject] = []

        if let artworkSet = managedChild.value(forKey: "artworks") as? NSSet {
            artworkObjects = artworkSet.compactMap { $0 as? NSManagedObject }
            diag("syncArtworks: \(artworkObjects.count) artwork(s) via relationship for '\(swiftDataChild.name)'")
        } else {
            let relNames = managedChild.entity.relationshipsByName.keys.sorted()
            diag("syncArtworks: 'artworks' relationship returned nil for '\(swiftDataChild.name)'. Available: \(relNames)")
        }

        // --- Pass 2: fallback direct fetch from shared store ---
        if artworkObjects.isEmpty, let container = persistentContainer, let sharedStore {
            let artworkRequest = NSFetchRequest<NSManagedObject>(entityName: "Artwork")
            artworkRequest.affectedStores = [sharedStore]
            if let allSharedArtworks = try? container.viewContext.fetch(artworkRequest) {
                for artwork in allSharedArtworks {
                    if let artworkChild = artwork.value(forKey: "child") as? NSManagedObject,
                       artworkChild.objectID == managedChild.objectID {
                        artworkObjects.append(artwork)
                    }
                }
                diag("syncArtworks: \(artworkObjects.count) artwork(s) via direct fetch for '\(swiftDataChild.name)' (total shared: \(allSharedArtworks.count))")
            }
        }

        guard !artworkObjects.isEmpty else {
            diag("syncArtworks: no artworks found for '\(swiftDataChild.name)'")
            return (0, 0)
        }

        // Build TWO lookup dictionaries from SwiftData artworks
        var existingBySyncId: [String: Artwork] = [:]
        var existingByLegacyKey: [String: Artwork] = [:]
        for art in (swiftDataChild.artworks ?? []) {
            if let syncId = art.syncIdentifier, !syncId.isEmpty {
                existingBySyncId[syncId] = art
            }
            existingByLegacyKey[ArtworkMatchStrategy.legacyKey(for: art)] = art
        }

        var insertCount = 0
        var updateCount = 0

        for managedArtwork in artworkObjects {
            let title = managedArtwork.value(forKey: "title") as? String ?? ""
            let createdAt = managedArtwork.value(forKey: "createdAt") as? Date ?? .now
            let caption = managedArtwork.value(forKey: "caption") as? String ?? ""
            let isFavorited = managedArtwork.value(forKey: "isFavorited") as? Bool ?? false
            let remoteSyncId = managedArtwork.value(forKey: "syncIdentifier") as? String

            // Get CloudKit record name for this artwork
            let recordName = persistentContainer?.recordID(for: managedArtwork.objectID)?.recordName

            // --- Match by syncIdentifier first (stable, survives title/date edits) ---
            var matched: Artwork?

            // Try matching by remote syncIdentifier
            if let remoteSyncId, !remoteSyncId.isEmpty,
               let found = existingBySyncId[remoteSyncId] {
                matched = found
            }
            // Try matching by CloudKit record name
            if matched == nil, let recordName,
               let found = existingBySyncId[recordName] {
                matched = found
            }
            // Fallback: legacy key matching
            if matched == nil {
                let legacyKey = ArtworkMatchStrategy.legacyKey(title: title, createdAt: createdAt)
                matched = existingByLegacyKey[legacyKey]
            }

            if let existing = matched {
                // Update existing artwork — the shared (owner's) version is canonical
                var changed = false
                if existing.title != title {
                    existing.title = title
                    changed = true
                }
                if existing.caption != caption {
                    existing.caption = caption
                    changed = true
                }
                if existing.isFavorited != isFavorited {
                    existing.isFavorited = isFavorited
                    changed = true
                }
                if existing.createdAt != createdAt {
                    existing.createdAt = createdAt
                    changed = true
                }
                // Only fill in binary data if the local copy is missing it.
                if existing.imageData == nil,
                   let remoteImage = managedArtwork.value(forKey: "imageData") as? Data {
                    existing.imageData = remoteImage
                    changed = true
                }
                if existing.voiceNoteData == nil,
                   let remoteVoice = managedArtwork.value(forKey: "voiceNoteData") as? Data {
                    existing.voiceNoteData = remoteVoice
                    changed = true
                }
                // Backfill syncIdentifier if missing
                if existing.syncIdentifier == nil || existing.syncIdentifier?.isEmpty == true {
                    existing.syncIdentifier = remoteSyncId ?? recordName ?? UUID().uuidString
                    changed = true
                }
                if changed { updateCount += 1 }
            } else {
                // Create new artwork with stable syncIdentifier
                let syncId = remoteSyncId ?? recordName ?? UUID().uuidString
                let artwork = Artwork(
                    title: title,
                    caption: caption,
                    imageData: managedArtwork.value(forKey: "imageData") as? Data,
                    voiceNoteData: managedArtwork.value(forKey: "voiceNoteData") as? Data,
                    isFavorited: isFavorited,
                    createdAt: createdAt,
                    child: swiftDataChild,
                    syncIdentifier: syncId
                )
                modelContext.insert(artwork)
                insertCount += 1
            }
        }

        if insertCount > 0 || updateCount > 0 {
            diag("syncArtworks: \(insertCount) inserted, \(updateCount) updated for '\(swiftDataChild.name)'")
        }
        return (insertCount, updateCount)
    }

    // MARK: - Owner Detection & Access Control

    /// Returns whether the current user is the owner of the given child.
    ///
    /// - Unshared child → always `true` (local data, user is the owner)
    /// - Shared child → checks `CKShare.currentUserParticipant?.role == .owner`
    /// - Fallback: if the child exists in the private store (no sharedRecordName),
    ///   the current user is the owner
    func isOwner(of child: Child) -> Bool {
        // Unshared child — user is always the owner
        guard isShared(child) || child.sharedRecordName != nil else {
            return true
        }

        // Check CKShare participant role
        if let share = existingShare(for: child),
           let currentUser = share.currentUserParticipant {
            return currentUser.role == .owner
        }

        // Fallback: children received via sharing have a sharedRecordName
        // but no objectIDURL in the private store. Owners created the child
        // locally, so they have a valid objectIDURL.
        if child.sharedRecordName != nil {
            // If we can resolve the child's objectID in Core Data, it's in
            // the private store — the user is the owner.
            if let _ = try? managedObjectID(for: child) {
                return true
            }
            return false
        }

        return true
    }

    /// Leaves a shared child profile as a participant.
    ///
    /// Deletes the shared record zone from the participant's shared database
    /// and removes the SwiftData mirror.
    func leaveShare(_ child: Child, modelContext: ModelContext) async throws {
        guard let container = persistentContainer, let sharedStore else {
            throw SharingError.notInitialised
        }

        // Find the shared zone for this child
        guard let recordName = child.sharedRecordName else {
            throw SharingError.objectIDNotFound
        }

        // Find the child in the shared store by matching record name
        let childReq = NSFetchRequest<NSManagedObject>(entityName: "Child")
        childReq.affectedStores = [sharedStore]
        let sharedChildren = (try? container.viewContext.fetch(childReq)) ?? []

        for managedChild in sharedChildren {
            let managedRecordName = container.recordID(for: managedChild.objectID)?.recordName
            if managedRecordName == recordName {
                // Get the share for this record
                if let shares = try? container.fetchShares(matching: [managedChild.objectID]),
                   let share = shares[managedChild.objectID] {
                    // Delete the share zone from our shared database
                    let ckContainer = CKContainer(identifier: ckContainerIdentifier)
                    let sharedDB = ckContainer.sharedCloudDatabase
                    try await sharedDB.deleteRecordZone(withID: share.recordID.zoneID)
                    diag("leaveShare: deleted shared zone for '\(child.name)'")
                }
                break
            }
        }

        // Clean up SwiftData mirror (cascade deletes artworks)
        modelContext.delete(child)
        try modelContext.save()
        diag("leaveShare: removed SwiftData mirror for '\(child.name)'")
    }

    /// Deletes a shared child as the owner — revokes all participants' access
    /// and removes the data from CloudKit and SwiftData.
    func deleteSharedChild(_ child: Child, modelContext: ModelContext) async throws {
        guard let container = persistentContainer else {
            throw SharingError.notInitialised
        }

        // Stop sharing first (revokes access for all participants)
        if isShared(child) {
            try await stopSharing(child)
        }

        // Delete from Core Data (triggers CloudKit record deletion)
        if let objectID = try? managedObjectID(for: child) {
            let managedObject = container.viewContext.object(with: objectID)

            // Delete related artworks from Core Data first
            if let artworkSet = managedObject.value(forKey: "artworks") as? NSSet {
                for case let artwork as NSManagedObject in artworkSet {
                    container.viewContext.delete(artwork)
                }
            }

            container.viewContext.delete(managedObject)
            if container.viewContext.hasChanges {
                try container.viewContext.save()
            }
            diag("deleteSharedChild: deleted from Core Data for '\(child.name)'")
        }

        // Delete from SwiftData (cascade deletes artworks)
        modelContext.delete(child)
        try modelContext.save()
        diag("deleteSharedChild: deleted from SwiftData for '\(child.name)'")
    }

    // MARK: - Backfill

    /// Populates `syncIdentifier` for existing artworks that were created
    /// before V6. Tries to get the CloudKit record name from Core Data;
    /// falls back to a UUID so future syncs have a stable key.
    ///
    /// Called once after `setup()` completes.
    func backfillSyncIdentifiers() {
        guard let modelContainer else {
            diag("backfill: SKIP — no model container")
            return
        }

        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Artwork>(
            predicate: #Predicate<Artwork> { $0.syncIdentifier == nil }
        )
        guard let artworks = try? context.fetch(descriptor), !artworks.isEmpty else {
            diag("backfill: no artworks need syncIdentifier")
            return
        }

        var backfilled = 0
        for artwork in artworks {
            // Try to get the CloudKit record name via Core Data
            if let container = persistentContainer,
               let url = artwork.objectIDURL {
                let coordinator = container.persistentStoreCoordinator
                // Validate store UUID before calling managedObjectID
                if let storeUUID = url.host, !storeUUID.isEmpty,
                   coordinator.persistentStores.contains(where: { $0.identifier == storeUUID }),
                   let objectID = coordinator.managedObjectID(forURIRepresentation: url),
                   let recordID = container.recordID(for: objectID) {
                    artwork.syncIdentifier = recordID.recordName
                    backfilled += 1
                    continue
                }
            }
            // Fallback: assign a UUID
            artwork.syncIdentifier = UUID().uuidString
            backfilled += 1
        }

        if backfilled > 0 {
            try? context.save()
            diag("backfill: assigned syncIdentifier to \(backfilled) artwork(s)")
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
        case syncFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .notInitialised:
                return "CloudKit sharing service is not initialised."
            case .objectIDNotFound:
                return "Could not find the managed object for this child."
            case .syncFailed(let underlying):
                return "Sync failed: \(underlying.localizedDescription)"
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
