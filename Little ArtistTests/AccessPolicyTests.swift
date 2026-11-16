//
//  AccessPolicyTests.swift
//  Little ArtistTests
//
//  Specifies how purchases map to access: a 30-day free trial started by a
//  $0 in-app purchase, a one-time lifetime unlock, and grandfathered access
//  for anyone who ever bought the old subscriptions.
//

import Foundation
import Testing
@testable import Little_Artist

struct AccessPolicyTests {

    private let start = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    private func record(_ id: String, at date: Date, revoked: Bool = false) -> PurchaseRecord {
        PurchaseRecord(productID: id, purchaseDate: date, isRevoked: revoked)
    }

    // MARK: - No purchases

    @Test("No purchases means the trial has not started")
    func noPurchasesIsNotStarted() {
        let state = AccessPolicy.evaluate(purchases: [], now: start)
        #expect(state == .notStarted)
        #expect(state.hasFullAccess == false)
    }

    // MARK: - Trial

    @Test("Trial grants full access on day one with 30 days remaining")
    func trialDayOne() {
        let state = AccessPolicy.evaluate(
            purchases: [record(ProductCatalog.trial, at: start)],
            now: start.addingTimeInterval(60)
        )
        #expect(state == .trial(daysRemaining: 30, endsAt: start.addingTimeInterval(30 * day)))
        #expect(state.hasFullAccess)
    }

    @Test("Trial counts remaining days rounding partial days up")
    func trialRemainingDaysRoundUp() {
        let now = start.addingTimeInterval(29 * day + 3_600)
        let state = AccessPolicy.evaluate(purchases: [record(ProductCatalog.trial, at: start)], now: now)
        #expect(state == .trial(daysRemaining: 1, endsAt: start.addingTimeInterval(30 * day)))
    }

    @Test("Trial expires exactly 30 days after it started")
    func trialExpires() {
        let state = AccessPolicy.evaluate(
            purchases: [record(ProductCatalog.trial, at: start)],
            now: start.addingTimeInterval(30 * day)
        )
        #expect(state == .expired)
        #expect(state.hasFullAccess == false)
    }

    @Test("A refunded trial record is ignored")
    func revokedTrialIgnored() {
        let state = AccessPolicy.evaluate(
            purchases: [record(ProductCatalog.trial, at: start, revoked: true)],
            now: start
        )
        #expect(state == .notStarted)
    }

    @Test("The earliest trial record wins so reinstalling cannot restart the trial")
    func earliestTrialWins() {
        let state = AccessPolicy.evaluate(
            purchases: [
                record(ProductCatalog.trial, at: start.addingTimeInterval(40 * day)),
                record(ProductCatalog.trial, at: start)
            ],
            now: start.addingTimeInterval(41 * day)
        )
        #expect(state == .expired)
    }

    // MARK: - Lifetime

    @Test("Lifetime purchase grants permanent access")
    func lifetimeAccess() {
        let state = AccessPolicy.evaluate(
            purchases: [record(ProductCatalog.lifetime, at: start)],
            now: start.addingTimeInterval(5_000 * day)
        )
        #expect(state == .lifetime)
        #expect(state.hasFullAccess)
    }

    @Test("Lifetime beats an expired trial")
    func lifetimeBeatsExpiredTrial() {
        let state = AccessPolicy.evaluate(
            purchases: [
                record(ProductCatalog.trial, at: start),
                record(ProductCatalog.lifetime, at: start.addingTimeInterval(45 * day))
            ],
            now: start.addingTimeInterval(60 * day)
        )
        #expect(state == .lifetime)
    }

    @Test("A refunded lifetime purchase does not grant access")
    func refundedLifetime() {
        let state = AccessPolicy.evaluate(
            purchases: [record(ProductCatalog.lifetime, at: start, revoked: true)],
            now: start
        )
        #expect(state == .notStarted)
    }

    // MARK: - Legacy subscribers

    @Test("Anyone who bought a retired product is grandfathered to lifetime", arguments: ProductCatalog.legacyProducts)
    func legacySubscriberGrandfathered(productID: String) {
        let state = AccessPolicy.evaluate(
            purchases: [record(productID, at: start)],
            now: start.addingTimeInterval(800 * day)
        )
        #expect(state == .lifetime)
    }

    @Test("Unknown products are ignored")
    func unknownProductIgnored() {
        let state = AccessPolicy.evaluate(purchases: [record("com.example.other", at: start)], now: start)
        #expect(state == .notStarted)
    }

    // MARK: - Feature gating

    @Test("Creating content requires full access")
    func gating() {
        let endsAt = start.addingTimeInterval(30 * day)
        for feature in GatedFeature.allCases {
            #expect(AccessState.lifetime.allows(feature))
            #expect(AccessState.trial(daysRemaining: 3, endsAt: endsAt).allows(feature))
            #expect(AccessState.notStarted.allows(feature) == false)
            #expect(AccessState.expired.allows(feature) == false)
        }
    }

    @Test("Trial can only be offered before it has been used")
    func canStartTrial() {
        #expect(AccessState.notStarted.canStartTrial)
        #expect(AccessState.expired.canStartTrial == false)
        #expect(AccessState.lifetime.canStartTrial == false)
        #expect(AccessState.trial(daysRemaining: 2, endsAt: start).canStartTrial == false)
    }
}
