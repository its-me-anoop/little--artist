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
            let size = CGSize(width: 120, height: 120)
            let renderer = UIGraphicsImageRenderer(size: size)

            if let data = child.avatarImageData,
               let source = UIImage(data: data) {
                // Render the custom photo clipped to a circle
                let circularImage = renderer.image { _ in
                    UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
                    source.draw(in: CGRect(origin: .zero, size: size))
                }
                return circularImage.pngData()
            }

            // Generate a thumbnail from the avatar color + initial
            let image = renderer.image { _ in
                UIColor(Color(hex: child.avatarColor)).setFill()
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
                let initial = String(child.name.prefix(1)).uppercased()
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 52, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let textSize = initial.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                initial.draw(in: textRect, withAttributes: attrs)
            }
            return image.pngData()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            // Share saved — Core Data stack handles persistence automatically
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            // Sharing stopped — data returns to private zone automatically
        }
    }
}
