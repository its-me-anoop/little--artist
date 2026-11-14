//
//  PaywallView.swift
//  Little Artist
//
//  Offers the free 30-day trial (before it has been used) and the one-time
//  lifetime unlock. Discloses the trial length, what locks afterwards and
//  the price before anything is bought, as App Review Guideline 3.1.1
//  requires. There are no subscriptions.
//

import SwiftUI

/// Modal sheet for starting the free trial or buying lifetime access.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    /// Why the paywall was shown.
    var reason: LimitReason = .upgrade

    private var store: StoreKitManager { StoreKitManager.shared }

    enum LimitReason: Identifiable {
        var id: Self { self }
        case children
        case artworks
        case upgrade
    }

    // MARK: - Copy

    private var headline: String {
        switch store.state {
        case .notStarted: String(localized: "Try everything free for 30 days")
        case .trial: String(localized: "Keep every masterpiece, forever")
        case .expired: String(localized: "Your free month has ended")
        case .lifetime: String(localized: "You own Little Artist")
        }
    }

    private var message: String {
        switch store.state {
        case .notStarted:
            String(localized: "Unlimited children and artwork for a month, free. Afterwards, pay once to keep adding. Nothing is ever charged automatically.")
        case .trial(let days, _):
            days == 1
                ? String(localized: "Your free trial ends tomorrow. Pay once and Little Artist is yours for life.")
                : String(localized: "\(days) days left in your free trial. Pay once and Little Artist is yours for life.")
        case .expired:
            String(localized: "Your artwork is safe and always viewable. Unlock once to keep adding new pieces and children.")
        case .lifetime:
            String(localized: "Thank you for supporting an independent developer.")
        }
    }

    private var lifetimePrice: String {
        store.lifetimePrice ?? String(localized: "a one-time price")
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Brand.sectionSpacing) {
                header
                heroSection
                benefitCards
                ctaSection
                statusSection
                legalSection
                restoreButton
            }
            .padding(.vertical, Brand.screenPadding)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(BrandAppBackground())
        .task { await store.loadProducts() }
        .onChange(of: store.state) { old, new in
            // Close once the user gains access from this sheet.
            if !old.hasFullAccess && new.hasFullAccess || new == .lifetime { dismiss() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(Brand.headlineFont)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            Image("LaunchFox")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)

            Text(headline)
                .font(Brand.title1Font)
                .foregroundStyle(Brand.charcoal)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Brand.formPadding)
    }

    // MARK: - Benefits

    private var benefitCards: some View {
        VStack(spacing: 12) {
            benefitCard(icon: "infinity", tint: Brand.primary,
                        title: "Unlimited children and artwork",
                        description: "Every little artist gets their own gallery")
            benefitCard(icon: "apple.intelligence", tint: Brand.lavender,
                        title: "Apple Intelligence captions",
                        description: "Playful titles written on your iPhone, privately")
            benefitCard(icon: "mic.fill", tint: Brand.sky,
                        title: "Voice memos and Siri",
                        description: "Keep their words, and just ask Siri to save art")
            benefitCard(icon: "icloud.fill", tint: Brand.sage,
                        title: "Private iCloud sync",
                        description: "On all your devices. No accounts, no ads")
        }
        .padding(.horizontal, Brand.screenPadding)
    }

    // MARK: - Call to Action

    @ViewBuilder
    private var ctaSection: some View {
        VStack(spacing: 10) {
            if store.state.canStartTrial {
                primaryButton(String(localized: "Start 30-Day Free Trial")) {
                    Task { await store.startTrial() }
                }
                Text("Free for 30 days, then \(lifetimePrice) once for lifetime access, only if you choose to buy it.")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
                    .multilineTextAlignment(.center)
                secondaryButton(String(localized: "Buy Lifetime Now · \(lifetimePrice)")) {
                    Task { await store.buyLifetime() }
                }
            } else if store.state != .lifetime {
                primaryButton(String(localized: "Unlock Lifetime · \(lifetimePrice)")) {
                    Task { await store.buyLifetime() }
                }
                Text("One payment. No subscription.")
                    .font(Brand.caption2Font)
                    .foregroundStyle(Brand.warmGray)
            }

            // The promise competitors break: art is never held hostage.
            Label("Your art stays yours. View and export it free, always.", systemImage: "lock.open.fill")
                .font(Brand.caption2Font.weight(.medium))
                .foregroundStyle(Brand.sage)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .disabled(store.isPurchasing)
        .padding(.horizontal, Brand.screenPadding)
    }

    @ViewBuilder
    private var statusSection: some View {
        if store.isPurchasing {
            ProgressView("Processing…")
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

    private var legalSection: some View {
        VStack(spacing: 6) {
            Text("The 30-day trial and the lifetime unlock are one-time in-app purchases. Nothing renews and nothing is charged automatically.")
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://www.flutterly.co.uk/projects/artling/privacy-policy")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
        }
        .font(Brand.caption2Font)
        .foregroundStyle(Brand.warmGray)
        .padding(.horizontal, Brand.formPadding)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await store.restore() }
        }
        .font(Brand.captionFont)
        .foregroundStyle(Brand.warmGray)
        .padding(.bottom, 8)
    }

    // MARK: - Buttons

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Brand.headlineFont)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Brand.buttonPadding)
                .background(Brand.primary, in: Capsule())
                .brandFABShadow()
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Brand.subheadlineFont.weight(.semibold))
                .foregroundStyle(Brand.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(Capsule().strokeBorder(Brand.primary, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
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
                .font(Brand.headlineFont)
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

#Preview {
    PaywallView(reason: .artworks)
}
