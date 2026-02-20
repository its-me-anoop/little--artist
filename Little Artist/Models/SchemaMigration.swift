//
//  SchemaMigration.swift
//  Little Artist
//
//  Versioned schema migration plan for SwiftData models.
//  All migrations are lightweight — SwiftData infers changes automatically.
//

import Foundation
import SwiftData

// MARK: - V1 Schema (Original: Child, Artwork)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self]
    }
}

// MARK: - V2 Schema (Added isFavorited, voiceNoteData)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self]
    }
}

// MARK: - V3 Schema (CloudKit-compatible defaults)

enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self]
    }
}

// MARK: - V4 Schema (Added Tag model + tags relationship)

enum SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self, Tag.self]
    }
}

// MARK: - V5 Schema (Added sharedRecordName for CloudKit sharing)

enum SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Child.self, Artwork.self, Tag.self]
    }
}

// MARK: - Migration Plan

enum LittleArtistMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self, SchemaV5.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )
}
