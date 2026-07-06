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

    // MARK: - Private

    /// Resizes an image so its longest edge is at most `maxDimension`.
    /// Returns the original image if it's already smaller.
    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)

        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(
            width: (size.width * scale).rounded(.down),
            height: (size.height * scale).rounded(.down)
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
