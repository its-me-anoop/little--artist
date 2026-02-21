//
//  AppDelegate.swift
//  Little Artist
//
//  UIApplicationDelegate + UIWindowSceneDelegate for handling
//  CloudKit share acceptance callbacks in SwiftUI scene-based apps.
//

import CloudKit
import UIKit

/// Handles app-level callbacks and provides scene configuration
/// that routes CloudKit share acceptance to ``SceneDelegate``.
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    /// Returns a scene configuration that uses ``SceneDelegate`` so that
    /// `windowScene(_:userDidAcceptCloudKitShareWith:)` is delivered.
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

    /// Fallback for non-scene environments (unlikely in SwiftUI apps).
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        CloudKitSharingService.shared.diag("AppDelegate: userDidAcceptCloudKitShareWith CALLED")
        Task { @MainActor in
            CloudKitSharingService.shared.acceptShare(metadata: cloudKitShareMetadata)
        }
    }
}

// MARK: - Scene Delegate

/// Handles per-scene callbacks. In SwiftUI scene-based apps, CloudKit share
/// acceptance is routed here — NOT to the UIApplicationDelegate method.
class SceneDelegate: NSObject, UIWindowSceneDelegate {

    /// Called when the user taps a CloudKit share link and the system
    /// delivers the share metadata to this scene.
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        CloudKitSharingService.shared.diag("SceneDelegate: userDidAcceptCloudKitShareWith CALLED — record=\(cloudKitShareMetadata.share.recordID.recordName)")
        Task { @MainActor in
            CloudKitSharingService.shared.acceptShare(metadata: cloudKitShareMetadata)
        }
    }
}
