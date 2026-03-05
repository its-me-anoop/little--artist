//
//  PrivacyPolicyView.swift
//  Little Artist
//
//  Displays the privacy policy from the website in an in-app Safari browser.
//

import SwiftUI
import SafariServices

/// Wraps `SFSafariViewController` for use in SwiftUI.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Displays the app's privacy policy from the website.
struct PrivacyPolicyView: View {
    private let privacyURL = URL(string: "https://www.flutterly.co.uk/little-artist/privacy-policy")!

    var body: some View {
        SafariView(url: privacyURL)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
