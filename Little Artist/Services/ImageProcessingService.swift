//
//  ImageProcessingService.swift
//  Little Artist
//
//  Resizes and compresses artwork images at ingest time.
//  Produces a two-tier output: a main image (max 2048px, JPEG 0.7)
//  and a thumbnail (max 512px, JPEG 0.6).
//

import UIKit

/// Stateless image processing utility for artwork ingest.
///
/// Call ``processForStorage(image:)`` from camera/scanner captures, or
/// ``processForStorage(data:)`` from photo picker / batch imports.
enum ImageProcessingService {

    // MARK: - Configuration

    /// Maximum longest-edge dimension for the main stored image.
    static let mainMaxDimension: CGFloat = 2048

    /// JPEG compression quality for the main image (0.0–1.0).
    static let mainQuality: CGFloat = 0.7

    /// Maximum longest-edge dimension for the thumbnail.
    static let thumbnailMaxDimension: CGFloat = 512

    /// JPEG compression quality for the thumbnail (0.0–1.0).
    static let thumbnailQuality: CGFloat = 0.6

    // MARK: - Public API

    /// Processes a `UIImage` (from camera or scanner) into compressed main + thumbnail data.
    static func processForStorage(image: UIImage) -> (imageData: Data, thumbnailData: Data) {
        let mainImage = resized(image, maxDimension: mainMaxDimension)
        let thumbImage = resized(image, maxDimension: thumbnailMaxDimension)

        let imageData = mainImage.jpegData(compressionQuality: mainQuality) ?? Data()
        let thumbnailData = thumbImage.jpegData(compressionQuality: thumbnailQuality) ?? Data()

        return (imageData: imageData, thumbnailData: thumbnailData)
    }

    /// Processes raw `Data` (from photo picker) into compressed main + thumbnail data.
    /// Returns `nil` if the data cannot be decoded as an image.
    static func processForStorage(data: Data) -> (imageData: Data, thumbnailData: Data)? {
        guard let image = UIImage(data: data) else { return nil }
        return processForStorage(image: image)
    }

    /// Maximum longest-edge dimension for child avatar photos. Avatars are
    /// shown at most ~140pt, so this keeps them sharp at 3x while keeping
    /// iCloud sync small.
    static let avatarMaxDimension: CGFloat = 512

    /// Downscales and compresses a child avatar photo.
    static func processAvatar(image: UIImage) -> Data? {
        resized(image, maxDimension: avatarMaxDimension).jpegData(compressionQuality: 0.8)
    }

    /// Downscales and compresses raw avatar data (photo picker, Image
    /// Playground). Returns `nil` if the data isn't an image.
    static func processAvatar(data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return processAvatar(image: image)
    }

    // MARK: - Private

    /// Resizes an image so its longest edge is at most `maxDimension`.
    /// Returns the original image if it's already smaller.
    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        // Work in pixels so the limit means the same on every device.
        let size = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let longest = max(size.width, size.height)

        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )

        // Render at 1x: `size` is in pixels here, and the default format
        // would multiply it by the screen scale (3x on most iPhones).
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
