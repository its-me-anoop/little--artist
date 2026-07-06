//
//  AchievementService.swift
//  Little Artist
//
//  Tracks creative milestones and seeds default achievements.
//

import Foundation
import SwiftData

/// Tracks creative milestones and seeds default achievements.
enum AchievementService {

    static let mediumTags = [
        "Craft", "Painting", "Drawing", "Watercolor",
        "Collage", "Sculpture", "Digital", "Mixed Media"
    ]

    private static let defaults: [(id: String, title: String, subtitle: String, icon: String, category: String)] = [
        ("first_masterpiece", "First Masterpiece", "The journey begins!", "star.fill", "artwork"),
        ("fridge_door", "Fridge Door Full", "10 masterpieces saved.", "square.grid.3x3.fill", "artwork"),
        ("little_curator", "Little Curator", "25 masterpieces saved.", "crown.fill", "artwork"),
        ("prolific", "Prolific", "A growing stack of art.", "square.stack.3d.up.fill", "artwork"),
        ("gallery_owner", "Gallery Owner", "100 masterpieces saved.", "person.crop.rectangle.stack.fill", "artwork"),
        ("creative_week", "Creative Streak", "Three artworks in one week.", "flame.fill", "engagement"),
        ("memory_lane", "Memory Lane", "Relived your first memory.", "text.book.closed.fill", "engagement"),
        ("art_family", "Art Family", "A second little artist joins.", "figure.2.and.child.holdinghands", "engagement"),
        ("year_in_review", "Year in Review", "365 days of creativity.", "calendar.badge.checkmark", "seasonal"),
        ("seasonal_artist", "Seasonal Artist", "Art in every season.", "leaf.fill", "seasonal"),
        ("first_story", "First Story", "A voice memo saved forever.", "waveform", "voice"),
        ("storyteller", "Storyteller", "10 voice stories recorded.", "mic.fill", "voice"),
        ("rainbow_palette", "Rainbow Palette", "Every medium explored.", "paintpalette.fill", "medium")
    ]

    /// Seeds any default achievements that don't exist yet. Idempotent by
    /// identifier, so newly added badges appear on existing installs too.
    static func seedAchievements(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []
        let existingIds = Set(existing.map(\.identifier))

        var inserted = false
        for def in defaults where !existingIds.contains(def.id) {
            let achievement = Achievement(
                identifier: def.id,
                title: def.title,
                subtitle: def.subtitle,
                iconName: def.icon,
                category: def.category
            )
            context.insert(achievement)
            inserted = true
        }
        if inserted {
            try? context.save()
        }
    }

    /// Checks all milestone conditions and marks newly earned achievements.
    /// Returns the achievements earned by this check so callers can
    /// celebrate them (see `CelebrationCenter`).
    @discardableResult
    static func checkMilestones(context: ModelContext) -> [Achievement] {
        let allArtworks = (try? context.fetch(FetchDescriptor<Artwork>())) ?? []
        let achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        let artworkCount = allArtworks.count
        let voiceMemoCount = allArtworks.filter { $0.voiceNoteData != nil }.count
        let allTagNames = Set(allArtworks.flatMap { $0.tags?.map(\.name) ?? [] })
        let usedMediums = allTagNames.intersection(Set(mediumTags))

        let dates = allArtworks.map(\.createdAt)
        let hasYearSpan: Bool = {
            guard let earliest = dates.min(), let latest = dates.max() else { return false }
            return Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0 >= 365
        }()
        let seasons: Set<Int> = Set(dates.map { (Calendar.current.component(.month, from: $0) - 1) / 3 })
        let hasFourSeasons = seasons.count >= 4

        // Three artworks inside any rolling 7-day window.
        let hasCreativeWeek: Bool = {
            let sorted = dates.sorted()
            guard sorted.count >= 3 else { return false }
            for i in 0...(sorted.count - 3) where sorted[i + 2].timeIntervalSince(sorted[i]) <= 7 * 24 * 3600 {
                return true
            }
            return false
        }()

        let childCount = (try? context.fetchCount(FetchDescriptor<Child>())) ?? 0

        var newlyEarned: [Achievement] = []
        for achievement in achievements where !achievement.isEarned {
            let shouldEarn: Bool = switch achievement.identifier {
            case "first_masterpiece": artworkCount >= 1
            case "fridge_door": artworkCount >= 10
            case "little_curator": artworkCount >= 25
            case "prolific": artworkCount >= 50
            case "gallery_owner": artworkCount >= 100
            case "creative_week": hasCreativeWeek
            case "art_family": childCount >= 2
            case "year_in_review": hasYearSpan
            case "seasonal_artist": hasFourSeasons
            case "first_story": voiceMemoCount >= 1
            case "storyteller": voiceMemoCount >= 10
            case "rainbow_palette": usedMediums.count >= mediumTags.count
            default: false
            }

            if shouldEarn {
                achievement.isEarned = true
                achievement.earnedAt = .now
                newlyEarned.append(achievement)
            }
        }
        try? context.save()
        return newlyEarned
    }

    /// Marks the "Memory Lane" achievement as earned when user taps an "On This Day" card.
    static func markMemoryViewed(context: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>(
            predicate: #Predicate { $0.identifier == "memory_lane" }
        )
        guard let achievement = try? context.fetch(descriptor).first,
              !achievement.isEarned else { return }
        achievement.isEarned = true
        achievement.earnedAt = .now
        try? context.save()
    }
}
