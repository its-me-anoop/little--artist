//
//  ReviewPromptService.swift
//  Little Artist
//
//  Decides when to ask for an App Store rating. We only ask right after a
//  happy moment (saving artwork, a milestone celebration, an "On This Day"
//  memory), never on launch and never mid-task, and we throttle hard so
//  the prompt stays rare. Apple additionally caps the system prompt at
//  three showings per year.
//

import Foundation
import Observation

/// Tracks happy moments and raises ``shouldRequestReview`` when it is a
/// good time to show the system rating prompt.
///
/// The root view observes ``shouldRequestReview``, calls SwiftUI's
/// `requestReview` action, then calls ``didRequestReview()``.
@MainActor
@Observable
final class ReviewPromptService {
    static let shared = ReviewPromptService()

    /// A moment worth asking for a rating after.
    enum HappyMoment {
        /// The user saved one or more artworks.
        case artworkSaved(count: Int)
        /// A milestone celebration was dismissed.
        case milestoneCelebrated
        /// The user opened an "On This Day" memory.
        case memoryViewed
    }

    // MARK: - Tuning

    /// Total artworks saved before the first prompt may appear.
    static let artworksBeforeFirstPrompt = 5
    /// Minimum days between two prompts.
    static let minimumDaysBetweenPrompts = 60
    /// Minimum days since first launch before any prompt.
    static let minimumDaysSinceInstall = 2

    // MARK: - State

    /// Set to `true` when the root view should show the rating prompt.
    private(set) var shouldRequestReview = false

    private let defaults: UserDefaults
    private let now: () -> Date

    private enum Key {
        static let firstLaunch = "review.firstLaunchDate"
        static let artworksSaved = "review.artworksSaved"
        static let lastPromptDate = "review.lastPromptDate"
        static let lastPromptVersion = "review.lastPromptVersion"
    }

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
        if defaults.object(forKey: Key.firstLaunch) == nil {
            defaults.set(now(), forKey: Key.firstLaunch)
        }
    }

    // MARK: - Public API

    /// Total artworks saved since install (for testing and display).
    var artworksSaved: Int { defaults.integer(forKey: Key.artworksSaved) }

    /// Records a happy moment and raises the prompt flag if eligible.
    func record(_ moment: HappyMoment) {
        if case .artworkSaved(let count) = moment {
            defaults.set(artworksSaved + max(count, 0), forKey: Key.artworksSaved)
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") { return }
        #endif
        if isEligible() {
            shouldRequestReview = true
        }
    }

    /// Call after the system prompt was requested so we don't ask again soon.
    func didRequestReview() {
        shouldRequestReview = false
        defaults.set(now(), forKey: Key.lastPromptDate)
        defaults.set(Self.currentVersion, forKey: Key.lastPromptVersion)
    }

    // MARK: - Eligibility

    /// Whether every throttle rule currently allows a prompt.
    func isEligible() -> Bool {
        guard artworksSaved >= Self.artworksBeforeFirstPrompt else { return false }

        if let firstLaunch = defaults.object(forKey: Key.firstLaunch) as? Date,
           days(since: firstLaunch) < Self.minimumDaysSinceInstall {
            return false
        }

        if let lastPrompt = defaults.object(forKey: Key.lastPromptDate) as? Date,
           days(since: lastPrompt) < Self.minimumDaysBetweenPrompts {
            return false
        }

        // At most once per app version.
        if defaults.string(forKey: Key.lastPromptVersion) == Self.currentVersion {
            return false
        }

        return true
    }

    private func days(since date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: now()).day ?? 0
    }

    private static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    // MARK: - App Store Links

    /// The app's App Store ID.
    static let appStoreID = "6759450819"

    /// Opens the App Store "write a review" page directly.
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    /// Public App Store page, used when sharing the app.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
}
