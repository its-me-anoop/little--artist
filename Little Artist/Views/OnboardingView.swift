//
//  OnboardingView.swift
//  Little Artist
//
//  A five-page onboarding carousel introducing the app's key features.
//  Each page uses a unique card entrance animation for visual delight.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI

/// A five-page onboarding carousel presented on first launch.
///
/// Each page highlights a key feature of the app (artwork capture, AI captions,
/// voice notes, sharing) with a unique card entrance animation. The user can
/// swipe between pages, skip onboarding, or tap "Get Started" on the last page.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let accentColor = Color.orange

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icons: ["paintpalette.fill", "figure.child", "scribble.variable"],
            titleTop: "Preserve the",
            titleHighlight: "Magic",
            description: "Never lose a precious drawing again. Digitally archive and share your child's masterpieces in one safe place.",
            animation: .drift
        ),
        OnboardingPage(
            icons: ["camera.fill", "photo.stack", "rectangle.portrait.on.rectangle.portrait.angled.fill"],
            titleTop: "Capture Every",
            titleHighlight: "Creation",
            description: "Snap photos of drawings, paintings, and crafts. Build a beautiful gallery of your child's creativity over time.",
            animation: .fan
        ),
        OnboardingPage(
            icons: ["sparkles", "text.quote", "wand.and.stars"],
            titleTop: "AI-Powered",
            titleHighlight: "Captions",
            description: "Let AI generate fun titles and captions for each artwork, capturing the magic and story behind every creation.",
            animation: .drop
        ),
        OnboardingPage(
            icons: ["mic.fill", "waveform", "play.circle.fill"],
            titleTop: "Add Voice",
            titleHighlight: "Notes",
            description: "Let your child record a voice note describing their artwork. Preserve their words and imagination forever.",
            animation: .pulse
        ),
        OnboardingPage(
            icons: ["square.and.arrow.up.fill", "heart.fill", "person.2.fill"],
            titleTop: "Share &",
            titleHighlight: "Celebrate",
            description: "Share artwork with family and friends. Let everyone celebrate your little artist's wonderful creations.",
            animation: .scatter
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top illustration area with Skip
            ZStack(alignment: .topTrailing) {
                // Soft background blob
                RoundedRectangle(cornerRadius: 40)
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.08), accentColor.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 340)
                    .padding(.horizontal, 16)

                // Illustration cards
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        AnimatedCardsView(
                            icons: page.icons,
                            accentColor: accentColor,
                            style: page.animation,
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                // Skip button
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(accentColor)
                    .padding(.trailing, 36)
                    .padding(.top, 16)
                }
            }

            Spacer().frame(height: 36)

            // Title
            VStack(spacing: 4) {
                Text(pages[currentPage].titleTop)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)

                Text(pages[currentPage].titleHighlight)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(accentColor)
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Spacer().frame(height: 16)

            // Description
            Text(pages[currentPage].description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.3), value: currentPage)

            Spacer()

            // Page indicators
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? accentColor : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // Action button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasCompletedOnboarding = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(accentColor)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
