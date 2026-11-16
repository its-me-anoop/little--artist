//
//  SerialTaskQueue.swift
//  Little Artist
//
//  Runs async operations one at a time, in the order they were submitted.
//  Apple Intelligence trapped inside FoundationModels when the artwork
//  check and the caption request ran at the same time, so every model
//  request goes through one queue.
//

import Foundation

/// Serializes async work: an operation starts only after the previous one
/// has finished, even across suspension points.
actor SerialTaskQueue {

    /// Shared queue for all on-device / Private Cloud Compute requests.
    static let languageModel = SerialTaskQueue()

    private var tail: Task<Void, Never>?

    /// Runs `operation` after every previously submitted operation has
    /// completed, and returns its result.
    func run<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        let previous = tail
        let task = Task<T, Error> {
            await previous?.value
            return try await operation()
        }
        tail = Task { _ = try? await task.value }
        return try await task.value
    }
}
