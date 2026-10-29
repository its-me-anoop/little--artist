//
//  GrowthFeatureTests.swift
//  Little ArtistTests
//
//  Tests for the App Store growth features: review prompt throttling,
//  widget artwork selection, export helpers and print-ready PDF sizing.
//

import Foundation
import PDFKit
import SwiftData
import Testing
import UIKit
@testable import Little_Artist

// MARK: - Review Prompt

@MainActor
struct ReviewPromptServiceTests {

    /// A fresh, isolated defaults suite plus a controllable clock.
    private func makeService(start: Date = Date(timeIntervalSince1970: 1_800_000_000))
        -> (ReviewPromptService, UserDefaults, (TimeInterval) -> Void) {
        let suite = "ReviewPromptTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        var now = start
        let service = ReviewPromptService(defaults: defaults, now: { now })
        return (service, defaults, { now = now.addingTimeInterval($0) })
    }

    private let day: TimeInterval = 24 * 60 * 60

    @Test("No prompt before enough artworks are saved")
    func noPromptBeforeThreshold() {
        let (service, _, advance) = makeService()
        advance(10 * day)
        service.record(.artworkSaved(count: ReviewPromptService.artworksBeforeFirstPrompt - 1))
        #expect(service.isEligible() == false)
    }

    @Test("No prompt in the first days after install")
    func noPromptRightAfterInstall() {
        let (service, _, _) = makeService()
        service.record(.artworkSaved(count: 20))
        #expect(service.isEligible() == false)
    }

    @Test("Eligible once enough artworks and days have passed")
    func eligibleAfterThreshold() {
        let (service, _, advance) = makeService()
        advance(Double(ReviewPromptService.minimumDaysSinceInstall) * day)
        service.record(.artworkSaved(count: ReviewPromptService.artworksBeforeFirstPrompt))
        #expect(service.isEligible())
    }

    @Test("Asking once blocks another prompt for the same version")
    func throttledAfterPrompt() {
        let (service, _, advance) = makeService()
        advance(5 * day)
        service.record(.artworkSaved(count: 10))
        #expect(service.isEligible())
        service.didRequestReview()
        #expect(service.shouldRequestReview == false)
        advance(Double(ReviewPromptService.minimumDaysBetweenPrompts + 1) * day)
        // Same app version — still blocked.
        #expect(service.isEligible() == false)
    }

    @Test("Artwork counts accumulate across saves")
    func countsAccumulate() {
        let (service, _, _) = makeService()
        service.record(.artworkSaved(count: 2))
        service.record(.artworkSaved(count: 3))
        service.record(.milestoneCelebrated)
        #expect(service.artworksSaved == 5)
    }
}

// MARK: - Widget Selection

struct WidgetSnapshotSelectionTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test("On This Day leads, then favourites, then recent; no duplicates")
    func selectionOrder() {
        let today = date(2026, 10, 29)
        let candidates = [
            WidgetSnapshotService.Candidate(id: "recent", createdAt: date(2026, 10, 1), isFavorited: false),
            WidgetSnapshotService.Candidate(id: "fav", createdAt: date(2025, 3, 3), isFavorited: true),
            WidgetSnapshotService.Candidate(id: "anniv2", createdAt: date(2024, 10, 29), isFavorited: true),
            WidgetSnapshotService.Candidate(id: "anniv1", createdAt: date(2025, 10, 29), isFavorited: false),
            WidgetSnapshotService.Candidate(id: "today", createdAt: date(2026, 10, 29), isFavorited: false),
        ]
        let picks = WidgetSnapshotService.select(candidates, today: today, calendar: calendar)

        #expect(picks.map(\.id) == ["anniv2", "anniv1", "fav", "today", "recent"])
        #expect(picks[0].reason == .onThisDay)
        #expect(picks[0].yearsAgo == 2)
        #expect(picks[1].yearsAgo == 1)
        #expect(picks[2].reason == .favorite)
        // Artwork made today is not an anniversary.
        #expect(picks[3].reason == .recent)
        #expect(Set(picks.map(\.id)).count == picks.count)
    }

    @Test("Selection respects the entry limit")
    func selectionLimit() {
        let candidates = (0..<40).map {
            WidgetSnapshotService.Candidate(id: "\($0)", createdAt: Date(timeIntervalSince1970: Double($0) * 86_400), isFavorited: $0 % 2 == 0)
        }
        let picks = WidgetSnapshotService.select(candidates, calendar: calendar, limit: 12)
        #expect(picks.count == 12)
    }

    @Test("Snapshot round-trips through JSON")
    func snapshotCodable() throws {
        let entry = WidgetArtworkEntry(
            id: "abc", title: "Rainbow", childName: "Mia",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            reason: .onThisDay, yearsAgo: 3, imageFileName: "abc.jpg"
        )
        let snapshot = WidgetSnapshot(generatedAt: .now, totalArtworks: 7, entries: [entry])
        let data = try JSONEncoder.snapshot.encode(snapshot)
        let decoded = try JSONDecoder.snapshot.decode(WidgetSnapshot.self, from: data)
        #expect(decoded.entries == [entry])
        #expect(decoded.totalArtworks == 7)
    }

    @Test("Thumbnails are downscaled")
    func downscale() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000), format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return format
        }())
        let big = renderer.jpegData(withCompressionQuality: 0.9) { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
        }
        let small = try #require(WidgetSnapshotService.downscaledJPEG(big))
        let image = try #require(UIImage(data: small))
        #expect(max(image.size.width, image.size.height) <= CGFloat(WidgetSnapshotService.thumbnailMaxPixels))
    }
}

// MARK: - Archive Export

@MainActor
struct ArchiveExportTests {

    @Test("File names are sanitised")
    func sanitize() {
        #expect(ArchiveExportService.sanitized("Mia/Rose: \"Sun\"") == "Mia-Rose- -Sun-")
        #expect(ArchiveExportService.sanitized("   ") == "Untitled")
        #expect(ArchiveExportService.sanitized(String(repeating: "a", count: 200)).count == 80)
    }

    @Test("CSV fields are quoted and escaped")
    func csv() {
        #expect(ArchiveExportService.csvField("plain") == "\"plain\"")
        #expect(ArchiveExportService.csvField("say \"hi\", ok") == "\"say \"\"hi\"\", ok\"")
    }

    @Test("ZIP export contains every artwork")
    func zipExport() async throws {
        let schema = Schema([Child.self, Artwork.self, Tag.self, Comment.self, Achievement.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let child = Child(name: "Mia", avatarColor: "F2784B")
        context.insert(child)
        let pixel = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).jpegData(withCompressionQuality: 0.8) { _ in }
        for index in 0..<3 {
            context.insert(Artwork(
                title: "Same Title",
                imageData: pixel,
                voiceNoteData: index == 0 ? Data([0x01]) : nil,
                createdAt: Date(timeIntervalSince1970: 1_800_000_000),
                child: child
            ))
        }
        try context.save()

        let url = try await ArchiveExportService.exportZIP(container: container) { _ in }
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(url.pathExtension == "zip")
        let size = try #require(try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int)
        #expect(size > 0)
    }
}

// MARK: - Print-Ready PDF

@MainActor
struct PhotoBookPDFTests {

    @Test("Photo book pages are 8.25 in square (8 in + bleed)")
    func photoBookPageSize() throws {
        let artwork = Artwork(title: "Tree", imageData: UIGraphicsImageRenderer(size: CGSize(width: 10, height: 20)).pngData { _ in })
        let data = PDFExportService.generatePortfolio(childName: "Mia", artworks: [artwork], format: .photoBook8x8)
        let document = try #require(PDFDocument(data: data))
        #expect(document.pageCount == 2)
        let bounds = try #require(document.page(at: 0)).bounds(for: .mediaBox)
        #expect(bounds.width == 594)
        #expect(bounds.height == 594)
    }

    @Test("Letter format is unchanged")
    func letterPageSize() throws {
        let data = PDFExportService.generatePortfolio(childName: "Mia", artworks: [], format: .letter)
        let document = try #require(PDFDocument(data: data))
        let bounds = try #require(document.page(at: 0)).bounds(for: .mediaBox)
        #expect(bounds.size == CGSize(width: 612, height: 792))
    }
}
