//
//  Tag.swift
//  Little Artist
//
//  SwiftData model representing a tag/category for artwork.
//

import Foundation
import SwiftData

/// A reusable tag that can be applied to artworks for categorization.
@Model
final class Tag {
    /// The display name of the tag.
    var name: String = ""

    /// Artworks tagged with this tag.
    @Relationship(inverse: \Artwork.tags)
    var artworks: [Artwork]?

    init(name: String) {
        self.name = name
    }
}
