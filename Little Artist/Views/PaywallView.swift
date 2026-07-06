//
//  PaywallView.swift
//  Little Artist
//
//  Shown when users hit free tier limits.
//  Integrates with StoreKitManager for real purchases.
//

import SwiftUI
import StoreKit

/// A modal paywall shown when a free tier limit is reached.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    /// Describes which limit was hit.
    let reason: LimitReason

    private var store: StoreKitManager { StoreKitManager.shared }

    /// Dynamically calculated savings text based on live product prices.
    private var savingsText: String {
        guard let monthly = store.monthlyProduct,
              let yearly = store.yearlyProduct else {
            return "Best value"
        }
        let annualMonthly = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        guard annualMonthly > 0 else { return "Best value" }
        let savings = ((annualMonthly - yearlyPrice) / annualMonthly * 100).rounded(.down)
        return "Best value — save \(Int(savings))%"
    }

    enum LimitReason: Identifiable {
        var id: Self { self }
        case children
        case artworks

        var title: String {
            "Unlock Premium Features"
        }

        var message: String {
            switch self {
            case .children:
                return "Add unlimited child profiles, cloud sync, AI captions, and more with Artling Premium."
            case .artworks:
                return "Save unlimited artworks, sync across devices, and unlock AI-powered captions with Artling Premium."
            }
        }

        var icon: String {
            "sparkles"
        }
    }

    /// The purchase plans offered on the paywall.
    enum Plan {
        case monthly
        case yearly
        case lifetime
    }

    /// The currently selected plan.
    @State private var selectedPlan: Plan = .yearly

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                // MARK: Header
                header

                // MARK: Hero
                heroSection

                // MARK: Benefits
                benefitCards

                // MARK: Subscription Tiers
                subscriptionTiers

                // MARK: CTA
                ctaButton

                // MARK: Loading / Error States
                statusSection

                // MARK: Legal
                legalSection

                // MARK: Restore
                restoreButton
            }
            .padding(.vertical, Brand.screenPadding)
        }
        .background(BrandAppBackground())
        .task(id: store.isPremium) {
            if store.isPremium {
                dismiss()
            }
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Brand.warmGray.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Brand.primary)

                Text("Little Artist Premium")
                    .font(Brand.headlineFont)
                    .foregroundStyle(Brand.primary)
            }

            Spacer()

            // Invisible spacer to balance close button
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Unlock Your Full Studio")
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)
                .multilineTextAlignment(.center)

            Text(reason.message)
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Brand.screenPadding)
        }
    }

    // MARK: - Benefit Cards

    private var benefitCards: some View {
        VStack(spacing: 12) {
            benefitCard(
                icon: "person.3",
                tint: Brand.primary,
                title: "Unlimited Child Profiles",
                description: "Track every little artist in the family"
            )
            benefitCard(
                icon: "square.grid.2x2",
                tint: Brand.sky,
                title: "Unlimited Artworks",
                description: "Never run out of space for masterpieces"
            )
            benefitCard(
                icon: "cloud.fill",
                tint: Brand.lavender,
                title: "Cloud Backup & Sync",
                description: "Keep artwork safe across all your devices"
            )
            benefitCard(
                icon: "doc.text",
                tint: Brand.warmGray,
                title: "PDF Portfolio Export",
                description: "Create beautiful keepsake portfolios"
            )
            // Emphasized card for Voice Memo & AI
            benefitCard(
                icon: "mic.fill",
                tint: Brand.primary,
                title: "Voice Memo & AI",
                description: "Record stories and get AI-powered captions",
                emphasized: true
            )
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    // MARK: - Subscription Tiers

    private var subscriptionTiers: some View {
        VStack(spacing: 12) {
            // Yearly tier — highlighted with savings badge
            Button {
                selectedPlan = .yearly
                HapticService.selection()
            } label: {
                VStack(spacing: 0) {
                    // Best Value badge
                    Text(savingsText)
                        .font(Brand.caption2Font)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Brand.lavender, in: Capsule())
                        .offset(y: -2)

                    VStack(spacing: 4) {
                        Text("Yearly")
                            .font(Brand.headlineFont)
                            .foregroundStyle(Brand.charcoal)

                        Text(store.yearlyProduct?.displayPrice ?? "$34.99")
                            .font(Brand.title2Font)
                            .foregroundStyle(Brand.primary)

                        Text("per year")
                            .font(Brand.caption2Font)
                            .foregroundStyle(Brand.warmGray)
                    }
                    .padding(.vertical, Brand.buttonPadding)
                    .frame(maxWidth: .infinity)
                }
                .background(Brand.surface)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                        .strokeBorder(
                            selectedPlan == .yearly ? Brand.lavender : Brand.softTan,
                            lineWidth: selectedPlan == .yearly ? 2.5 : 1
                        )
                )
                .brandCardShadow()
            }
            .buttonStyle(.plain)

            // Monthly and Lifetime — side by side
            HStack(spacing: 12) {
                compactTierCard(
                    plan: .monthly,
                    name: "Monthly",
                    price: store.monthlyProduct?.displayPrice ?? "$4.99",
                    detail: "per month"
                )

                compactTierCard(
                    plan: .lifetime,
                    name: "Lifetime",
                    price: store.lifetimeProduct?.displayPrice ?? "$79.99",
                    detail: "pay once, forever"
                )
            }
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    /// A compact selectable tier card for the monthly and lifetime plans.
    private func compactTierCard(
        plan: Plan,
        name: String,
        price: String,
        detail: String
    ) -> some View {
        Button {
            selectedPlan = plan
            HapticService.selection()
        } label: {
            VStack(spacing: 4) {
                Text(name)
                    .font(Brand.headlineFont)
                    .foregroundStyle(Brand.charcoal)

                Text(price)
                    .font(Brand.title2Font)
                    .foregroundStyle(selectedPlan == plan ? Brand.primary : Brand.charcoal)

                Text(detail)
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }
            .padding(.vertical, Brand.buttonPadding)
            .frame(maxWidth: .infinity)
            .background(Brand.surface)
            .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                    .strokeBorder(
                        selectedPlan == plan ? Brand.primary : Brand.softTan,
                        lineWidth: selectedPlan == plan ? 2.5 : 1
                    )
            )
            .brandCardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Button

    /// The product matching the currently selected plan, if loaded.
    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly: return store.monthlyProduct
        case .yearly: return store.yearlyProduct
        case .lifetime: return store.lifetimeProduct
        }
    }

    private var ctaButton: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    if let product = selectedProduct {
                        await store.purchase(product)
                    }
                }
            } label: {
                Text(selectedPlan == .lifetime ? "Unlock Forever" : "Subscribe Now")
                    .font(Brand.headlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Brand.buttonPadding)
                    .background(Brand.primary)
                    .clipShape(Capsule())
                    .brandFABShadow()
            }
            .disabled(store.isPurchasing || store.products.isEmpty)

            Text("Cancel anytime · No hidden fees")
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        if store.products.isEmpty {
            ProgressView()
                .tint(Brand.primary)
                .padding(.vertical, 8)
        }

        if store.isPurchasing {
            ProgressView("Processing...")
                .font(Brand.captionFont)
                .tint(Brand.primary)
        }

        if let error = store.errorMessage {
            Text(error)
                .font(Brand.captionFont)
                .foregroundStyle(Brand.dustyRose)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Brand.formPadding)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 6) {
            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in your Apple Account subscriptions settings. Lifetime is a one-time purchase and never renews.")
                .font(Brand.caption2Font)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://www.flutterly.co.uk/projects/artling/privacy-policy")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(Brand.caption2Font)
            .foregroundStyle(Brand.warmGray)
        }
        .padding(.horizontal, Brand.formPadding)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("Restore Purchases")
                .font(Brand.captionFont)
                .foregroundStyle(Brand.warmGray)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Benefit Card Helper

    private func benefitCard(
        icon: String,
        tint: Color,
        title: String,
        description: String,
        emphasized: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            // Icon in tinted circle
            Image(systemName: icon)
                .font(.system(size: emphasized ? 18 : 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: emphasized ? 44 : 40, height: emphasized ? 44 : 40)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(emphasized ? Brand.headlineFont : Brand.subheadlineFont.weight(.semibold))
                    .foregroundStyle(Brand.charcoal)

                Text(description)
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
            }

            Spacer()
        }
        .padding(emphasized ? 16 : 14)
        .background(Brand.surface)
        .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Brand.radiusCard, style: .continuous)
                .strokeBorder(emphasized ? Brand.primary.opacity(0.3) : Brand.glassStroke, lineWidth: 1)
        )
        .brandCardShadow()
    }
}

// MARK: - Preview

#Preview("Children Limit") {
    PaywallView(reason: .children)
}

#Preview("Artwork Limit") {
    PaywallView(reason: .artworks)
}
