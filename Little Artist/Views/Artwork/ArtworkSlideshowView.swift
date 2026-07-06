//
//  ArtworkSlideshowView.swift
//  Little Artist
//
//  Full-screen auto-advancing slideshow — an "exhibition mode" for
//  showing off the gallery at family gatherings.
//

import SwiftUI

/// Plays through artworks full-screen with gentle crossfades and a
/// subtle Ken Burns zoom. Tap toggles the controls; auto-advances
/// every few seconds while playing.
struct ArtworkSlideshowView: View {
    /// Artworks to present, in display order.
    let artworks: [Artwork]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var isPlaying = true
    @State private var showControls = true

    /// Seconds each slide stays on screen while playing.
    private static let slideSeconds = 5

    private var currentArtwork: Artwork? {
        artworks.indices.contains(index) ? artworks[index] : nil
    }

    var body: some View {
        ZStack {
            Brand.charcoal.ignoresSafeArea()

            if let artwork = currentArtwork,
               let data = artwork.imageData,
               let image = UIImage(data: data) {
                SlideImageView(image: image, animateZoom: !reduceMotion)
                    .id(index)
                    .transition(.opacity)
            }

            controlsOverlay
                .opacity(showControls ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .task(id: advanceTaskKey) {
            guard isPlaying, artworks.count > 1 else { return }
            try? await Task.sleep(for: .seconds(Self.slideSeconds))
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.8)) {
                index = (index + 1) % artworks.count
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    /// Restarts the advance timer whenever the slide or play state changes.
    private var advanceTaskKey: String {
        "\(index)-\(isPlaying)"
    }

    // MARK: - Controls

    private var controlsOverlay: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Brand.cream.opacity(0.85))
                }
                .accessibilityLabel("Close slideshow")

                Spacer()

                Button {
                    isPlaying.toggle()
                    HapticService.light()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Brand.cream.opacity(0.85))
                }
                .accessibilityLabel(isPlaying ? "Pause slideshow" : "Play slideshow")
            }
            .padding(.horizontal, Brand.screenPadding)
            .padding(.top, 8)

            Spacer()

            if let artwork = currentArtwork {
                VStack(spacing: 4) {
                    if !artwork.title.isEmpty {
                        Text(artwork.title)
                            .font(Brand.title2Font)
                            .foregroundStyle(Brand.cream)
                            .multilineTextAlignment(.center)
                    }

                    Text(slideCaption(for: artwork))
                        .font(Brand.captionFont)
                        .foregroundStyle(Brand.cream.opacity(0.75))
                }
                .padding(.horizontal, Brand.formPadding)
                .padding(.bottom, 30)
            }
        }
    }

    private func slideCaption(for artwork: Artwork) -> String {
        let date = artwork.createdAt.formatted(date: .abbreviated, time: .omitted)
        if let name = artwork.child?.name, !name.isEmpty {
            return "\(name) · \(date)"
        }
        return date
    }
}

// MARK: - Slide Image

/// A single slide that owns its Ken Burns zoom state, so each new slide
/// starts the zoom fresh.
private struct SlideImageView: View {
    let image: UIImage
    let animateZoom: Bool

    @State private var zoomed = false

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .padding(Brand.screenPadding)
            .scaleEffect(zoomed ? 1.05 : 1.0)
            .onAppear {
                guard animateZoom else { return }
                withAnimation(.easeInOut(duration: 4.8)) {
                    zoomed = true
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ArtworkSlideshowView(artworks: [])
}
