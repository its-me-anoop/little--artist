//
//  SchemaMigrationV8.swift
//  Little Artist
//
//  Schema V8 definition and lightweight migration plan from V7.
//  Adds Comment and Achievement models.
//

import Foundation
import SwiftData

enum SchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)
    static var models: [any PersistentModel.Type] = [
        Child.self,
        Artwork.self,
        Tag.self,
        Comment.self,
        Achievement.self
    ]
}

enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV7.self, SchemaV8.self]
    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: SchemaV7.self, toVersion: SchemaV8.self)
    ]
}
