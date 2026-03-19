//
//  Achievement.swift
//  Little Artist
//
//  SwiftData model representing a milestone badge that tracks the family's creative journey.
//

import Foundation
import SwiftData

/// A milestone badge that tracks the family's creative journey.
@Model final class Achievement {
    var identifier: String
    var title: String
    var subtitle: String
    var iconName: String
    var isEarned: Bool
    var earnedAt: Date?
    var category: String

    init(
        identifier: String,
        title: String,
        subtitle: String,
        iconName: String,
        isEarned: Bool = false,
        earnedAt: Date? = nil,
        category: String
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.isEarned = isEarned
        self.earnedAt = earnedAt
        self.category = category
    }
}
