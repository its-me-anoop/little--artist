//
//  LittleArtistIntents.swift
//  Little Artist
//
//  Siri App Intents and shortcut phrases. Capture, milestones, and
//  gallery stats are all reachable by voice or the Shortcuts app.
//

import AppIntents
import SwiftData

// MARK: - Capture Artwork

/// Opens the app straight into the capture flow.
struct CaptureArtworkIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture Artwork"
    static let description = IntentDescription("Open Artling ready to save a new masterpiece.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.pendingAction = .captureArtwork
        return .result()
    }
}

// MARK: - View Milestones

/// Opens the app on the Milestones tab.
struct ViewMilestonesIntent: AppIntent {
    static let title: LocalizedStringResource = "View Milestones"
    static let description = IntentDescription("See the achievements your little artists have unlocked.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.pendingAction = .showMilestones
        return .result()
    }
}

// MARK: - Gallery Stats

/// Answers "how many artworks have I saved" without opening the app.
struct GalleryStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Gallery Stats"
    static let description = IntentDescription("Hear how many masterpieces you've saved.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = FirestoreRepository.shared.modelContainer else {
            return .result(dialog: "Open Artling first to set up your gallery.")
        }

        let context = ModelContext(container)
        let artworkCount = (try? context.fetchCount(FetchDescriptor<Artwork>())) ?? 0
        let childCount = (try? context.fetchCount(FetchDescriptor<Child>())) ?? 0

        let dialog: IntentDialog
        if artworkCount == 0 {
            dialog = "Your gallery is ready and waiting for its first masterpiece."
        } else if childCount <= 1 {
            dialog = "You've saved \(artworkCount) \(artworkCount == 1 ? "masterpiece" : "masterpieces") for your little artist."
        } else {
            dialog = "You've saved \(artworkCount) masterpieces across \(childCount) little artists."
        }
        return .result(dialog: dialog)
    }
}

// MARK: - Shortcuts Provider

/// Registers Siri phrases so intents work by voice without setup.
struct LittleArtistShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureArtworkIntent(),
            phrases: [
                "Capture artwork in \(.applicationName)",
                "Save artwork in \(.applicationName)",
                "Add art to \(.applicationName)",
                "Save a masterpiece in \(.applicationName)"
            ],
            shortTitle: "Capture Artwork",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: GalleryStatsIntent(),
            phrases: [
                "How many artworks are in \(.applicationName)",
                "Gallery stats in \(.applicationName)"
            ],
            shortTitle: "Gallery Stats",
            systemImageName: "photo.on.rectangle.angled"
        )
        AppShortcut(
            intent: ViewMilestonesIntent(),
            phrases: [
                "Show milestones in \(.applicationName)",
                "Show achievements in \(.applicationName)"
            ],
            shortTitle: "View Milestones",
            systemImageName: "medal.fill"
        )
    }
}
