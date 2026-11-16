//
//  PremiumManager.swift
//  Little Artist
//
//  Synchronous access checks for code that cannot observe
//  ``StoreKitManager`` (repositories, intents, button handlers).
//
//  There are no count limits any more: during the 30-day free trial and
//  after the one-time lifetime purchase everything is unlimited. Before the
//  trial starts, or after it ends without a purchase, creating new content
//  is locked but existing artwork stays viewable, editable and exportable.
//

import Foundation

/// Centralized, synchronous premium checks.
enum PremiumManager {

    /// Override for testing. Set to non-nil to bypass the cached state.
    #if DEBUG
    static var _overrideIsPremium: Bool?
    #endif

    /// The last known access state, as cached by ``StoreKitManager``.
    static var accessState: AccessState {
        UserDefaultsAccessCache().load(now: .now) ?? .notStarted
    }

    /// Whether every feature is unlocked (trial running or lifetime owned).
    static var isPremium: Bool {
        #if DEBUG
        if let override = _overrideIsPremium { return override }
        #endif
        return accessState.hasFullAccess
    }

    /// Whether a child can be added. Children are unlimited with access.
    static func canAddChild(currentCount _: Int = 0) -> Bool { isPremium }

    /// Whether artwork can be added. Artwork is unlimited with access.
    static func canAddArtwork(currentCount _: Int = 0) -> Bool { isPremium }
}
