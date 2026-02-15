//
//  Artwork.swift
//  Little Artist
//
//  Created by Anoop Jose on 13/02/2026.
//

import Foundation
import SwiftData

@Model
final class Artwork {
    var title: String
    var caption: String

    @Attribute(.externalStorage)
    var imageData: Data?

    var voiceNoteURL: String?
    var createdAt: Date

    var child: Child?

    init(
        title: String,
        caption: String = "",
        imageData: Data? = nil,
        voiceNoteURL: String? = nil,
        createdAt: Date = .now,
        child: Child? = nil
    ) {
        self.title = title
        self.caption = caption
        self.imageData = imageData
        self.voiceNoteURL = voiceNoteURL
        self.createdAt = createdAt
        self.child = child
    }
}
