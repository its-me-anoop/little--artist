//
//  Little_ArtistTests.swift
//  Little ArtistTests
//
//  Unit tests for the Little Artist data models, utilities, and services.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Little_Artist

/// Builds an isolated in-memory context covering the full app schema.
@MainActor
private func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}

// MARK: - Artwork Model Tests

struct ArtworkModelTests {

    @Test("Artwork initializer stores provided values")
    func artworkInitializerStoresProvidedValues() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let child = Child(name: "Mia", avatarColor: "FF8000")
        let imageData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let voiceData = Data([0x01, 0x02, 0x03])

        let artwork = Artwork(
            title: "Sunset",
            caption: "By the beach",
            imageData: imageData,
            voiceNoteData: voiceData,
            isFavorited: true,
            createdAt: createdAt,
            child: child
        )

        #expect(artwork.title == "Sunset")
        #expect(artwork.caption == "By the beach")
        #expect(artwork.imageData == imageData)
        #expect(artwork.voiceNoteData == voiceData)
        #expect(artwork.isFavorited == true)
        #expect(artwork.createdAt == createdAt)
        #expect(artwork.child === child)
    }

    @Test("Artwork initializer applies defaults")
    func artworkInitializerAppliesDefaults() {
        let before = Date()
        let artwork = Artwork(title: "Untitled")
        let after = Date()

        #expect(artwork.caption == "")
        #expect(artwork.imageData == nil)
        #expect(artwork.voiceNoteData == nil)
        #expect(artwork.isFavorited == false)
        #expect(artwork.child == nil)
        #expect(artwork.createdAt >= before && artwork.createdAt <= after)
    }
}

// MARK: - Child Model Tests

struct ChildModelTests {

    @Test("Child initializer stores values")
    func childInitializerStoresValues() {
        let createdAt = Date(timeIntervalSince1970: 1_650_000_000)
        let avatarData = Data([0x00, 0x01, 0x02])

        let child = Child(
            name: "Noah",
            avatarColor: "0088FF",
            avatarImageData: avatarData,
            createdAt: createdAt
        )

        #expect(child.name == "Noah")
        #expect(child.avatarColor == "0088FF")
        #expect(child.avatarImageData == avatarData)
        #expect(child.createdAt == createdAt)
    }

    @Test("Child initializer applies defaults")
    func childInitializerAppliesDefaults() {
        let before = Date()
        let child = Child(name: "Lily", avatarColor: "FF0000")
        let after = Date()

        #expect(child.avatarImageData == nil)
        #expect(child.createdAt >= before && child.createdAt <= after)
    }
}

// MARK: - Color Hex Tests

struct ColorHexTests {

    @Test("Color init(hex:) parses 6-digit RGB")
    func colorHexParsesSixDigitRGB() {
        #if canImport(UIKit)
        let uiColor = UIColor(Color(hex: "FF8000"))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let extracted = uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(extracted)
        #expect(abs(red - 1.0) < 0.001)
        #expect(abs(green - (128.0 / 255.0)) < 0.001)
        #expect(abs(blue - 0.0) < 0.001)
        #expect(abs(alpha - 1.0) < 0.001)
        #endif
    }

    @Test("Color init(hex:) falls back to white for unsupported input")
    func colorHexFallsBackToWhiteForUnsupportedInput() {
        #if canImport(UIKit)
        let uiColor = UIColor(Color(hex: "FFF"))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let extracted = uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        #expect(extracted)
        #expect(abs(red - 1.0) < 0.001)
        #expect(abs(green - 1.0) < 0.001)
        #expect(abs(blue - 1.0) < 0.001)
        #expect(abs(alpha - 1.0) < 0.001)
        #endif
    }
}

// MARK: - PremiumManager Tests

struct PremiumManagerTests {

    @Test("canAddChild returns true when under limit")
    func canAddChildUnderLimit() {
        #expect(PremiumManager.canAddChild(currentCount: 0) == true)
    }

    @Test("canAddChild returns false when at limit")
    func canAddChildAtLimit() {
        // Ensure we're testing free tier (isPremium defaults to false)
        UserDefaults.standard.removeObject(forKey: "isPremium")
        #expect(PremiumManager.canAddChild(currentCount: 1) == false)
        #expect(PremiumManager.canAddChild(currentCount: 5) == false)
    }

    @Test("canAddArtwork returns true when under limit")
    func canAddArtworkUnderLimit() {
        #expect(PremiumManager.canAddArtwork(currentCount: 0) == true)
        #expect(PremiumManager.canAddArtwork(currentCount: 39) == true)
    }

    @Test("canAddArtwork returns false when at limit")
    func canAddArtworkAtLimit() {
        UserDefaults.standard.removeObject(forKey: "isPremium")
        #expect(PremiumManager.canAddArtwork(currentCount: 40) == false)
        #expect(PremiumManager.canAddArtwork(currentCount: 100) == false)
    }

    @Test("Free tier limits are correct")
    func freeTierLimitsAreCorrect() {
        #expect(PremiumManager.freeChildLimit == 1)
        #expect(PremiumManager.freeArtworkLimit == 40)
    }

    @Test("Premium user bypasses limits")
    func premiumUserBypassesLimits() {
        PremiumManager._overrideIsPremium = true

        let canAddChild = PremiumManager.canAddChild(currentCount: 100)
        let canAddArtwork = PremiumManager.canAddArtwork(currentCount: 1000)

        PremiumManager._overrideIsPremium = nil

        #expect(canAddChild == true)
        #expect(canAddArtwork == true)
    }
}

// MARK: - ArtworkRepository Tests

@MainActor
struct ArtworkRepositoryTests {

    @Test("createChild persists a child")
    func createChildPersists() throws {
        let context = try makeInMemoryContext()

        let child = ArtworkRepository.shared.createChild(
            name: "Mia", avatarColor: "F2784B", in: context
        )

        #expect(child.name == "Mia")
        #expect(try context.fetchCount(FetchDescriptor<Child>()) == 1)
    }

    @Test("updateChild changes only provided fields")
    func updateChildPartial() throws {
        let context = try makeInMemoryContext()
        let child = ArtworkRepository.shared.createChild(
            name: "Noah", avatarColor: "7EB8DA", in: context
        )

        ArtworkRepository.shared.updateChild(child, name: "Noah James", in: context)

        #expect(child.name == "Noah James")
        #expect(child.avatarColor == "7EB8DA")
    }

    @Test("deleteChild cascades to artworks")
    func deleteChildCascades() throws {
        let context = try makeInMemoryContext()
        let child = ArtworkRepository.shared.createChild(
            name: "Ivy", avatarColor: "A8C5A0", in: context
        )
        ArtworkRepository.shared.createArtwork(title: "Sun", child: child, in: context)
        #expect(try context.fetchCount(FetchDescriptor<Artwork>()) == 1)

        ArtworkRepository.shared.deleteChild(child, in: context)

        #expect(try context.fetchCount(FetchDescriptor<Child>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Artwork>()) == 0)
    }

    @Test("createArtwork stores fields and links the child")
    func createArtworkStoresFields() throws {
        let context = try makeInMemoryContext()
        let child = ArtworkRepository.shared.createChild(
            name: "Leo", avatarColor: "B8A9D4", in: context
        )

        let artwork = ArtworkRepository.shared.createArtwork(
            title: "Rocket",
            caption: "To the moon",
            imageData: Data([0x01]),
            child: child,
            in: context
        )

        #expect(artwork.title == "Rocket")
        #expect(artwork.caption == "To the moon")
        #expect(artwork.child === child)
        #expect(child.artworks?.count == 1)
    }

    @Test("Voice notes are dropped for free-tier users and kept for premium")
    func voiceNotePremiumGating() throws {
        let context = try makeInMemoryContext()
        let child = ArtworkRepository.shared.createChild(
            name: "Zoe", avatarColor: "E8C94A", in: context
        )
        let voice = Data([0x0A, 0x0B])

        PremiumManager._overrideIsPremium = false
        let freeArtwork = ArtworkRepository.shared.createArtwork(
            title: "Free", voiceNoteData: voice, child: child, in: context
        )

        PremiumManager._overrideIsPremium = true
        let premiumArtwork = ArtworkRepository.shared.createArtwork(
            title: "Premium", voiceNoteData: voice, child: child, in: context
        )
        PremiumManager._overrideIsPremium = nil

        #expect(freeArtwork.voiceNoteData == nil)
        #expect(premiumArtwork.voiceNoteData == voice)
    }

    @Test("updateArtwork edits fields and deleteArtwork removes it")
    func updateAndDeleteArtwork() throws {
        let context = try makeInMemoryContext()
        let child = ArtworkRepository.shared.createChild(
            name: "Ada", avatarColor: "D4928A", in: context
        )
        let artwork = ArtworkRepository.shared.createArtwork(
            title: "Before", child: child, in: context
        )

        ArtworkRepository.shared.updateArtwork(
            artwork, title: "After", isFavorited: true, in: context
        )
        #expect(artwork.title == "After")
        #expect(artwork.isFavorited == true)

        ArtworkRepository.shared.deleteArtwork(artwork, in: context)
        #expect(try context.fetchCount(FetchDescriptor<Artwork>()) == 0)
    }
}

// MARK: - AchievementService Tests

@MainActor
struct AchievementServiceTests {

    @Test("Seeding creates the default achievements exactly once")
    func seedingIsIdempotent() throws {
        let context = try makeInMemoryContext()

        AchievementService.seedAchievements(context: context)
        let firstCount = try context.fetchCount(FetchDescriptor<Achievement>())

        AchievementService.seedAchievements(context: context)
        let secondCount = try context.fetchCount(FetchDescriptor<Achievement>())

        #expect(firstCount == 8)
        #expect(secondCount == 8)
    }

    @Test("First artwork unlocks First Masterpiece and reports it once")
    func firstMasterpieceUnlocksOnce() throws {
        let context = try makeInMemoryContext()
        AchievementService.seedAchievements(context: context)

        let child = Child(name: "Eli", avatarColor: "7BC8B5")
        context.insert(child)
        context.insert(Artwork(title: "Cat", child: child))
        try context.save()

        let earned = AchievementService.checkMilestones(context: context)
        #expect(earned.contains { $0.identifier == "first_masterpiece" })

        // A second check must not re-report the same achievement.
        let earnedAgain = AchievementService.checkMilestones(context: context)
        #expect(earnedAgain.isEmpty)
    }

    @Test("No achievements are earned with an empty gallery")
    func emptyGalleryEarnsNothing() throws {
        let context = try makeInMemoryContext()
        AchievementService.seedAchievements(context: context)

        let earned = AchievementService.checkMilestones(context: context)
        #expect(earned.isEmpty)
    }
}

// MARK: - CelebrationCenter Tests

@MainActor
struct CelebrationCenterTests {

    @Test("Celebrations queue in order and dismiss one at a time")
    func queueAndDismiss() {
        let center = CelebrationCenter.shared
        // Drain anything left over from other tests.
        while center.current != nil { center.dismissCurrent() }

        let first = Achievement(
            identifier: "a", title: "A", subtitle: "", iconName: "star", category: "test"
        )
        let second = Achievement(
            identifier: "b", title: "B", subtitle: "", iconName: "star", category: "test"
        )

        center.celebrate([first, second])
        #expect(center.current?.identifier == "a")

        center.dismissCurrent()
        #expect(center.current?.identifier == "b")

        center.dismissCurrent()
        #expect(center.current == nil)

        // Dismissing with an empty queue must not crash.
        center.dismissCurrent()
        #expect(center.current == nil)
    }
}

// MARK: - Comment Model Tests

struct CommentModelTests {

    @Test("Comment initializer stores values with sensible defaults")
    func commentInitializer() {
        let comment = Comment(text: "Lovely!", authorName: "Grandma")

        #expect(comment.text == "Lovely!")
        #expect(comment.authorName == "Grandma")
        #expect(comment.authorAvatarData == nil)
        #expect(comment.artwork == nil)
    }
}

// MARK: - AI Engine Ladder Tests

struct AIEngineLadderTests {

    @Test("On-device engine leads the ladder when fully capable")
    func onDevicePreferred() {
        let availability = AIEngineAvailability(
            onDeviceAvailable: true,
            onDeviceSupportsVision: true,
            privateCloudAvailable: true,
            privateCloudSupportsVision: true,
            privateCloudQuotaReached: false
        )
        #expect(availability.capableAppleEngines == [.onDevice, .privateCloudCompute])
    }

    @Test("Falls to Private Cloud Compute when on-device lacks vision")
    func privateCloudWhenOnDeviceLacksVision() {
        let availability = AIEngineAvailability(
            onDeviceAvailable: true,
            onDeviceSupportsVision: false,
            privateCloudAvailable: true,
            privateCloudSupportsVision: true,
            privateCloudQuotaReached: false
        )
        #expect(availability.capableAppleEngines == [.privateCloudCompute])
    }

    @Test("Private Cloud Compute is skipped when quota is reached")
    func privateCloudSkippedWhenQuotaReached() {
        let availability = AIEngineAvailability(
            onDeviceAvailable: false,
            onDeviceSupportsVision: false,
            privateCloudAvailable: true,
            privateCloudSupportsVision: true,
            privateCloudQuotaReached: true
        )
        #expect(availability.capableAppleEngines.isEmpty)
    }

    @Test("Empty ladder falls to static fallback when nothing available")
    func emptyLadderFallsToStaticFallback() {
        let availability = AIEngineAvailability()
        #expect(availability.capableAppleEngines.isEmpty)
    }

    @Test("Privacy badge shown only for Apple engines")
    func privacyBadges() {
        #expect(AIEngine.onDevice.privacyBadge != nil)
        #expect(AIEngine.privateCloudCompute.privacyBadge != nil)
        #expect(AIEngine.fallback.privacyBadge == nil)
    }
}

// MARK: - StoreKitManager Tests

@MainActor
struct StoreKitProductTests {

    @Test("All three premium products are configured")
    func allProductsConfigured() {
        #expect(StoreKitManager.ProductID.all.count == 3)
        #expect(StoreKitManager.ProductID.all.contains(StoreKitManager.ProductID.monthlyPremium))
        #expect(StoreKitManager.ProductID.all.contains(StoreKitManager.ProductID.yearlyPremium))
        #expect(StoreKitManager.ProductID.all.contains(StoreKitManager.ProductID.lifetimePremium))
    }

    @Test("Product identifiers use the app's bundle prefix")
    func productIdentifiersUseBundlePrefix() {
        for id in StoreKitManager.ProductID.all {
            #expect(id.hasPrefix("com.flutterly.littleartist.premium."))
        }
    }
}
