//
//  OnboardingView.swift
//  Little Artist
//
//  A five-page onboarding carousel introducing the app's key features.
//  Each page uses a unique card entrance animation for visual delight.
//  On iPad (regular width), switches to a side-by-side layout with
//  scaled-up animations on the left and text/controls on the right.
//
//  Created by Anoop Jose on 13/02/2026.
//

import SwiftUI
import SwiftData

/// A five-page onboarding carousel presented on first launch.
///
/// Each page highlights a key feature of the app (artwork capture, AI captions,
/// voice notes, sharing) with a unique card entrance animation. The user can
/// swipe between pages, skip onboarding, or tap "Get Started" on the last page.
/// On iPad, renders a side-by-side layout with enlarged card animations.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query private var children: [Child]
    @State private var currentPage = 0
    @State private var showAddChild = false

    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

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

    // MARK: - Shared Subviews

    private var skipButton: some View {
        Group {
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
                .font(Brand.subheadlineFont)
                .foregroundStyle(Brand.primary)
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text(pages[currentPage].titleTop)
                .font(Brand.displayFont)
                .foregroundStyle(.primary)

            Text(pages[currentPage].titleHighlight)
                .font(Brand.displayFont)
                .foregroundStyle(Brand.primary)
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    private var descriptionSection: some View {
        Text(pages[currentPage].description)
            .font(Brand.subheadlineFont)
            .foregroundStyle(.secondary)
            .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    private var pageIndicators: some View {
        HStack(spacing: 6) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Brand.primary : Brand.warmGray.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            impactFeedback.impactOccurred()
            withAnimation(.easeInOut(duration: 0.3)) {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else if children.isEmpty {
                    showAddChild = true
                } else {
                    hasCompletedOnboarding = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(Brand.headlineFont)
                if currentPage < pages.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(Brand.headlineFont)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Brand.primary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .background(Color(.systemBackground))
        .onChange(of: currentPage) { _, _ in
            selectionFeedback.selectionChanged()
        }
        .sheet(isPresented: $showAddChild, onDismiss: {
            hasCompletedOnboarding = true
        }) {
            AddChildView()
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 40)
                    .fill(.ultraThinMaterial)
                    .frame(height: 340)
                    .padding(.horizontal, 16)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        AnimatedCardsView(
                            icons: page.icons,
                            accentColor: Brand.primary,
                            style: page.animation,
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                skipButton
                    .padding(.trailing, 36)
                    .padding(.top, 16)
            }

            Spacer().frame(height: 36)

            titleSection
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            descriptionSection
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            pageIndicators
                .padding(.bottom, 24)

            actionButton
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left pane — scaled card animations
            ZStack {
                RoundedRectangle(cornerRadius: Brand.radiusOnboarding)
                    .fill(.ultraThinMaterial)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        AnimatedCardsView(
                            icons: page.icons,
                            accentColor: Brand.primary,
                            style: page.animation,
                            isActive: currentPage == index
                        )
                        .scaleEffect(Brand.Adaptive.onboardingCardScale(for: sizeClass))
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Right pane — text & controls
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    skipButton
                        .padding(.trailing, 36)
                        .padding(.top, 24)
                }

                Spacer()

                titleSection
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 20)

                descriptionSection
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 40)

                pageIndicators
                    .padding(.horizontal, 40)

                Spacer()

                actionButton
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
