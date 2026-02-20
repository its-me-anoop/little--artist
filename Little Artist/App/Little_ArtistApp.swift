//
//  Little_ArtistApp.swift
//  Little Artist
//
//  Application entry point. Configures the SwiftData model container
//  and routes between the onboarding flow and the main interface.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// The main application entry point for Little Artist.
///
/// Sets up the shared `ModelContainer` for `Child` and `Artwork` persistence
/// and conditionally presents either the ``OnboardingView`` or the
/// ``ContentView`` based on whether the user has completed onboarding.
@main
struct Little_ArtistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false

    /// Reference to StoreKit manager so transaction listener starts early.
    private let storeKit = StoreKitManager.shared

    var sharedModelContainer: ModelContainer = {
        // Ensure the Application Support directory exists before SwiftData tries to write.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        let schema = Schema(versionedSchema: SchemaV4.self)
        let isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")

        // Use explicit store URL so Core Data's NSPersistentCloudKitContainer
        // can point at the same SQLite file for CloudKit sharing.
        let storeURL = appSupport.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: (isPremium && iCloudEnabled) ? .automatic : .none
        )

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: LittleArtistMigrationPlan.self,
                configurations: [modelConfiguration]
            )

            // Initialise CloudKit sharing stack when premium + iCloud enabled
            if isPremium && iCloudEnabled {
                CloudKitSharingService.shared.setup()
            }

            return container
        } catch {
            // If migration fails, delete the old store and create fresh.
            try? FileManager.default.removeItem(at: storeURL)
            let storeDir = storeURL.deletingLastPathComponent()
            for suffix in ["-shm", "-wal"] {
                let related = storeDir.appendingPathComponent(storeURL.lastPathComponent + suffix)
                try? FileManager.default.removeItem(at: related)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
