//
//  StoreKitManager.swift
//  Little Artist
//
//  Owns the user's access state: a free 30-day trial (a $0 non-consumable,
//  per App Review Guideline 3.1.1) followed by a one-time lifetime unlock.
//  There are no subscriptions. StoreKit sits behind the `StoreFront`
//  protocol so the logic is unit tested without the App Store.
//

import Foundation
import Observation
import StoreKit

// MARK: - Store Abstractions

/// Result of a purchase attempt.
enum PurchaseOutcome: Equatable, Sendable {
    case purchased
    case cancelled
    case pending
}

/// The App Store operations the entitlement service depends on.
protocol StoreFront: Sendable {
    /// Every verified purchase the user has made, including refunded ones.
    func purchaseHistory() async -> [PurchaseRecord]
    /// Localised display prices keyed by product identifier.
    func displayPrices(for productIDs: [String]) async throws -> [String: String]
    /// Buys a product and finishes the transaction.
    func purchase(productID: String) async throws -> PurchaseOutcome
    /// Forces a sync with the App Store (Restore Purchases).
    func sync() async throws
}

/// Persists the last known access state for instant, offline gating.
protocol AccessStateCaching: AnyObject {
    func load(now: Date) -> AccessState?
    func save(_ state: AccessState)
}

// MARK: - Store Manager

/// Observable source of truth for what the user can do.
@MainActor
@Observable
final class StoreKitManager {

    /// Shared instance backed by StoreKit.
    static let shared = StoreKitManager(
        store: StoreKitStoreFront(),
        clock: { Date.now },
        cache: UserDefaultsAccessCache()
    )

    // MARK: State

    private(set) var state: AccessState
    private(set) var lifetimePrice: String?
    private(set) var isPurchasing = false
    var errorMessage: String?

    // MARK: Dependencies

    @ObservationIgnored private let store: StoreFront
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private let cache: AccessStateCaching
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(store: StoreFront, clock: @escaping () -> Date, cache: AccessStateCaching) {
        self.store = store
        self.clock = clock
        self.cache = cache
        self.state = cache.load(now: clock()) ?? .notStarted
    }

    // MARK: Lifecycle

    /// Loads prices, evaluates entitlements and listens for transaction updates
    /// (refunds, Ask to Buy approvals, purchases on other devices).
    func start() {
        guard updatesTask == nil else { return }
        #if DEBUG
        if let forced = Self.debugAccessOverride(ProcessInfo.processInfo.arguments, now: clock()) {
            apply(forced)
            return
        }
        #endif
        updatesTask = Task { [weak self] in
            await self?.loadProducts()
            await self?.refresh()
            for await _ in Transaction.updates {
                await self?.refresh()
            }
        }
    }

    // MARK: Queries

    func allows(_ feature: GatedFeature) -> Bool { state.allows(feature) }

    /// Whether every feature is unlocked (trial running or lifetime owned).
    var isPremium: Bool { state.hasFullAccess }

    // MARK: Actions

    func refresh() async {
        let history = await store.purchaseHistory()
        apply(AccessPolicy.evaluate(purchases: history, now: clock()))
    }

    func loadProducts() async {
        do {
            let prices = try await store.displayPrices(for: ProductCatalog.purchasable)
            lifetimePrice = prices[ProductCatalog.lifetime]
        } catch {
            errorMessage = String(localized: "Couldn't reach the App Store. Check your connection and try again.")
        }
    }

    func startTrial() async {
        guard state.canStartTrial else { return }
        await buy(ProductCatalog.trial)
    }

    func buyLifetime() async {
        await buy(ProductCatalog.lifetime)
    }

    func restore() async {
        errorMessage = nil
        do {
            try await store.sync()
        } catch {
            errorMessage = String(localized: "Couldn't restore purchases. Please try again.")
        }
        await refresh()
    }

    #if DEBUG
    /// UI tests and screenshots force a state without StoreKit:
    /// `-debugPremium` (lifetime) or `-uiTestAccess notStarted|trial|expired|lifetime`.
    static func debugAccessOverride(_ arguments: [String], now: Date) -> AccessState? {
        if arguments.contains("-debugPremium") { return .lifetime }
        guard let index = arguments.firstIndex(of: "-uiTestAccess"), index + 1 < arguments.count else { return nil }
        switch arguments[index + 1] {
        case "notStarted": return .notStarted
        case "trial": return .trial(daysRemaining: 30, endsAt: now.addingTimeInterval(ProductCatalog.trialLength))
        case "expired": return .expired
        case "lifetime": return .lifetime
        default: return nil
        }
    }
    #endif

    // MARK: Private

    private func buy(_ productID: String) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            switch try await store.purchase(productID: productID) {
            case .purchased:
                await refresh()
                HapticService.success()
            case .cancelled:
                break
            case .pending:
                errorMessage = String(localized: "Your purchase is waiting for approval. It will unlock automatically once approved.")
            }
        } catch {
            errorMessage = String(localized: "The purchase didn't go through. Please try again.")
        }
    }

    private func apply(_ newState: AccessState) {
        state = newState
        cache.save(newState)
    }
}

// MARK: - StoreKit Implementation

/// `StoreFront` backed by StoreKit 2.
struct StoreKitStoreFront: StoreFront {

    func purchaseHistory() async -> [PurchaseRecord] {
        var records: [PurchaseRecord] = []
        for await result in Transaction.all {
            guard case .verified(let transaction) = result else { continue }
            records.append(PurchaseRecord(
                productID: transaction.productID,
                purchaseDate: transaction.purchaseDate,
                isRevoked: transaction.revocationDate != nil
            ))
        }
        return records
    }

    func displayPrices(for productIDs: [String]) async throws -> [String: String] {
        let products = try await Product.products(for: productIDs)
        return Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0.displayPrice) })
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        guard let product = try await Product.products(for: [productID]).first else {
            throw StoreKitError.notAvailableInStorefront
        }
        switch try await product.purchase() {
        case .success(.verified(let transaction)):
            await transaction.finish()
            return .purchased
        case .success(.unverified):
            throw StoreKitError.unknown
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .cancelled
        }
    }

    func sync() async throws {
        try await AppStore.sync()
    }
}

// MARK: - Caches

/// Stores the last known state in `UserDefaults`, where ``PremiumManager``
/// reads it synchronously.
final class UserDefaultsAccessCache: AccessStateCaching {
    static let key = "cachedAccessState"
    private let defaults: UserDefaults
    private let key = UserDefaultsAccessCache.key

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(now: Date) -> AccessState? {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(AccessSnapshot.self, from: data)
        else { return nil }
        return snapshot.state(now: now)
    }

    func save(_ state: AccessState) {
        let data = try? JSONEncoder().encode(AccessSnapshot(state))
        defaults.set(data, forKey: key)
    }
}

/// Volatile cache for tests and previews.
final class InMemoryAccessCache: AccessStateCaching {
    private var snapshot: AccessSnapshot?

    func load(now: Date) -> AccessState? { snapshot?.state(now: now) }
    func save(_ state: AccessState) { snapshot = AccessSnapshot(state) }
}

/// Codable form of ``AccessState``. Trial snapshots re-derive the days left
/// from their end date so a stale cache never over-grants access.
struct AccessSnapshot: Codable, Equatable {
    enum Kind: String, Codable { case notStarted, trial, lifetime, expired }

    let kind: Kind
    let trialEndsAt: Date?

    init(_ state: AccessState) {
        switch state {
        case .notStarted: kind = .notStarted; trialEndsAt = nil
        case .trial(_, let endsAt): kind = .trial; trialEndsAt = endsAt
        case .lifetime: kind = .lifetime; trialEndsAt = nil
        case .expired: kind = .expired; trialEndsAt = nil
        }
    }

    func state(now: Date) -> AccessState {
        switch kind {
        case .notStarted: return .notStarted
        case .lifetime: return .lifetime
        case .expired: return .expired
        case .trial:
            guard let trialEndsAt, now < trialEndsAt else { return .expired }
            let days = Int((trialEndsAt.timeIntervalSince(now) / 86_400).rounded(.up))
            return .trial(daysRemaining: days, endsAt: trialEndsAt)
        }
    }
}
