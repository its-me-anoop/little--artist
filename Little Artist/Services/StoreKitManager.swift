//
//  StoreKitManager.swift
//  Little Artist
//
//  Manages StoreKit 2 subscriptions for Little Artist Premium.
//  Handles product loading, purchasing, and entitlement verification.
//

import StoreKit
import SwiftUI
import Observation

/// Manages StoreKit 2 product fetching, purchasing, and subscription status.
@MainActor
@Observable
final class StoreKitManager {

    /// Singleton shared instance.
    static let shared = StoreKitManager()

    /// Product identifiers configured in App Store Connect.
    enum ProductID {
        static let monthlyPremium = "com.flutterly.littleartist.premium.monthly"
        static let yearlyPremium = "com.flutterly.littleartist.premium.yearly"
        static let lifetimePremium = "com.flutterly.littleartist.premium.lifetime"

        static let all: [String] = [monthlyPremium, yearlyPremium, lifetimePremium]
    }

    /// Available subscription products fetched from the App Store.
    private(set) var products: [Product] = []

    /// Whether the user currently has an active premium subscription.
    private(set) var isPremium: Bool = false

    /// Whether a purchase is currently in progress.
    private(set) var isPurchasing: Bool = false

    /// Most recent error message for UI display.
    var errorMessage: String?

    /// Listener for transaction updates (renewals, refunds, etc.).
    private var transactionListener: Task<Void, Never>?

    // MARK: - Lifecycle

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    // MARK: - Products

    /// Fetches available subscription products from the App Store.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProductID.all)
            products = storeProducts.sorted { $0.price < $1.price }
            await updateIntroOfferEligibility()
        } catch {
            errorMessage = "Unable to load subscription options."
        }
    }

    /// Returns the monthly product, if loaded.
    var monthlyProduct: Product? {
        products.first { $0.id == ProductID.monthlyPremium }
    }

    /// Returns the yearly product, if loaded.
    var yearlyProduct: Product? {
        products.first { $0.id == ProductID.yearlyPremium }
    }

    /// Returns the lifetime (one-time purchase) product, if loaded.
    var lifetimeProduct: Product? {
        products.first { $0.id == ProductID.lifetimePremium }
    }

    // MARK: - Free Trial

    /// Whether this Apple Account can still claim the subscription group's
    /// introductory offer (Apple allows one per group, ever).
    private(set) var isEligibleForIntroOffer = false

    /// The free-trial offer on a subscription, if one is configured in
    /// App Store Connect and this account is still eligible for it.
    func freeTrial(for product: Product?) -> Product.SubscriptionOffer? {
        guard isEligibleForIntroOffer,
              let offer = product?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer
    }

    /// Trial length as (count, unit), with weeks expressed in days.
    private static func trialLength(_ offer: Product.SubscriptionOffer) -> (Int, String) {
        let count = offer.period.value * max(offer.periodCount, 1)
        switch offer.period.unit {
        case .day: return (count, "day")
        case .week: return (count * 7, "day")
        case .month: return (count, "month")
        case .year: return (count, "year")
        @unknown default: return (count, "day")
        }
    }

    /// A compact label like "7-day" for buttons and badges.
    static func trialLengthLabel(_ offer: Product.SubscriptionOffer) -> String {
        let (count, unit) = trialLength(offer)
        return "\(count)-\(unit)"
    }

    /// A phrase like "7 days" or "1 month" for disclosure text.
    static func trialDurationText(_ offer: Product.SubscriptionOffer) -> String {
        let (count, unit) = trialLength(offer)
        return "\(count) \(unit)\(count == 1 ? "" : "s")"
    }

    /// Refreshes intro-offer eligibility from the App Store.
    private func updateIntroOfferEligibility() async {
        guard let subscription = yearlyProduct?.subscription ?? monthlyProduct?.subscription else {
            isEligibleForIntroOffer = false
            return
        }
        isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
    }

    // MARK: - Purchase

    /// Initiates a purchase for the given product.
    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
                HapticService.success()

            case .userCancelled:
                break

            case .pending:
                errorMessage = "Purchase is pending approval."

            @unknown default:
                errorMessage = "An unexpected error occurred."
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }

        isPurchasing = false
    }

    // MARK: - Restore

    /// Restores previously purchased subscriptions.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            HapticService.success()
        } catch {
            errorMessage = "Unable to restore purchases."
        }
    }

    // MARK: - Subscription Status

    /// Checks current entitlements and updates `isPremium`.
    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.revocationDate == nil,
               ProductID.all.contains(transaction.productID) {
                hasActiveSubscription = true
            }
        }

        isPremium = hasActiveSubscription
        UserDefaults.standard.set(hasActiveSubscription, forKey: "isPremium")
        await updateIntroOfferEligibility()
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates in the background (renewals, refunds, revocations).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result) {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    /// Unwraps a verified transaction or throws if unverified.
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case unverified
    }
}
