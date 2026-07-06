//
//  CelebrationCenter.swift
//  Little Artist
//
//  Queues newly earned achievements so the root view can celebrate them
//  with confetti — one at a time, in the order they were earned.
//

import Foundation
import Observation

/// App-wide queue of achievements waiting to be celebrated.
///
/// Producers (save flows, imports) append via ``celebrate(_:)``;
/// `ContentView` presents an overlay for ``current`` and advances the
/// queue with ``dismissCurrent()``.
@MainActor
@Observable
final class CelebrationCenter {
    static let shared = CelebrationCenter()

    /// Achievements queued for celebration, oldest first.
    private(set) var queue: [Achievement] = []

    /// The achievement currently being celebrated, if any.
    var current: Achievement? { queue.first }

    /// Adds newly earned achievements to the celebration queue.
    func celebrate(_ achievements: [Achievement]) {
        queue.append(contentsOf: achievements)
    }

    /// Finishes the current celebration and moves to the next one.
    func dismissCurrent() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
    }

    private init() {}
}
