//
//  AppDelegate.swift
//  Little Artist
//
//  UIApplicationDelegate for handling CloudKit share acceptance callbacks.
//

import CloudKit
import UIKit

/// Handles app-level callbacks, primarily CloudKit share acceptance.
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    /// Called when the user accepts a CloudKit share invitation from another user.
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            CloudKitSharingService.shared.acceptShare(metadata: cloudKitShareMetadata)
        }
    }
}
