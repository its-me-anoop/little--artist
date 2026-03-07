//
//  AppDelegate.swift
//  Little Artist
//
//  UIApplicationDelegate + UIWindowSceneDelegate for handling
//  Firebase share link acceptance.
//

import UIKit

/// Handles app-level callbacks and provides scene configuration
/// for Universal Link-based share acceptance.
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    /// Returns a scene configuration that uses ``SceneDelegate`` for
    /// Universal Link handling (share acceptance).
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Scene Delegate

/// Handles per-scene callbacks for Universal Link-based share acceptance.
class SceneDelegate: NSObject, UIWindowSceneDelegate {

    /// Called when the user opens a Universal Link (e.g. a share invite).
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }

        // Extract shareId from the URL
        // Expected format: https://yourdomain.com/share/{shareId}
        let pathComponents = url.pathComponents
        if let shareIndex = pathComponents.firstIndex(of: "share"),
           shareIndex + 1 < pathComponents.count {
            let shareId = pathComponents[shareIndex + 1]
            Task { @MainActor in
                FirestoreSyncService.shared.diag("Share link opened: \(shareId)")
                do {
                    try await FirestoreRepository.shared.acceptShare(shareId: shareId)
                    // Restart sync to pick up shared data
                    FirestoreSyncService.shared.stop()
                    FirestoreSyncService.shared.start()
                } catch {
                    FirestoreSyncService.shared.diag("Share acceptance failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
