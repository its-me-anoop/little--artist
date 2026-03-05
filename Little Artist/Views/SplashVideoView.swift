//
//  SplashVideoView.swift
//  Little Artist
//
//  Plays the splash video on app launch, then transitions to the main content.
//

import AVFoundation
import AVKit
import SwiftUI

/// A full-screen splash view that plays a video before transitioning to the app.
struct SplashVideoView: View {
    @Binding var isFinished: Bool

    @State private var player: AVPlayer?
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Color(white: 1).ignoresSafeArea()

            if let player {
                VideoPlayerView(player: player)
                    .frame(width: 250, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: Brand.radiusCard))
            }
        }
        .opacity(opacity)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "splash", withExtension: "mov") else {
            isFinished = true
            return
        }

        let avPlayer = AVPlayer(url: url)
        avPlayer.isMuted = true
        self.player = avPlayer

        // Listen for video end
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFinished = true
            }
        }

        avPlayer.play()
    }
}

// MARK: - Video Player UIKit Bridge

/// UIViewRepresentable wrapper for AVPlayerLayer to display video without controls.
private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

/// UIView subclass that hosts an AVPlayerLayer for full-screen video playback.
private class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
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
