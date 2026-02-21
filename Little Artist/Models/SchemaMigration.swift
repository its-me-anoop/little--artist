//
//  SchemaMigration.swift
//  Little Artist
//
//  Current schema definition for SwiftData models.
//
//  Note: The previous VersionedSchema / SchemaMigrationPlan was removed because
//  all schema versions referenced the *current* model types, producing duplicate
//  checksums at runtime (NSInvalidArgumentException "Duplicate version checksums
//  detected"). If proper versioned migrations are needed in the future, each
//  VersionedSchema must define its own nested @Model types that capture the
//  historical shape of each model at that version.
//

import Foundation
import SwiftData

// MARK: - Current Schema

enum SchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self, Tag.self]
    }
}
