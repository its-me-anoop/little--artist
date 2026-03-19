//
//  Little_ArtistApp.swift
//  Little Artist
//
//  Application entry point. Configures the SwiftData model container
//  and routes between the onboarding flow and the main interface.
//
//  Created by Anoop Jose on 13/02/2026.
//

import FirebaseCore
import SwiftData
import SwiftUI

/// The main application entry point for Artling.
///
/// Sets up the shared `ModelContainer` for `Child` and `Artwork` persistence
/// and conditionally presents either the ``OnboardingView`` or the
/// ``ContentView`` based on whether the user has completed onboarding.
@main
struct Little_ArtistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var splashFinished = false

    /// Reference to StoreKit manager so transaction listener starts early.
    private let storeKit = StoreKitManager.shared

    var sharedModelContainer: ModelContainer = {
        // Ensure the Application Support directory exists before SwiftData tries to write.
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        #if DEBUG
        // Enable premium + sync for testing via launch argument: -debugPremium
        if ProcessInfo.processInfo.arguments.contains("-debugPremium") {
            UserDefaults.standard.set(true, forKey: "isPremium")
            UserDefaults.standard.set(true, forKey: "firebaseSyncEnabled")
        }
        #endif

        let schema = Schema(versionedSchema: SchemaV8.self)

        // SwiftData uses local-only storage. Firebase handles cloud sync
        // through FirestoreSyncService.
        let storeURL = appSupport.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        // Configure Firebase before creating the container
        FirebaseApp.configure()
        FirebaseAuthService.shared.setup()

        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: AppSchemaMigrationPlan.self,
                configurations: [modelConfiguration]
            )

            // Provide model container to sync services
            FirestoreSyncService.shared.modelContainer = container
            FirestoreRepository.shared.modelContainer = container

            // Always-on Firebase sync (starts once auth user is available).
            // Upload first to assign firestoreIds + populate localWriteIds,
            // THEN start the listener so echo writes are properly suppressed.
            Task { @MainActor in
                while FirebaseAuthService.shared.userId == nil {
                    try? await Task.sleep(for: .milliseconds(200))
                }
                await FirestoreRepository.shared.activateCloudSyncIfNeeded()
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
