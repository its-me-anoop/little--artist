//
//  IdentifierBackfill.swift
//  Little Artist
//
//  Ensures every Child and Artwork has a unique `uuid`. SwiftData's
//  lightweight migration gives all pre-existing rows the same default
//  value, and Siri / Spotlight need each one to be distinct.
//

import Foundation
import SwiftData

/// Reassigns duplicate identifiers so each record is unique.
enum IdentifierBackfill {

    /// Returns how many records received a new identifier.
    @discardableResult
    static func run(in context: ModelContext) throws -> Int {
        var repaired = 0
        repaired += reassignDuplicates(
            try context.fetch(FetchDescriptor<Child>(sortBy: [SortDescriptor(\.createdAt)])),
            id: \.uuid
        )
        repaired += reassignDuplicates(
            try context.fetch(FetchDescriptor<Artwork>(sortBy: [SortDescriptor(\.createdAt)])),
            id: \.uuid
        )
        if repaired > 0 { try context.save() }
        return repaired
    }

    /// Keeps the first occurrence of each identifier (oldest record) and
    /// gives later duplicates a fresh one.
    static func reassignDuplicates<Model: AnyObject>(
        _ models: [Model],
        id: ReferenceWritableKeyPath<Model, UUID>
    ) -> Int {
        var seen = Set<UUID>()
        var repaired = 0
        for model in models {
            if seen.contains(model[keyPath: id]) {
                model[keyPath: id] = UUID()
                repaired += 1
            }
            seen.insert(model[keyPath: id])
        }
        return repaired
    }
}
