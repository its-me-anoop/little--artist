//
//  QuickActionRouter.swift
//  Little Artist
//
//  Routes app-wide quick actions (Siri App Intents, shortcuts) into the
//  SwiftUI navigation layer.
//

import Foundation
import Observation

/// A pending navigation request raised outside the view hierarchy —
/// e.g. by a Siri App Intent — and consumed by `ContentView`.
@MainActor
@Observable
final class QuickActionRouter {
    static let shared = QuickActionRouter()

    /// Destinations the app can jump straight into.
    enum Action: Equatable {
        /// Open capture, attributing the piece to a child when given.
        case captureArtwork(childID: UUID? = nil)
        case showMilestones
        case showTimeline
        /// Show one piece of artwork (from Siri, Shortcuts or Spotlight).
        case openArtwork(UUID)
        /// Show the gallery filtered to one child.
        case openChild(UUID)
    }

    /// The action waiting to be handled, if any. Consumers reset this to
    /// nil after acting on it.
    var pendingAction: Action?

    private init() {}
}
