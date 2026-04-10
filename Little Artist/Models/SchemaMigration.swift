//
//  SchemaMigration.swift
//  Little Artist
//
//  Current schema definition for SwiftData models.
//
//  Version history:
//  - V7 (legacy): included `Child.sharedRecordName` and `Artwork.syncIdentifier`.
//  - V8 (current): drops both of those fields. SwiftData handles the
//    property-removal migration automatically as a lightweight migration
//    because no data transformation is required.
//
//  Note: An explicit `SchemaMigrationPlan` with nested per-version snapshot
//  model types is intentionally NOT used here. Defining V7 and V8 as separate
//  VersionedSchemas that both reference the *current* top-level model types
//  produces duplicate checksums at runtime (SwiftData:
//  `NSInvalidArgumentException "Duplicate version checksums detected"`).
//  Because the only change from V7 → V8 is the removal of two optional
//  String fields, bumping the version identifier on a single VersionedSchema
//  is sufficient — SwiftData detects the drift and runs lightweight migration.
//

import Foundation
import SwiftData

// MARK: - Current Schema

/// Current active schema. Bumping this version identifier signals SwiftData
/// to run a lightweight migration against on-disk stores created by earlier
/// app builds.
enum SchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self, Tag.self]
    }
}
