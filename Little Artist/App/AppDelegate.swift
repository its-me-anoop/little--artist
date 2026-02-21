//
//  AppDelegate.swift
//  Little Artist
//
//  UIApplicationDelegate + UIWindowSceneDelegate for handling
//  CloudKit share acceptance callbacks and remote notification
//  delivery in SwiftUI scene-based apps.
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
        // Register for remote notifications so CloudKit can deliver
        // silent pushes when data changes on another device.
        application.registerForRemoteNotifications()
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

    /// Handles background remote notifications from CloudKit.
    ///
    /// `NSPersistentCloudKitContainer` processes the CloudKit data automatically,
    /// but SwiftData's `@Query` results won't refresh until its context processes
    /// the new persistent history. This handler triggers that refresh.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            let service = CloudKitSharingService.shared
            guard service.isInitialised, service.isSyncEnabled else {
                completionHandler(.noData)
                return
            }
            service.diag("AppDelegate: didReceiveRemoteNotification — refreshing")
            service.refreshSwiftDataContext()
            service.syncSharedDataToSwiftData()
            completionHandler(.newData)
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
