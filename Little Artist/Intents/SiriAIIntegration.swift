//
//  SiriAIIntegration.swift
//  Little Artist
//
//  iOS 27.3 Siri AI integration: exposes the app's intents as tools Siri
//  can call, gives artwork a rich card snippet, and keeps children's
//  details behind device authentication.
//
//  Compiled only with the iOS 27.3 SDK (AppIntents 301.2+). The same
//  Swift compiler ships with Xcode 27.2, so the gate is on the module
//  version, not `#if compiler`. Conformances are added in availability-
//  gated extensions so the intents keep working in Shortcuts on older iOS.
//

#if canImport(AppIntents, _version: 301.2)

import AppIntents
import SwiftUI

// MARK: - Tools

// Siri can call these when a request names Little Artist, while the app is
// in the foreground, or after it found a child or artwork through
// Spotlight. They take and return entities so steps can chain, e.g.
// "show Mia's latest drawing and add it to favorites".

@available(iOS 27.3, *) extension CaptureArtworkIntent: ToolIntent {}
@available(iOS 27.3, *) extension ShowLatestArtworkIntent: ToolIntent {}
@available(iOS 27.3, *) extension OnThisDayIntent: ToolIntent {}
@available(iOS 27.3, *) extension CountArtworkIntent: ToolIntent {}
@available(iOS 27.3, *) extension FavoriteArtworkIntent: ToolIntent {}
@available(iOS 27.3, *) extension OpenArtworkIntent: ToolIntent {}
@available(iOS 27.3, *) extension OpenChildGalleryIntent: ToolIntent {}
@available(iOS 27.3, *) extension ViewMilestonesIntent: ToolIntent {}

// MARK: - Artwork Card Snippet

@available(iOS 27.3, *)
extension ArtworkEntity: SnippetRepresentableEntity {
    /// The card Siri and Spotlight show for a piece of artwork.
    static var snippet: some EntitySnippetContent<ArtworkEntity> {
        CardSnippet(supportedFamilies: [.standard]) { artwork, _ in
            ArtworkSnippetView(
                artwork: artwork,
                footnote: artwork.createdAt.formatted(date: .abbreviated, time: .omitted)
            )
        }
    }
}

// MARK: - Privacy

// Children's names, photos and artwork are family data: Siri may only
// show them once the device is unlocked.

@available(iOS 27.3, *)
extension ChildEntity {
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
}

@available(iOS 27.3, *)
extension ArtworkEntity {
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
}

#endif
