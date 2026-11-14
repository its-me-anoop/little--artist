//
//  StoreKitManagerTests.swift
//  Little ArtistTests
//
//  Behaviour of the store manager with StoreKit replaced by fakes.
//

import Foundation
import Testing
@testable import Little_Artist

// MARK: - Fakes

final class FakeStoreFront: StoreFront, @unchecked Sendable {
    var history: [PurchaseRecord] = []
    var prices: [String: String] = [ProductCatalog.lifetime: "£14.99", ProductCatalog.trial: "Free"]
    var nextOutcome: PurchaseOutcome = .purchased
    var now: Date
    private(set) var purchasedIDs: [String] = []
    private(set) var syncCount = 0

    init(now: Date) { self.now = now }

    func purchaseHistory() async -> [PurchaseRecord] { history }

    func displayPrices(for productIDs: [String]) async throws -> [String: String] {
        prices.filter { productIDs.contains($0.key) }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        purchasedIDs.append(productID)
        if nextOutcome == .purchased {
            history.append(PurchaseRecord(productID: productID, purchaseDate: now, isRevoked: false))
        }
        return nextOutcome
    }

    func sync() async throws { syncCount += 1 }
}

// MARK: - Tests

@MainActor
struct StoreKitManagerTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeService(_ store: FakeStoreFront) -> StoreKitManager {
        let fixed = now
        return StoreKitManager(store: store, clock: { fixed }, cache: InMemoryAccessCache())
    }

    @Test("Refresh derives state from purchase history")
    func refreshDerivesState() async {
        let store = FakeStoreFront(now: now)
        store.history = [PurchaseRecord(productID: ProductCatalog.lifetime, purchaseDate: now, isRevoked: false)]
        let service = makeService(store)

        await service.refresh()

        #expect(service.state == .lifetime)
    }

    @Test("Starting the trial buys the $0 product and unlocks everything")
    func startTrial() async {
        let store = FakeStoreFront(now: now)
        let service = makeService(store)
        await service.refresh()
        #expect(service.state == .notStarted)

        await service.startTrial()

        #expect(store.purchasedIDs == [ProductCatalog.trial])
        #expect(service.state.hasFullAccess)
        #expect(service.errorMessage == nil)
    }

    @Test("A trial is never started twice")
    func trialNotRestarted() async {
        let store = FakeStoreFront(now: now)
        store.history = [PurchaseRecord(productID: ProductCatalog.trial, purchaseDate: now.addingTimeInterval(-40 * 86_400), isRevoked: false)]
        let service = makeService(store)
        await service.refresh()

        await service.startTrial()

        #expect(store.purchasedIDs.isEmpty)
        #expect(service.state == .expired)
    }

    @Test("Buying lifetime unlocks permanently")
    func buyLifetime() async {
        let store = FakeStoreFront(now: now)
        let service = makeService(store)

        await service.buyLifetime()

        #expect(store.purchasedIDs == [ProductCatalog.lifetime])
        #expect(service.state == .lifetime)
        #expect(service.isPremium)
    }

    @Test("Cancelling a purchase leaves state unchanged without an error")
    func cancelledPurchase() async {
        let store = FakeStoreFront(now: now)
        store.nextOutcome = .cancelled
        let service = makeService(store)
        await service.refresh()

        await service.buyLifetime()

        #expect(service.state == .notStarted)
        #expect(service.errorMessage == nil)
        #expect(service.isPurchasing == false)
    }

    @Test("Pending purchases explain that approval is needed")
    func pendingPurchase() async {
        let store = FakeStoreFront(now: now)
        store.nextOutcome = .pending
        let service = makeService(store)

        await service.buyLifetime()

        #expect(service.errorMessage != nil)
    }

    @Test("Restore syncs with the App Store and re-evaluates")
    func restore() async {
        let store = FakeStoreFront(now: now)
        let service = makeService(store)
        store.history = [PurchaseRecord(productID: "com.flutterly.littleartist.premium.yearly", purchaseDate: now, isRevoked: false)]

        await service.restore()

        #expect(store.syncCount == 1)
        #expect(service.state == .lifetime)
    }

    @Test("Prices are loaded for the paywall")
    func loadsPrices() async {
        let store = FakeStoreFront(now: now)
        let service = makeService(store)

        await service.loadProducts()

        #expect(service.lifetimePrice == "£14.99")
    }

    @Test("The last known state is cached so gating works before StoreKit answers")
    func cachesState() async {
        let store = FakeStoreFront(now: now)
        store.history = [PurchaseRecord(productID: ProductCatalog.lifetime, purchaseDate: now, isRevoked: false)]
        let cache = InMemoryAccessCache()
        let fixed = now
        let first = StoreKitManager(store: store, clock: { fixed }, cache: cache)
        await first.refresh()

        let second = StoreKitManager(store: FakeStoreFront(now: now), clock: { fixed }, cache: cache)

        #expect(second.state == .lifetime)
    }
}
