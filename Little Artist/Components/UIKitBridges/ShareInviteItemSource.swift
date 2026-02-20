//
//  ShareInviteItemSource.swift
//  Little Artist
//
//  A UIActivityItemSource that provides custom link metadata for CloudKit
//  share invitations, displaying the child's avatar and a personalised title
//  instead of the default iCloud link preview.
//

import LinkPresentation
import SwiftUI
import UIKit

/// Provides rich link metadata for a CloudKit share invitation URL.
///
/// When used with `UIActivityViewController`, this replaces the default
/// iCloud link preview with the child's avatar and a personalised title.
final class ShareInviteItemSource: NSObject, UIActivityItemSource {
    private let url: URL
    private let childName: String
    private let avatarImage: UIImage?

    /// - Parameters:
    ///   - url: The CloudKit share invitation URL.
    ///   - childName: The child's name for the preview title.
    ///   - avatarImageData: The child's avatar photo data (optional).
    ///   - avatarColor: Hex color for the fallback avatar circle.
    init(url: URL, childName: String, avatarImageData: Data?, avatarColor: String) {
        self.url = url
        self.childName = childName

        // Build the preview image: custom photo clipped to circle, or colored initial
        if let data = avatarImageData, let photo = UIImage(data: data) {
            let size = CGSize(width: 120, height: 120)
            let renderer = UIGraphicsImageRenderer(size: size)
            self.avatarImage = renderer.image { _ in
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
                photo.draw(in: CGRect(origin: .zero, size: size))
            }
        } else {
            // Generate colored circle with initial
            let size = CGSize(width: 120, height: 120)
            let renderer = UIGraphicsImageRenderer(size: size)
            self.avatarImage = renderer.image { _ in
                UIColor(Color(hex: avatarColor)).setFill()
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
                let initial = String(childName.prefix(1)).uppercased()
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
        }
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        url
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.originalURL = url
        metadata.url = url
        metadata.title = "Join \(childName)'s Little Artist"

        if let image = avatarImage {
            metadata.iconProvider = NSItemProvider(object: image)
        }

        return metadata
    }
}
