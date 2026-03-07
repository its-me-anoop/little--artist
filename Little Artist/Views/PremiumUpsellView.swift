//
//  PremiumUpsellView.swift
//  Little Artist
//
//  A one-time soft upsell shown after the user saves their very first artwork.
//  Celebratory and warm — not a hard gate.
//

import SwiftUI

/// A compact celebratory sheet nudging users toward premium after their first artwork.
struct PremiumUpsellView: View {
    @Environment(\.dismiss) private var dismiss
    private var store: StoreKitManager { StoreKitManager.shared }
    @State private var showPaywall = false

    private var paywallPresented: Binding<Bool> {
        Binding(
            get: { showPaywall && !store.isPremium },
            set: { showPaywall = $0 }
        )
    }

    var body: some View {
        VStack(spacing: Brand.sectionSpacing) {
            Spacer()

            // Celebration icon
            Image(systemName: "sparkles")
                .font(.system(size: 52, design: .rounded))
                .foregroundStyle(Brand.primary)

            // Title
            Text("Your first masterpiece!")
                .font(Brand.title2Font)
                .foregroundStyle(Brand.charcoal)

            // Subtitle
            Text("You're off to a great start")
                .font(Brand.bodyFont)
                .foregroundStyle(Brand.warmGray)

            // Premium feature highlights
            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "arrow.triangle.2.circlepath", text: "Cloud Backup & Sync")
                featureRow(icon: "infinity", text: "Unlimited Artwork Storage")
                featureRow(icon: "sparkles", text: "AI-Powered Captions")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: Brand.radiusCard)
                    .fill(Brand.surface)
            )
            .padding(.horizontal, 32)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    guard !store.isPremium else {
                        dismiss()
                        return
                    }
                    showPaywall = true
                } label: {
                    Text("See Plans")
                        .font(Brand.headlineFont)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Brand.buttonPadding)
                        .background(Brand.primary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)

                Button {
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 32)
        }
        .background(BrandAppBackground())
        .sheet(isPresented: paywallPresented) {
            PaywallView(reason: .artworks)
        }
        .task(id: store.isPremium) {
            if store.isPremium {
                showPaywall = false
                dismiss()
            }
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

#Preview {
    PremiumUpsellView()
}
