//
//  Little_ArtistTests.swift
//  Little ArtistTests
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

struct Little_ArtistTests {

    @Test("Artwork initializer stores provided values")
    func artworkInitializerStoresProvidedValues() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let child = Child(name: "Mia", avatarColor: "FF8000")
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

        let artwork = Artwork(
            title: "Sunset",
            caption: "By the beach",
            imageData: data,
            voiceNoteURL: "voice.m4a",
            createdAt: createdAt,
            child: child
        )

        #expect(artwork.title == "Sunset")
        #expect(artwork.caption == "By the beach")
        #expect(artwork.imageData == data)
        #expect(artwork.voiceNoteURL == "voice.m4a")
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
        #expect(artwork.voiceNoteURL == nil)
        #expect(artwork.child == nil)
        #expect(artwork.createdAt >= before && artwork.createdAt <= after)
    }

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
