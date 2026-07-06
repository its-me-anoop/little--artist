//
//  PremiumManager.swift
//  Little Artist
//
//  Manages premium subscription status and free tier limits.
//  Uses StoreKitManager for live subscription state, with
//  UserDefaults cache as fallback for synchronous checks.
//

import SwiftUI

/// Centralized free tier limits and premium status.
///
/// Free tier is volume-capped, never time-limited: one child profile and
/// enough artworks to cover a school term, so families can prove the app's
/// value before paying. Unlimited children is the premium anchor.
enum PremiumManager {
    /// Maximum number of children on the free tier.
    static let freeChildLimit = 1

    /// Maximum number of artworks on the free tier.
    static let freeArtworkLimit = 40

    /// Override for testing. Set to non-nil to bypass UserDefaults.
    #if DEBUG
    static var _overrideIsPremium: Bool?
    #endif

    /// Whether the user has unlocked premium.
    /// Reads from UserDefaults cache (set by StoreKitManager).
    static var isPremium: Bool {
        #if DEBUG
        if let override = _overrideIsPremium { return override }
        #endif
        return UserDefaults.standard.bool(forKey: "isPremium")
    }

    /// Check if the user can add another child.
    static func canAddChild(currentCount: Int) -> Bool {
        isPremium || currentCount < freeChildLimit
    }

    /// Check if the user can add more artwork.
    static func canAddArtwork(currentCount: Int) -> Bool {
        isPremium || currentCount < freeArtworkLimit
    }
}
