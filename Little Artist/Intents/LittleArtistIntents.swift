//
//  LittleArtistIntents.swift
//  Little Artist
//
//  Actions Siri, Shortcuts, Spotlight and the Action button can perform.
//  Intents that navigate hand off to `QuickActionRouter`; intents that
//  answer questions read the library through `LibraryStore`.
//

import AppIntents
import Foundation
import SwiftUI

// MARK: - Open Artwork

/// Opens one piece of artwork. Also used when a Spotlight result is tapped.
struct OpenArtworkIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Artwork"
    static let description = IntentDescription("Shows a piece of artwork in Little Artist.")

    @Parameter(title: "Artwork", description: "The piece of artwork to open.")
    var target: ArtworkEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.pendingAction = .openArtwork(target.id)
        return .result()
    }
}

// MARK: - Open Child Gallery

/// Opens the gallery filtered to one child.
struct OpenChildGalleryIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Child's Gallery"
    static let description = IntentDescription("Shows all artwork by one child.")

    @Parameter(title: "Child", description: "The child whose gallery to open.")
    var target: ChildEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.pendingAction = .openChild(target.id)
        return .result()
    }
}

// MARK: - Capture Artwork

/// Opens the app straight into the capture flow, optionally for one child.
struct CaptureArtworkIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture Artwork"
    static let description = IntentDescription("Open Little Artist ready to save a new masterpiece.", searchKeywords: ["drawing", "painting", "photo", "scan", "save", "craft"])
    static let openAppWhenRun = true

    @Parameter(title: "Child", description: "The child who made the artwork. Leave empty to choose in the app.")
    var child: ChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Capture artwork for \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuickActionRouter.shared.pendingAction = .captureArtwork(childID: child?.id)
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

// MARK: - Latest Artwork

/// Shows the most recent artwork in a Siri snippet, without opening the app.
struct ShowLatestArtworkIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Latest Artwork"
    static let description = IntentDescription("Shows the most recent artwork, optionally for one child.", searchKeywords: ["latest", "newest", "recent", "drawing"])

    @Parameter(title: "Child", description: "Only look at artwork by this child. Leave empty for everyone.")
    var child: ChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show the latest artwork by \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ArtworkEntity?> & ProvidesDialog & ShowsSnippetView {
        guard let artwork = LibraryQuery.latestArtwork(in: try LibraryStore.artworks(), childID: child?.id) else {
            let dialog: IntentDialog = child.map { "\($0.name) hasn't saved any artwork yet." }
                ?? "There's no artwork saved yet."
            return .result(value: nil, dialog: dialog, view: AnyView(EmptyView()))
        }
        let entity = ArtworkEntity(artwork: artwork)
        return .result(
            value: entity,
            dialog: "Here's \(entity.title) by \(entity.childName).",
            view: AnyView(ArtworkSnippetView(
                artwork: entity,
                footnote: artwork.createdAt.formatted(date: .abbreviated, time: .omitted)
            ))
        )
    }
}

// MARK: - On This Day

/// Surfaces artwork made on today's date in earlier years.
struct OnThisDayIntent: AppIntent {
    static let title: LocalizedStringResource = "On This Day"
    static let description = IntentDescription("Shows artwork made on this day in earlier years.", searchKeywords: ["memories", "anniversary", "years ago"])

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let memory = LibraryQuery.onThisDay(in: try LibraryStore.artworks()).first else {
            return .result(dialog: "No artwork was made on this day in earlier years.", view: AnyView(EmptyView()))
        }
        let entity = ArtworkEntity(artwork: memory.artwork)
        let when = memory.yearsAgo == 1
            ? String(localized: "1 year ago")
            : String(localized: "\(memory.yearsAgo) years ago")
        return .result(
            dialog: "\(when) today, \(entity.childName) made \(entity.title).",
            view: AnyView(ArtworkSnippetView(artwork: entity, footnote: when))
        )
    }
}

// MARK: - Count Artwork

/// Answers "how many drawings has Mia made" without opening the app.
struct CountArtworkIntent: AppIntent {
    static let title: LocalizedStringResource = "Count Artwork"
    static let description = IntentDescription("Hear how many masterpieces you've saved.", searchKeywords: ["how many", "total", "drawings", "count"])

    @Parameter(title: "Child", description: "Only count artwork by this child. Leave empty for everyone.")
    var child: ChildEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Count artwork by \(\.$child)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let artworks = try LibraryStore.artworks()
        if let child {
            let count = artworks.filter { $0.child?.uuid == child.id }.count
            return .result(value: count, dialog: "\(child.name) has saved \(count) pieces of artwork.")
        }
        let count = artworks.count
        let dialog: IntentDialog = count == 0
            ? "Your gallery is ready and waiting for its first masterpiece."
            : "You've saved \(count) pieces of artwork."
        return .result(value: count, dialog: dialog)
    }
}

// MARK: - Favorite

/// Adds or removes a piece from Favorites.
struct FavoriteArtworkIntent: AppIntent {
    static let title: LocalizedStringResource = "Favorite Artwork"
    static let description = IntentDescription("Adds a piece of artwork to Favorites, or removes it.")

    @Parameter(title: "Artwork", description: "The piece of artwork to add to or remove from Favorites.")
    var artwork: ArtworkEntity

    @Parameter(title: "Favorite", description: "On to add to Favorites, off to remove.", default: true)
    var isFavorite: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Set favorite for \(\.$artwork) to \(\.$isFavorite)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let model = try LibraryStore.artwork(id: artwork.id) else {
            throw $artwork.needsValueError("Which artwork?")
        }
        ArtworkRepository.shared.updateArtwork(model, isFavorited: isFavorite, in: try LibraryStore.context)
        return .result(dialog: isFavorite
            ? "Added \(artwork.title) to Favorites."
            : "Removed \(artwork.title) from Favorites.")
    }
}

// MARK: - Snippet

/// Compact card Siri shows when it answers with a piece of artwork.
struct ArtworkSnippetView: View {
    let artwork: ArtworkEntity
    let footnote: String

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let data = artwork.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Brand.primaryTint
                        .overlay(Image(systemName: "paintpalette.fill").foregroundStyle(Brand.primary))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusImage, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.title)
                    .font(Brand.headlineFont)
                if !artwork.childName.isEmpty {
                    Text("by \(artwork.childName)")
                        .font(Brand.subheadlineFont)
                        .foregroundStyle(Brand.warmGray)
                }
                Text(footnote)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

// MARK: - Shortcuts Provider

/// Registers Siri phrases so intents work by voice without setup.
struct LittleArtistShortcuts: AppShortcutsProvider {

    static var shortcutTileColor: ShortcutTileColor { .orange }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureArtworkIntent(),
            phrases: [
                "Capture artwork in \(.applicationName)",
                "Save artwork in \(.applicationName)",
                "Save a masterpiece in \(.applicationName)",
                "Save \(\.$child)'s artwork in \(.applicationName)",
                "Add \(\.$child)'s drawing to \(.applicationName)"
            ],
            shortTitle: "Capture Artwork",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: ShowLatestArtworkIntent(),
            phrases: [
                "Show the latest artwork in \(.applicationName)",
                "Show \(\.$child)'s latest artwork in \(.applicationName)",
                "What did \(\.$child) draw last in \(.applicationName)"
            ],
            shortTitle: "Latest Artwork",
            systemImageName: "photo.on.rectangle"
        )
        AppShortcut(
            intent: OnThisDayIntent(),
            phrases: [
                "Show On This Day in \(.applicationName)",
                "What did my kids make on this day in \(.applicationName)"
            ],
            shortTitle: "On This Day",
            systemImageName: "clock.arrow.circlepath"
        )
        AppShortcut(
            intent: CountArtworkIntent(),
            phrases: [
                "How many artworks are in \(.applicationName)",
                "How much artwork has \(\.$child) made in \(.applicationName)"
            ],
            shortTitle: "Count Artwork",
            systemImageName: "number"
        )
        AppShortcut(
            intent: OpenChildGalleryIntent(),
            phrases: [
                "Open \(\.$target)'s gallery in \(.applicationName)",
                "Show \(\.$target)'s art in \(.applicationName)"
            ],
            shortTitle: "Child's Gallery",
            systemImageName: "figure.child"
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
