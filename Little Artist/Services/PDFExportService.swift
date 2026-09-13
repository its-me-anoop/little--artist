//
//  PDFExportService.swift
//  Little Artist
//
//  Generates a PDF portfolio for a child's artwork collection.
//  Each page shows the artwork image, title, caption, and date.
//

import UIKit
import CoreGraphics

/// Generates branded PDF portfolios from a child's artwork.
enum PDFExportService {

    /// Page dimensions (US Letter).
    private static let pageWidth: CGFloat = 612
    private static let pageHeight: CGFloat = 792
    private static let margin: CGFloat = 50

    /// Generates a PDF Data blob for the given child and their artworks.
    static func generatePortfolio(childName: String, artworks: [Artwork]) -> Data {
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            drawCoverPage(childName: childName, artworkCount: artworks.count, contentWidth: contentWidth)

            // Sort artworks by date (newest first)
            let sorted = artworks.sorted { $0.createdAt > $1.createdAt }

            // One artwork per page
            for artwork in sorted {
                context.beginPage()
                drawArtworkPage(artwork: artwork, contentWidth: contentWidth)
            }
        }

        return data
    }

    // MARK: - Cover Page

    private static func drawCoverPage(childName: String, artworkCount: Int, contentWidth: CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        let countFont = UIFont.systemFont(ofSize: 14, weight: .medium)

        let accentColor = UIColor(red: 242/255, green: 120/255, blue: 75/255, alpha: 1) // Brand.primary
        let charcoalColor = UIColor(red: 61/255, green: 61/255, blue: 61/255, alpha: 1)
        let warmGrayColor = UIColor(red: 138/255, green: 134/255, blue: 128/255, alpha: 1)

        // Decorative circle
        let circleRect = CGRect(x: pageWidth / 2 - 40, y: 220, width: 80, height: 80)
        let circlePath = UIBezierPath(ovalIn: circleRect)
        accentColor.withAlphaComponent(0.15).setFill()
        circlePath.fill()

        // Paint palette icon (text-based)
        let iconAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40),
            .foregroundColor: accentColor
        ]
        let icon = "🎨"
        let iconSize = icon.size(withAttributes: iconAttrs)
        icon.draw(at: CGPoint(x: pageWidth / 2 - iconSize.width / 2, y: 240 - iconSize.height / 2 + 40), withAttributes: iconAttrs)

        // Title
        let title = "\(childName)'s Art Portfolio"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: charcoalColor
        ]
        let titleRect = CGRect(x: margin, y: 360, width: contentWidth, height: 100)
        let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
        titleStr.draw(with: titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)

        // Subtitle
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let subtitle = "Generated \(dateFormatter.string(from: Date.now))"
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: warmGrayColor
        ]
        subtitle.draw(at: CGPoint(x: margin, y: 430), withAttributes: subtitleAttrs)

        // Count
        let countText = "\(artworkCount) artwork\(artworkCount == 1 ? "" : "s")"
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: countFont,
            .foregroundColor: accentColor
        ]
        countText.draw(at: CGPoint(x: margin, y: 460), withAttributes: countAttrs)

        // Footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: warmGrayColor
        ]
        let footer = "Created with Little Artist"
        footer.draw(at: CGPoint(x: margin, y: pageHeight - margin - 12), withAttributes: footerAttrs)
    }

    // MARK: - Artwork Page

    private static func drawArtworkPage(artwork: Artwork, contentWidth: CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        let captionFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let dateFont = UIFont.systemFont(ofSize: 11, weight: .medium)

        let charcoalColor = UIColor(red: 61/255, green: 61/255, blue: 61/255, alpha: 1)
        let warmGrayColor = UIColor(red: 138/255, green: 134/255, blue: 128/255, alpha: 1)
        let accentColor = UIColor(red: 242/255, green: 120/255, blue: 75/255, alpha: 1)

        var yOffset: CGFloat = margin

        // Artwork image
        if let imageData = artwork.imageData, let image = UIImage(data: imageData) {
            let maxImageHeight: CGFloat = 480
            let aspectRatio = image.size.width / image.size.height
            let imageWidth = min(contentWidth, image.size.width)
            var imageHeight = imageWidth / aspectRatio
            if imageHeight > maxImageHeight {
                imageHeight = maxImageHeight
            }
            let imageRect = CGRect(
                x: margin + (contentWidth - imageWidth) / 2,
                y: yOffset,
                width: imageWidth,
                height: imageHeight
            )

            // Rounded rect clip
            let clipPath = UIBezierPath(roundedRect: imageRect, cornerRadius: 12)
            clipPath.addClip()
            image.draw(in: imageRect)

            // Reset clip
            UIGraphicsGetCurrentContext()?.resetClip()

            yOffset += imageHeight + 24
        }

        // Title
        let title = artwork.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = title.isEmpty ? "Untitled" : title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: charcoalColor
        ]
        let titleRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 60)
        let titleStr = NSAttributedString(string: displayTitle, attributes: titleAttrs)
        titleStr.draw(with: titleRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        yOffset += 30

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateStr = dateFormatter.string(from: artwork.createdAt)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: accentColor
        ]
        dateStr.draw(at: CGPoint(x: margin, y: yOffset), withAttributes: dateAttrs)
        yOffset += 24

        // Caption
        let caption = artwork.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if !caption.isEmpty {
            let captionAttrs: [NSAttributedString.Key: Any] = [
                .font: captionFont,
                .foregroundColor: warmGrayColor
            ]
            let captionRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 80)
            let captionStr = NSAttributedString(string: caption, attributes: captionAttrs)
            captionStr.draw(with: captionRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        }

        // Page footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: warmGrayColor
        ]
        let childName = artwork.child?.name ?? ""
        let footer = childName.isEmpty ? "Little Artist" : "by \(childName) · Little Artist"
        footer.draw(at: CGPoint(x: margin, y: pageHeight - margin - 10), withAttributes: footerAttrs)
    }
}
