//
//  CloudSharingView.swift
//  Little Artist
//
//  A UIViewControllerRepresentable wrapper around UICloudSharingController
//  for presenting CloudKit share invitations and management.
//

import CloudKit
import SwiftUI

/// A SwiftUI wrapper around `UICloudSharingController` for sharing child profiles.
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let child: Child

    func makeCoordinator() -> Coordinator {
        Coordinator(child: child)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let child: Child

        init(child: Child) {
            self.child = child
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("[CloudSharingView] Failed to save share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            child.name
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            child.avatarImageData
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            // Share saved — Core Data stack handles persistence automatically
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            // Sharing stopped — data returns to private zone automatically
        }
    }
}
