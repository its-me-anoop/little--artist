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

import os
import SwiftData
import SwiftUI

/// The main application entry point for Artling.
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

    /// Reference to StoreKit manager so transaction listener starts early.
    private let storeKit = StoreKitManager.shared

    /// The CloudKit container that mirrors the user's private data.
    private static let cloudKitContainerID = "iCloud.uk.co.flutterly.Little-Artist"

    var sharedModelContainer: ModelContainer = {
        // Ensure the Application Support directory exists before SwiftData tries to write.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        #if DEBUG
        // Enable premium for testing via launch argument: -debugPremium
        if ProcessInfo.processInfo.arguments.contains("-debugPremium") {
            UserDefaults.standard.set(true, forKey: "isPremium")
        }
        #endif

        // User content syncs to the private iCloud database; achievements
        // are local-only derived state (syncing them would duplicate the
        // seeded rows on every device).
        let cloudSchema = Schema([Child.self, Artwork.self, Tag.self, Comment.self])
        let localSchema = Schema([Achievement.self])
        let fullSchema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])

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
            // If migration fails, delete the old stores and create fresh.
            for url in [storeURL, localStoreURL] {
                try? FileManager.default.removeItem(at: url)
                let storeDir = url.deletingLastPathComponent()
                for suffix in ["-shm", "-wal"] {
                    let related = storeDir.appendingPathComponent(url.lastPathComponent + suffix)
                    try? FileManager.default.removeItem(at: related)
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
                let inMemoryConfig = ModelConfiguration(schema: fullSchema, isStoredInMemoryOnly: true)
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
            .onChange(of: appAppearance) { _, newValue in
                let appearance = AppAppearance(rawValue: newValue) ?? .system
                applyAppearance(appearance)
            }
            #if DEBUG
            .onAppear {
                // Activate debug premium override via launch argument:
                //   -debugPremium YES
                if ProcessInfo.processInfo.arguments.contains("-debugPremium") {
                    PremiumManager._overrideIsPremium = true
                    UserDefaults.standard.set(true, forKey: "isPremium")
                }
            }
            #endif
        }
        .modelContainer(sharedModelContainer)
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
