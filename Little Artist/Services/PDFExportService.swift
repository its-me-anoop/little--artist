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

    /// The page format of an exported portfolio.
    enum Format: String, CaseIterable, Identifiable {
        /// US Letter, newest first — for sharing and home printing.
        case letter
        /// 8×8 in square photo book with 0.125 in bleed, oldest first —
        /// the most common size offered by photo-book printers.
        case photoBook8x8

        var id: String { rawValue }

        var title: String {
            switch self {
            case .letter: return "Standard PDF (US Letter)"
            case .photoBook8x8: return "Print-Ready Photo Book (8×8 in)"
            }
        }

        var fileSuffix: String {
            switch self {
            case .letter: return "Portfolio"
            case .photoBook8x8: return "Photo_Book_8x8"
            }
        }
    }

    /// Page geometry for a format, in PDF points (72 per inch).
    struct Layout {
        let pageWidth: CGFloat
        let pageHeight: CGFloat
        /// Distance from the page edge to the safe content area (includes bleed).
        let margin: CGFloat
        /// Extra area printed past the trim line.
        let bleed: CGFloat
        let fillsBackground: Bool

        var contentWidth: CGFloat { pageWidth - margin * 2 }

        static func forFormat(_ format: Format) -> Layout {
            switch format {
            case .letter:
                return Layout(pageWidth: 612, pageHeight: 792, margin: 50, bleed: 0, fillsBackground: false)
            case .photoBook8x8:
                // 8 in trim + 0.125 in bleed on every side = 8.25 in (594 pt).
                // Safe area: 0.5 in inside the trim line.
                let bleed: CGFloat = 9
                return Layout(pageWidth: 576 + bleed * 2, pageHeight: 576 + bleed * 2, margin: bleed + 36, bleed: bleed, fillsBackground: true)
            }
        }
    }

    private static let creamColor = UIColor(red: 255/255, green: 248/255, blue: 240/255, alpha: 1) // Brand.cream

    /// Generates a PDF Data blob for the given child and their artworks.
    static func generatePortfolio(childName: String, artworks: [Artwork], format: Format = .letter) -> Data {
        let layout = Layout.forFormat(format)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: layout.pageWidth, height: layout.pageHeight))

        let data = renderer.pdfData { context in
            // Cover page
            context.beginPage()
            fillBackgroundIfNeeded(layout)
            drawCoverPage(childName: childName, artworkCount: artworks.count, layout: layout, format: format)

            // Letter: newest first. Photo books read as a story: oldest first.
            let sorted = artworks.sorted {
                format == .photoBook8x8 ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
            }

            // One artwork per page
            for artwork in sorted {
                context.beginPage()
                fillBackgroundIfNeeded(layout)
                drawArtworkPage(artwork: artwork, layout: layout)
            }
        }

        return data
    }

    /// Photo books print edge to edge, so paint the full bleed area.
    private static func fillBackgroundIfNeeded(_ layout: Layout) {
        guard layout.fillsBackground else { return }
        creamColor.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: layout.pageWidth, height: layout.pageHeight))
    }

    // MARK: - Cover Page

    private static func drawCoverPage(childName: String, artworkCount: Int, layout: Layout, format: Format) {
        let pageWidth = layout.pageWidth
        let pageHeight = layout.pageHeight
        let margin = layout.margin
        let contentWidth = layout.contentWidth
        // Vertically position cover elements relative to the letter design.
        let scale = pageHeight / 792
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        let countFont = UIFont.systemFont(ofSize: 14, weight: .medium)

        let accentColor = UIColor(red: 242/255, green: 120/255, blue: 75/255, alpha: 1) // Brand.primary
        let charcoalColor = UIColor(red: 61/255, green: 61/255, blue: 61/255, alpha: 1)
        let warmGrayColor = UIColor(red: 138/255, green: 134/255, blue: 128/255, alpha: 1)

        // Decorative circle
        let circleRect = CGRect(x: pageWidth / 2 - 40, y: 220 * scale, width: 80, height: 80)
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
        icon.draw(at: CGPoint(x: pageWidth / 2 - iconSize.width / 2, y: 220 * scale + 40 - iconSize.height / 2), withAttributes: iconAttrs)

        // Title
        let title = format == .photoBook8x8 ? "\(childName)'s Art Book" : "\(childName)'s Art Portfolio"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: charcoalColor
        ]
        let titleRect = CGRect(x: margin, y: 360 * scale, width: contentWidth, height: 100)
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
        subtitle.draw(at: CGPoint(x: margin, y: 360 * scale + 70), withAttributes: subtitleAttrs)

        // Count
        let countText = "\(artworkCount) artwork\(artworkCount == 1 ? "" : "s")"
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: countFont,
            .foregroundColor: accentColor
        ]
        countText.draw(at: CGPoint(x: margin, y: 360 * scale + 100), withAttributes: countAttrs)

        // Footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: warmGrayColor
        ]
        let footer = "Created with Little Artist"
        footer.draw(at: CGPoint(x: margin, y: pageHeight - margin - 12), withAttributes: footerAttrs)
    }

    // MARK: - Artwork Page

    private static func drawArtworkPage(artwork: Artwork, layout: Layout) {
        let pageHeight = layout.pageHeight
        let margin = layout.margin
        let contentWidth = layout.contentWidth
        let titleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        let captionFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        let dateFont = UIFont.systemFont(ofSize: 11, weight: .medium)

        let charcoalColor = UIColor(red: 61/255, green: 61/255, blue: 61/255, alpha: 1)
        let warmGrayColor = UIColor(red: 138/255, green: 134/255, blue: 128/255, alpha: 1)
        let accentColor = UIColor(red: 242/255, green: 120/255, blue: 75/255, alpha: 1)

        var yOffset: CGFloat = margin

        // Artwork image
        if let imageData = artwork.imageData, let image = UIImage(data: imageData) {
            // Leave room below the image for title, date and caption.
            let maxImageHeight: CGFloat = pageHeight - margin * 2 - 150
            let aspectRatio = image.size.width / max(image.size.height, 1)
            var imageWidth = min(contentWidth, image.size.width)
            var imageHeight = imageWidth / aspectRatio
            if imageHeight > maxImageHeight {
                // Keep the aspect ratio instead of squashing tall artwork.
                imageHeight = maxImageHeight
                imageWidth = imageHeight * aspectRatio
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
