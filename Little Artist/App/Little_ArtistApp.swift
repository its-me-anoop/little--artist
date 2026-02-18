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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Child.self,
            Artwork.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
