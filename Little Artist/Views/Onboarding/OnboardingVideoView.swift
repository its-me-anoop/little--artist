//
//  OnboardingVideoView.swift
//  Little Artist
//
//  Plays a looping video for an onboarding page, starting/stopping
//  based on whether the page is currently active.
//

import AVFoundation
import SwiftUI

/// Displays a looping video for an onboarding page.
struct OnboardingVideoView: View {
    /// The video file name (without extension) in the app bundle.
    let videoName: String
    /// Whether this page is currently visible.
    let isActive: Bool

    @State private var player: AVPlayer?

    var body: some View {
        OnboardingPlayerView(player: player)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
            }
            .onChange(of: isActive) { _, active in
                if active {
                    player?.seek(to: .zero)
                    player?.play()
                } else {
                    player?.pause()
                }
            }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mov")
                ?? Bundle.main.url(forResource: videoName, withExtension: "MP4")
                ?? Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return
        }

        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        self.player = avPlayer

        // Loop the video
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }

        if isActive {
            avPlayer.play()
        }
    }
}

// MARK: - UIKit Bridge

/// UIViewRepresentable wrapper for AVPlayerLayer sized to fit inside onboarding cards.
private struct OnboardingPlayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> OnboardingPlayerUIView {
        OnboardingPlayerUIView()
    }

    func updateUIView(_ uiView: OnboardingPlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

/// UIView subclass hosting an AVPlayerLayer for onboarding video playback.
private class OnboardingPlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
