//
//  PreviewSampleData.swift
//  Little Artist
//
//  Mock data used exclusively by SwiftUI previews. These helpers create
//  realistic sample `Child` and `Artwork` instances for visual testing.
//

import Foundation
import SwiftData

/// Provides sample `Child` and `Artwork` instances for SwiftUI previews.
///
/// Usage:
/// ```swift
/// #Preview {
///     MyView()
///         .modelContainer(PreviewSampleData.container)
/// }
/// ```
enum PreviewSampleData {

    // MARK: - Model Container

    /// An in-memory `ModelContainer` pre-loaded with sample children and artworks.
    @MainActor
    static var container: ModelContainer {
        let schema = Schema([Child.self, Artwork.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        populateContainer(container)
        return container
    }

    // MARK: - Sample Children

    /// A sample child named "Emma" with a red avatar.
    static let emma = Child(
        name: "Emma",
        avatarColor: "FF6B6B",
        createdAt: date(year: 2025, month: 6, day: 1)
    )

    /// A sample child named "Noah" with a blue avatar.
    static let noah = Child(
        name: "Noah",
        avatarColor: "4D96FF",
        createdAt: date(year: 2025, month: 8, day: 15)
    )

    /// A sample child named "Lily" with a purple avatar.
    static let lily = Child(
        name: "Lily",
        avatarColor: "9B59B6",
        createdAt: date(year: 2026, month: 1, day: 10)
    )

    /// All sample children.
    static var sampleChildren: [Child] {
        [emma, noah, lily]
    }

    // MARK: - Sample Artworks

    /// A collection of sample artworks spanning multiple months and years.
    static var sampleArtworks: [Artwork] {
        [
            // February 2026
            Artwork(
                title: "Rainbow House",
                caption: "My dream house with a rainbow on top",
                createdAt: date(year: 2026, month: 2, day: 14)
            ),
            Artwork(
                title: "Snowy Mountain",
                caption: "Winter wonderland",
                createdAt: date(year: 2026, month: 2, day: 10)
            ),
            Artwork(
                title: "Valentine Card",
                caption: "For mom and dad",
                createdAt: date(year: 2026, month: 2, day: 5)
            ),

            // January 2026
            Artwork(
                title: "New Year Fireworks",
                caption: "Happy new year!",
                createdAt: date(year: 2026, month: 1, day: 1)
            ),
            Artwork(
                title: "Snowman",
                caption: "Frosty the snowman with a carrot nose",
                createdAt: date(year: 2026, month: 1, day: 15)
            ),

            // December 2025
            Artwork(
                title: "Christmas Tree",
                caption: "With ornaments and a golden star",
                createdAt: date(year: 2025, month: 12, day: 25)
            ),
            Artwork(
                title: "Gingerbread House",
                caption: "Yummy!",
                createdAt: date(year: 2025, month: 12, day: 20)
            ),

            // October 2025
            Artwork(
                title: "Pumpkin Patch",
                caption: "So many pumpkins",
                createdAt: date(year: 2025, month: 10, day: 28)
            ),
            Artwork(
                title: "Spooky Ghost",
                caption: "Boo!",
                createdAt: date(year: 2025, month: 10, day: 31)
            ),

            // June 2025
            Artwork(
                title: "Beach Day",
                caption: "Sun, sand, and waves",
                createdAt: date(year: 2025, month: 6, day: 15)
            ),
            Artwork(
                title: "Butterfly Garden",
                caption: "Colorful butterflies everywhere",
                createdAt: date(year: 2025, month: 6, day: 8)
            ),
        ]
    }

    /// A single sample artwork for simple previews.
    static var singleArtwork: Artwork {
        Artwork(
            title: "Rainbow House",
            caption: "My dream house with a rainbow on top",
            createdAt: date(year: 2026, month: 2, day: 14)
        )
    }

    // MARK: - Helpers

    /// Creates a `Date` from year, month, and day components.
    private static func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    /// Populates a container with sample children and artworks.
    @MainActor
    private static func populateContainer(_ container: ModelContainer) {
        let context = container.mainContext

        let emma = Child(name: "Emma", avatarColor: "FF6B6B", createdAt: date(year: 2025, month: 6, day: 1))
        let noah = Child(name: "Noah", avatarColor: "4D96FF", createdAt: date(year: 2025, month: 8, day: 15))
        context.insert(emma)
        context.insert(noah)

        for artwork in sampleArtworks.prefix(6) {
            artwork.child = emma
            context.insert(artwork)
        }

        for artwork in sampleArtworks.suffix(5) {
            artwork.child = noah
            context.insert(artwork)
        }
    }
}
