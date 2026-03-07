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

    var body: some View {
        VStack(spacing: Brand.sectionSpacing) {
            Spacer()

            // Icon
            Image(systemName: reason.icon)
                .font(.system(size: 56, design: .rounded))
                .foregroundStyle(Brand.primary)
                .padding(.bottom, 4)

            // Title
            Text(reason.title)
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)

            // Message
            Text(reason.message)
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Premium features list
            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "infinity", text: "Unlimited children & artworks")
                featureRow(icon: "arrow.triangle.2.circlepath", text: "Cloud Backup & Sync")
                featureRow(icon: "sparkles", text: "AI-Powered Captions")
                featureRow(icon: "doc.richtext", text: "PDF Portfolio Export")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusCard)
                    .fill(Brand.surface)
            )
            .padding(.horizontal, 32)

            Spacer()

            // Purchase buttons
            VStack(spacing: 12) {
                // Yearly (best value)
                if let yearly = store.yearlyProduct {
                    Button {
                        Task { await store.purchase(yearly) }
                    } label: {
                        VStack(spacing: 4) {
                            Text("Yearly — \(yearly.displayPrice)")
                                .font(Brand.headlineFont)
                            Text(savingsText)
                                .font(Brand.caption2Font)
                                .opacity(0.8)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Brand.buttonPadding)
                        .background(Brand.primary)
                        .clipShape(Capsule())
                    }
                    .disabled(store.isPurchasing)
                    .padding(.horizontal, 32)
                }

                // Monthly
                if let monthly = store.monthlyProduct {
                    Button {
                        Task { await store.purchase(monthly) }
                    } label: {
                        Text("Monthly — \(monthly.displayPrice)")
                            .font(Brand.subheadlineFont.weight(.semibold))
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .strokeBorder(Brand.primary, lineWidth: 1.5)
                            )
                    }
                    .disabled(store.isPurchasing)
                    .padding(.horizontal, 32)
                }

                // Fallback if products haven't loaded
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
                        .padding(.horizontal, 32)
                }

                // Restore + dismiss
                HStack(spacing: 24) {
                    Button("Restore") {
                        Task { await store.restorePurchases() }
                    }
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)

                    Button("Not Now") {
                        dismiss()
                    }
                    .font(Brand.captionFont)
                    .foregroundStyle(Brand.warmGray)
                }
                .padding(.top, 4)

                // Auto-renewal disclosure & legal links
                VStack(spacing: 6) {
                    Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in your Apple Account subscriptions settings.")
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
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
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

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Brand.primary)
                .frame(width: 28)

            Text(text)
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.charcoal)
        }
    }
}

// MARK: - Preview

#Preview("Children Limit") {
    PaywallView(reason: .children)
}

#Preview("Artwork Limit") {
    PaywallView(reason: .artworks)
}
