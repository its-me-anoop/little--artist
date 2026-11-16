//
//  Little_ArtistApp.swift
//  Little Artist
//
//  Application entry point. Configures the CloudKit-backed SwiftData
//  model container and routes between the onboarding flow and the
//  main interface.
//
//  Created by Anoop Jose on 13/02/2026.
//

import AppIntents
import os
import SwiftData
import SwiftUI

/// The main application entry point for Little Artist.
///
/// Sets up the shared `ModelContainer` — user content (children,
/// artworks, tags, comments) syncs to the user's private iCloud database
/// via CloudKit; achievements stay local-only (derived state that each
/// device re-earns from artwork). Conditionally presents either the
/// ``OnboardingView`` or the ``ContentView`` based on whether the user
/// has completed onboarding.
@main
struct Little_ArtistApp: App {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var splashFinished = false

    init() {
        // Evaluate the trial / lifetime state and listen for transaction
        // updates (refunds, Ask to Buy approvals, other devices) right away.
        StoreKitManager.shared.start()
    }

    /// The CloudKit container that mirrors the user's private data.
    private static let cloudKitContainerID = "iCloud.uk.co.flutterly.Little-Artist"

    var sharedModelContainer: ModelContainer = {
        // Ensure the Application Support directory exists before SwiftData tries to write.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        // User content syncs to the private iCloud database; achievements
        // are local-only derived state (syncing them would duplicate the
        // seeded rows on every device).
        let cloudSchema = Schema([Child.self, Artwork.self, Tag.self, Comment.self])
        let localSchema = Schema([Achievement.self])
        let fullSchema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])

        #if DEBUG
        // UI test mode: deterministic in-memory store, onboarding pre-completed
        // unless the test asks for it via -uiTestShowOnboarding.
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            UserDefaults.standard.set(
                !ProcessInfo.processInfo.arguments.contains("-uiTestShowOnboarding"),
                forKey: "hasCompletedOnboarding"
            )
            // No CloudKit in UI tests: the default (.automatic) would try to
            // mirror this throwaway store to iCloud and can make saves flaky.
            let inMemoryConfig = ModelConfiguration(
                schema: fullSchema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            if let container = try? ModelContainer(for: fullSchema, configurations: [inMemoryConfig]) {
                ArtworkRepository.shared.modelContainer = container
                let context = ModelContext(container)
                AchievementService.seedAchievements(context: context)
                // Screenshot mode: fill the gallery with sample artwork.
                if ProcessInfo.processInfo.arguments.contains("-uiTestSeedSampleArtwork") {
                    ScreenshotSampleData.seed(into: context)
                    AchievementService.checkMilestones(context: context)
                }
                return container
            }
        }
        #endif

        let storeURL = appSupport.appendingPathComponent("default.store")
        let localStoreURL = appSupport.appendingPathComponent("local.store")

        let cloudConfiguration = ModelConfiguration(
            "cloud",
            schema: cloudSchema,
            url: storeURL,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        let localConfiguration = ModelConfiguration(
            "local",
            schema: localSchema,
            url: localStoreURL,
            cloudKitDatabase: .none
        )

        func makeContainer() throws -> ModelContainer {
            try ModelContainer(
                for: fullSchema,
                configurations: [cloudConfiguration, localConfiguration]
            )
        }

        do {
            let container = try makeContainer()
            ArtworkRepository.shared.modelContainer = container

            // Seed default achievements on first launch, then evaluate existing
            // artworks so any already-qualifying achievements unlock immediately.
            let startupContext = ModelContext(container)
            AchievementService.seedAchievements(context: startupContext)
            AchievementService.checkMilestones(context: startupContext)

            return container
        } catch {
            // If the stores can't be opened, move them aside (never delete a
            // family's artwork) and start fresh. iCloud re-downloads synced
            // data; the quarantined files allow manual recovery.
            let stamp = Int(Date.now.timeIntervalSince1970)
            for url in [storeURL, localStoreURL] {
                for suffix in ["", "-shm", "-wal"] {
                    let source = URL(fileURLWithPath: url.path + suffix)
                    guard FileManager.default.fileExists(atPath: source.path) else { continue }
                    let destination = URL(fileURLWithPath: url.path + ".recovered-\(stamp)" + suffix)
                    try? FileManager.default.moveItem(at: source, to: destination)
                }
            }
            do {
                let container = try makeContainer()
                ArtworkRepository.shared.modelContainer = container
                let startupContext = ModelContext(container)
                AchievementService.seedAchievements(context: startupContext)
                return container
            } catch {
                let logger = Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Migration")
                logger.error("Could not create ModelContainer after store reset, using in-memory fallback: \(error)")
                // An in-memory store keeps the app functional; data won't persist this session.
                let inMemoryConfig = ModelConfiguration(schema: fullSchema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                if let fallback = try? ModelContainer(for: fullSchema, configurations: [inMemoryConfig]) {
                    ArtworkRepository.shared.modelContainer = fallback
                    return fallback
                }
                logger.critical("Failed to create even an in-memory ModelContainer.")
                preconditionFailure("Could not create any ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            let selectedAppearance = AppAppearance(rawValue: appAppearance) ?? .system

            Group {
                if !splashFinished {
                    SplashVideoView(isFinished: $splashFinished)
                } else if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .background(BrandAppBackground())
            .onAppear {
                applyAppearance(selectedAppearance)
            }
            .task {
                await prepareSystemIntegrations()
            }
            .onChange(of: appAppearance) { _, newValue in
                let appearance = AppAppearance(rawValue: newValue) ?? .system
                applyAppearance(appearance)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// Gives every record a unique identifier, then exposes the library to
    /// Spotlight, Siri and Shortcuts. Re-indexes each launch so changes that
    /// arrived from other devices through iCloud become searchable too.
    @MainActor
    private func prepareSystemIntegrations() async {
        let context = sharedModelContainer.mainContext
        do {
            try IdentifierBackfill.run(in: context)
        } catch {
            Logger(subsystem: "uk.co.flutterly.Little-Artist", category: "Migration")
                .error("Identifier backfill failed: \(error.localizedDescription, privacy: .public)")
        }
        ArtworkRepository.shared.indexer = SpotlightIndexService.shared
        SpotlightIndexService.shared.reindexAll(in: context)
        LittleArtistShortcuts.updateAppShortcutParameters()
    }

    @MainActor
    private func applyAppearance(_ appearance: AppAppearance) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .forEach { scene in
                scene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = appearance.interfaceStyle
                }
            }
    }
}
