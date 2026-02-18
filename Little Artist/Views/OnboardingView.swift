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

// MARK: - Card Animation Styles

/// The entrance animation style applied to icon cards on each onboarding page.
enum CardAnimation {
    /// Cards drift up from below with staggered delays.
    case drift
    /// Cards fan outward from a central stack.
    case fan
    /// Cards drop in from above with a soft bounce.
    case drop
    /// Cards scale up from the centre like a heartbeat.
    case pulse
    /// Cards fly in from different screen edges.
    case scatter
}

// MARK: - Onboarding Page Data

/// Data describing a single page of the onboarding carousel.
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icons: [String]
    let titleTop: String
    let titleHighlight: String
    let description: String
    let animation: CardAnimation
}

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

// MARK: - Animation Dispatcher

/// Routes each onboarding page to its corresponding card entrance animation view.
struct AnimatedCardsView: View {
    let icons: [String]
    let accentColor: Color
    let style: CardAnimation
    let isActive: Bool

    var body: some View {
        switch style {
        case .drift:
            DriftCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .fan:
            FanCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .drop:
            DropCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .pulse:
            PulseCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        case .scatter:
            ScatterCardsView(icons: icons, accentColor: accentColor, isActive: isActive)
        }
    }
}

// MARK: - Shared Animation Trigger

/// A view modifier that resets animation state instantly and replays
/// the entrance animation when `isActive` becomes `true`.
private struct AnimationTrigger: ViewModifier {
    let isActive: Bool
    let onPlay: () -> Void
    let onReset: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    // Reset instantly, then play after a tick
                    onReset()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        onPlay()
                    }
                } else {
                    onReset()
                }
            }
            .onAppear {
                if isActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        onPlay()
                    }
                }
            }
    }
}

// MARK: - 1. Drift (Page 1: Preserve the Magic)
// Cards rise up from below, staggered, and settle into tilted positions

struct DriftCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : -8))
                .offset(x: -70, y: show[0] ? (floating ? 17 : 23) : 100)
                .scaleEffect(show[0] ? 1 : 0.7)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 6))
                .offset(x: 75, y: show[2] ? (floating ? -12 : -4) : 80)
                .scaleEffect(show[2] ? 1 : 0.7)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 120)
                .scaleEffect(show[1] ? 1 : 0.7)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.0).delay(0.1)) { show[1] = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.35)) { show[0] = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.6)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.8)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

// MARK: - 2. Fan (Page 2: Capture Every Creation)
// Cards start stacked on top of each other, then fan outward like a hand of cards

struct FanCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var fanned = false
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(fanned ? -20 : 0))
                .offset(
                    x: fanned ? -70 : 0,
                    y: fanned ? (floating ? 17 : 23) : 10
                )
                .opacity(fanned ? 1 : 0.6)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(fanned ? 18 : 0))
                .offset(
                    x: fanned ? 75 : 0,
                    y: fanned ? (floating ? -12 : -4) : 10
                )
                .opacity(fanned ? 1 : 0.6)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: floating ? 6 : 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) { fanned = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.6)) {
                floating = true
            }
        }, onReset: {
            fanned = false
            floating = false
        }))
    }
}

// MARK: - 3. Drop (Page 3: AI-Powered Captions)
// Cards drop in from the top of the visible area with a soft bounce on landing

struct DropCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : 5))
                .offset(x: -70, y: show[0] ? (floating ? 17 : 23) : -70)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : -5))
                .offset(x: 75, y: show[2] ? (floating ? -12 : -4) : -60)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : -80)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.1)) { show[1] = true }
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.4)) { show[0] = true }
            withAnimation(.spring(duration: 1.2, bounce: 0.35).delay(0.7)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

// MARK: - 4. Pulse (Page 4: Add Voice Notes)
// Cards scale up from tiny at center, one by one, like a heartbeat

struct PulseCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : 0))
                .offset(
                    x: show[0] ? -70 : 0,
                    y: show[0] ? (floating ? 17 : 23) : 10
                )
                .scaleEffect(show[0] ? 1 : 0.1)
                .opacity(show[0] ? 1 : 0)

            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 0))
                .offset(
                    x: show[2] ? 75 : 0,
                    y: show[2] ? (floating ? -12 : -4) : 10
                )
                .scaleEffect(show[2] ? 1 : 0.1)
                .opacity(show[2] ? 1 : 0)

            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 10)
                .scaleEffect(show[1] ? 1 : 0.1)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.1)) { show[1] = true }
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.45)) { show[0] = true }
            withAnimation(.spring(duration: 0.9, bounce: 0.35).delay(0.8)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

// MARK: - 5. Scatter (Page 5: Share & Celebrate)
// Cards fly in from three different edges — left, right, and bottom

struct ScatterCardsView: View {
    let icons: [String]
    let accentColor: Color
    let isActive: Bool

    @State private var show: [Bool] = [false, false, false]
    @State private var floating = false

    var body: some View {
        ZStack {
            // Enters from the left
            IconCard(icon: icons[0], size: 56, cardSize: 90, color: accentColor.opacity(0.7))
                .rotationEffect(.degrees(show[0] ? -15 : -30))
                .offset(
                    x: show[0] ? -70 : -200,
                    y: show[0] ? (floating ? 17 : 23) : 23
                )
                .opacity(show[0] ? 1 : 0)

            // Enters from the right
            IconCard(icon: icons[2], size: 48, cardSize: 80, color: accentColor.opacity(0.5))
                .rotationEffect(.degrees(show[2] ? 12 : 30))
                .offset(
                    x: show[2] ? 75 : 200,
                    y: show[2] ? (floating ? -12 : -4) : -4
                )
                .opacity(show[2] ? 1 : 0)

            // Enters from below
            IconCard(icon: icons[1], size: 64, cardSize: 110, color: accentColor)
                .offset(x: 0, y: show[1] ? (floating ? 6 : 14) : 180)
                .opacity(show[1] ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AnimationTrigger(isActive: isActive, onPlay: {
            withAnimation(.easeOut(duration: 1.1).delay(0.1)) { show[0] = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.4)) { show[1] = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.7)) { show[2] = true }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(2.0)) {
                floating = true
            }
        }, onReset: {
            show = [false, false, false]
            floating = false
        }))
    }
}

/// A single rounded card displaying an SF Symbol icon.
/// Used as the animated illustration element on each onboarding page.
struct IconCard: View {
    let icon: String
    let size: CGFloat
    let cardSize: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(color)
        }
        .frame(width: cardSize, height: cardSize)
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
