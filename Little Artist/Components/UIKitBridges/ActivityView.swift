//
//  ActivityView.swift
//  Little Artist
//
//  A UIViewControllerRepresentable wrapper around UIActivityViewController
//  for presenting the system share sheet.
//
//  Created by Codex on 15/02/2026.
//

import SwiftUI

/// A SwiftUI wrapper around `UIActivityViewController` for sharing content.
struct ActivityView: UIViewControllerRepresentable {
    /// The items to share (images, text, URLs, etc.).
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// An `Identifiable` wrapper for share payload items, used with `.sheet(item:)`.
struct SharePayload: Identifiable {
    let id = UUID()
    /// The items to share.
    let items: [Any]
}
