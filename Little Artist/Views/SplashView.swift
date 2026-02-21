//
//  SplashView.swift
//  Little Artist
//
//  Branded splash screen shown during app launch while Firebase
//  and SwiftData initialize. Displays the app logo with a gentle
//  fade-in animation before transitioning to the main interface.
//

import SwiftUI

/// Animated splash screen with the Little Artist logo.
///
/// Shows the app icon, name, and tagline with a staggered fade-in,
/// then calls ``onFinished`` after a brief delay so the parent can
/// transition to the real content.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            Brand.cream
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // App icon — paint palette with colourful accent
                ZStack {
                    Circle()
                        .fill(Brand.primary.opacity(0.12))
                        .frame(width: 130, height: 130)

                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 60))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Brand.primary, Brand.sky, Brand.sage)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // App name
                VStack(spacing: 6) {
                    Text("Little Artist")
                        .font(Brand.displayFont)
                        .foregroundStyle(Brand.charcoal)
                        .opacity(textOpacity)

                    Text("Celebrate every masterpiece")
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.warmGray)
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            // Staggered entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                taglineOpacity = 1
            }

            // Dismiss after animations complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                onFinished()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(onFinished: {})
}
