//
//  Child.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftData

@Model
final class Child {
    var name: String
    var avatarColor: String
    var createdAt: Date

    @Attribute(.externalStorage)
    var avatarImageData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Artwork.child)
    var artworks: [Artwork]?

    init(name: String, avatarColor: String, avatarImageData: Data? = nil, createdAt: Date = .now) {
        self.name = name
        self.avatarColor = avatarColor
        self.avatarImageData = avatarImageData
        self.createdAt = createdAt
    }
}
