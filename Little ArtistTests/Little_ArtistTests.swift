//
//  Little_ArtistTests.swift
//  Little ArtistTests
//
//  Unit tests for the Little Artist data models, utilities, and services.
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import Little_Artist

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
            #expect(id.hasPrefix("uk.co.flutterly.littleartist.premium."))
        }
    }
}
