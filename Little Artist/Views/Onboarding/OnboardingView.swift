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
/// No sign-in required — data syncs to the user's private iCloud automatically.
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
            icons: ["crayon_palette", "crayon_child", "crayon_scribble"],
            titleTop: "Preserve the",
            titleHighlight: "Magic",
            description: "Never lose a precious drawing again. Digitally archive and share your child's masterpieces in one safe place.",
            animation: .drift,
            color: Brand.primary,
            videoName: "paint"
        ),
        OnboardingPage(
            icons: ["crayon_camera", "crayon_photos", "crayon_frame"],
            titleTop: "Capture Every",
            titleHighlight: "Creation",
            description: "Snap photos of drawings, paintings, and crafts. Build a beautiful gallery of your child's creativity over time.",
            animation: .fan,
            color: Brand.sage,
            videoName: "capture"
        ),
        OnboardingPage(
            icons: ["crayon_sparkles", "crayon_text", "crayon_wand"],
            titleTop: "AI-Powered",
            titleHighlight: "Captions",
            description: "Let AI generate fun titles and captions for each artwork, capturing the magic and story behind every creation.",
            animation: .drop,
            color: Brand.sky,
            videoName: "magic"
        ),
        OnboardingPage(
            icons: ["crayon_mic", "crayon_waveform", "crayon_play"],
            titleTop: "Add Voice",
            titleHighlight: "Notes",
            description: "Let your child record a voice note describing their artwork. Preserve their words and imagination forever.",
            animation: .pulse,
            color: Brand.lavender,
            videoName: "voice"
        ),
        OnboardingPage(
            icons: ["crayon_share", "crayon_heart", "crayon_people"],
            titleTop: "Share &",
            titleHighlight: "Celebrate",
            description: "Share artwork with family and friends. Let everyone celebrate your little artist's wonderful creations.",
            animation: .scatter,
            color: Brand.dustyRose,
            videoName: "share"
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
                .foregroundStyle(Brand.charcoal)
                .contentTransition(.numericText())
                .crayonStyle()

            Text(pages[currentPage].titleHighlight)
                .font(Brand.displayFont)
                .foregroundStyle(pages[currentPage].color)
                .contentTransition(.numericText())
                .crayonStyle()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
    }

    private var descriptionSection: some View {
        Text(pages[currentPage].description)
            .font(Brand.title3Font)
            .multilineTextAlignment(.center)
            .foregroundStyle(Brand.warmGray)
            .lineSpacing(4)
            .crayonStyle()
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? pages[currentPage].color : Brand.warmGray.opacity(0.2))
                    .frame(width: index == currentPage ? 12 : 8, height: index == currentPage ? 12 : 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentPage)
            }
        }
    }

    private var actionButton: some View {
        Button {
            impactFeedback.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    completeOnboarding()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .font(Brand.title2Font.bold())
                if currentPage < pages.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(Brand.title2Font.bold())
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(pages[currentPage].color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Brand.glassStrokeSoft, lineWidth: 3)
            )
            .shadow(color: pages[currentPage].color.opacity(0.4), radius: 12, x: 0, y: 6)
            .scaleEffect(currentPage < pages.count ? 1.0 : 0.95)
            .crayonStyle()
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentPage)
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
        .background(animatedBackground)
        .onChange(of: currentPage) { _, _ in
            selectionFeedback.selectionChanged()
        }
        .sheet(isPresented: $showAddChild, onDismiss: {
            hasCompletedOnboarding = true
        }) {
            AddChildView()
        }
    }

    private var animatedBackground: some View {
        ZStack {
            BrandAppBackground()
            
            GeometryReader { geo in
                Circle()
                    .fill(pages[currentPage].color.opacity(0.15))
                    .frame(width: geo.size.width * 1.5, height: geo.size.width * 1.5)
                    .blur(radius: 60)
                    .offset(x: currentPage % 2 == 0 ? -geo.size.width/4 : geo.size.width/4,
                            y: currentPage % 3 == 0 ? -geo.size.height/4 : geo.size.height/4)
                    .animation(.easeInOut(duration: 1.5), value: currentPage)
                
                Circle()
                    .fill(pages[currentPage].color.opacity(0.10))
                    .frame(width: geo.size.width * 1.2, height: geo.size.width * 1.2)
                    .blur(radius: 80)
                    .offset(x: currentPage % 2 == 0 ? geo.size.width/3 : -geo.size.width/3,
                            y: currentPage % 3 == 0 ? geo.size.height/3 : -geo.size.height/3)
                    .animation(.easeInOut(duration: 2.0), value: currentPage)
            }
            .ignoresSafeArea()
        }
    }

    private var iPhoneLayout: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 0) {
                        OnboardingVideoView(
                            videoName: page.videoName,
                            isActive: currentPage == index
                        )
                        .aspectRatio(1.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(page.color.opacity(0.3), lineWidth: 3)
                        )
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 48)

                        titleSection
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 24)

                        descriptionSection
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            skipButton
                .padding(.trailing, 36)
                .padding(.top, 16)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 24) {
                pageIndicators
                    .padding(.top, 8)
                
                actionButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - iPad Layout

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Left pane — video
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingVideoView(
                        videoName: page.videoName,
                        isActive: currentPage == index
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(pages[currentPage].color.opacity(0.3), lineWidth: 3)
            )
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

    @MainActor
    private func completeOnboarding() {
        if children.isEmpty {
            showAddChild = true
        } else {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
