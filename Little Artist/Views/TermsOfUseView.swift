//
//  TermsOfUseView.swift
//  Little Artist
//
//  Displays the Terms of Use from the website in an in-app Safari browser.
//

import SafariServices
import SwiftUI

/// Wraps `SFSafariViewController` for displaying Terms of Use in-app.
private struct TermsSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Displays the app's Terms of Use from the website.
struct TermsOfUseView: View {
    private let termsURL = URL(string: "https://www.flutterly.co.uk/projects/artling/terms-of-use")!

    var body: some View {
        TermsSafariView(url: termsURL)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TermsOfUseView()
    }
}
