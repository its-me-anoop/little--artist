//
//  HapticService.swift
//  Little Artist
//
//  Centralized haptic feedback helpers for consistent
//  tactile responses throughout the app.
//

import UIKit

enum HapticService {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
