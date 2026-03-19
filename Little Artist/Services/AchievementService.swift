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
        ("prolific", "Prolific", "A growing stack of art.", "square.stack.3d.up.fill", "artwork"),
        ("gallery_owner", "Gallery Owner", "100 masterpieces saved.", "person.crop.rectangle.stack.fill", "artwork"),
        ("memory_lane", "Memory Lane", "Relived your first memory.", "text.book.closed.fill", "engagement"),
        ("year_in_review", "Year in Review", "365 days of creativity.", "calendar.badge.checkmark", "seasonal"),
        ("seasonal_artist", "Seasonal Artist", "Art in every season.", "leaf.fill", "seasonal"),
        ("storyteller", "Storyteller", "10 voice stories recorded.", "mic.fill", "voice"),
        ("rainbow_palette", "Rainbow Palette", "Every medium explored.", "paintpalette.fill", "medium")
    ]

    /// Seeds all default achievements if none exist. Call on first launch.
    static func seedAchievements(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Achievement>())) ?? 0
        guard existing == 0 else { return }

        for def in defaults {
            let achievement = Achievement(
                identifier: def.id,
                title: def.title,
                subtitle: def.subtitle,
                iconName: def.icon,
                category: def.category
            )
            context.insert(achievement)
        }
        try? context.save()
    }

    /// Checks all milestone conditions and marks newly earned achievements.
    static func checkMilestones(context: ModelContext) {
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

        for achievement in achievements where !achievement.isEarned {
            let shouldEarn: Bool = switch achievement.identifier {
            case "first_masterpiece": artworkCount >= 1
            case "prolific": artworkCount >= 50
            case "gallery_owner": artworkCount >= 100
            case "year_in_review": hasYearSpan
            case "seasonal_artist": hasFourSeasons
            case "storyteller": voiceMemoCount >= 10
            case "rainbow_palette": usedMediums.count >= mediumTags.count
            default: false
            }

            if shouldEarn {
                achievement.isEarned = true
                achievement.earnedAt = .now
            }
        }
        try? context.save()
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
