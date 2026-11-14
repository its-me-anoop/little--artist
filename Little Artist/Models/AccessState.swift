//
//  AccessState.swift
//  Little Artist
//
//  Pure, StoreKit-free description of what the user may do, and the policy
//  that derives it from their purchase history. Kept free of side effects so
//  it can be unit tested exhaustively.
//

import Foundation

// MARK: - Product Catalog

/// In-app purchase identifiers configured in App Store Connect.
enum ProductCatalog {
    /// $0 non-consumable named "30-Day Free Trial" (App Review Guideline 3.1.1).
    /// Its purchase date marks the start of the trial and is restored with
    /// the user's Apple Account, so reinstalling cannot restart the trial.
    static let trial = "com.flutterly.littleartist.trial.30day"

    /// One-time, non-consumable lifetime unlock. Family Sharing is OFF for
    /// this product: Little Artist is a single-user app.
    static let lifetime = "com.flutterly.littleartist.lifetime"

    /// Retired products (the old subscriptions and the family-shareable
    /// lifetime unlock). Anyone who ever bought one keeps full access for life.
    static let legacyProducts = [
        "com.flutterly.littleartist.premium.monthly",
        "com.flutterly.littleartist.premium.yearly",
        "com.flutterly.littleartist.premium.lifetime"
    ]

    /// Products the paywall loads.
    static let purchasable = [trial, lifetime]

    /// Length of the free trial.
    static let trialLength: TimeInterval = 30 * 86_400
}

// MARK: - Purchase Record

/// A verified purchase, abstracted away from StoreKit's `Transaction`.
struct PurchaseRecord: Equatable, Sendable {
    let productID: String
    let purchaseDate: Date
    /// `true` when Apple refunded or revoked the purchase.
    let isRevoked: Bool
}

// MARK: - Gated Features

/// Actions that need an active trial or the lifetime unlock. Viewing,
/// editing, sharing and exporting existing artwork are always free so
/// families never lose access to their memories.
enum GatedFeature: CaseIterable, Sendable {
    case addArtwork
    case addChild
    case aiSuggestions
    case voiceMemo
}

// MARK: - Access State

/// What the user is entitled to right now.
enum AccessState: Equatable, Sendable {
    /// The free trial has never been started.
    case notStarted
    /// The free trial is running.
    case trial(daysRemaining: Int, endsAt: Date)
    /// Lifetime unlock purchased (or grandfathered from a legacy subscription).
    case lifetime
    /// The free trial ended without a purchase.
    case expired

    /// Whether every feature is unlocked.
    var hasFullAccess: Bool {
        switch self {
        case .trial, .lifetime: true
        case .notStarted, .expired: false
        }
    }

    /// Whether the free trial can still be offered.
    var canStartTrial: Bool { self == .notStarted }

    /// Whether `feature` is available.
    func allows(_ feature: GatedFeature) -> Bool { hasFullAccess }
}

// MARK: - Access Policy

/// Derives an ``AccessState`` from a purchase history.
enum AccessPolicy {

    static func evaluate(purchases: [PurchaseRecord], now: Date) -> AccessState {
        let valid = purchases.filter { !$0.isRevoked }

        let ownsLifetime = valid.contains { record in
            record.productID == ProductCatalog.lifetime
                || ProductCatalog.legacyProducts.contains(record.productID)
        }
        if ownsLifetime { return .lifetime }

        guard let trialStart = valid
            .filter({ $0.productID == ProductCatalog.trial })
            .map(\.purchaseDate)
            .min()
        else { return .notStarted }

        let endsAt = trialStart.addingTimeInterval(ProductCatalog.trialLength)
        guard now < endsAt else { return .expired }

        let remaining = endsAt.timeIntervalSince(now) / 86_400
        return .trial(daysRemaining: Int(remaining.rounded(.up)), endsAt: endsAt)
    }
}
