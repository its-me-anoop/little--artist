import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:little_artist/models/database.dart';

/// Generates branded PDF portfolios from a child's artwork collection.
///
/// Each portfolio includes a cover page with the child's name and artwork
/// count, followed by one page per artwork with image, title, date, and
/// caption.
abstract final class PDFExportService {
  // Page dimensions (US Letter)
  static const _pageWidth = 612.0;
  static const _pageHeight = 792.0;
  static const _margin = 50.0;

  // Brand colors
  static final _primaryColor = PdfColor.fromHex('#F2784B');
  static final _charcoalColor = PdfColor.fromHex('#3D3D3D');
  static final _warmGrayColor = PdfColor.fromHex('#8A8680');
  static final _primaryTintColor = PdfColor(
    _primaryColor.red,
    _primaryColor.green,
    _primaryColor.blue,
    0.15,
  );

  /// Generates a PDF portfolio for the given child and their artworks.
  ///
  /// Returns the PDF as raw bytes ready for saving or sharing.
  static Future<Uint8List> generatePortfolio(
    String childName,
    List<Artwork> artworks,
  ) async {
    final pdf = pw.Document(
      title: "$childName's Art Portfolio",
      author: 'Artling',
    );

    final contentWidth = _pageWidth - _margin * 2;

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
        margin: pw.EdgeInsets.all(_margin),
        build: (context) => _buildCoverPage(
          childName: childName,
          artworkCount: artworks.length,
          contentWidth: contentWidth,
        ),
      ),
    );

    // Sort artworks by date (newest first)
    final sorted = List<Artwork>.from(artworks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // One artwork per page
    for (final artwork in sorted) {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(_pageWidth, _pageHeight),
          margin: pw.EdgeInsets.all(_margin),
          build: (context) => _buildArtworkPage(
            artwork: artwork,
            childName: childName,
            contentWidth: contentWidth,
          ),
        ),
      );
    }

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // Cover page
  // ---------------------------------------------------------------------------

  static pw.Widget _buildCoverPage({
    required String childName,
    required int artworkCount,
    required double contentWidth,
  }) {
    final dateString = DateFormat('MMMM yyyy').format(DateTime.now());
    final countText = '$artworkCount artwork${artworkCount == 1 ? '' : 's'}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 170),

        // Decorative circle with icon
        pw.Center(
          child: pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _primaryTintColor,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'A',
              style: pw.TextStyle(
                fontSize: 36,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ),

        pw.SizedBox(height: 50),

        // Title
        pw.Text(
          "$childName's Art Portfolio",
          style: pw.TextStyle(
            fontSize: 36,
            fontWeight: pw.FontWeight.bold,
            color: _charcoalColor,
          ),
        ),

        pw.SizedBox(height: 16),

        // Date
        pw.Text(
          'Generated $dateString',
          style: pw.TextStyle(
            fontSize: 18,
            color: _warmGrayColor,
          ),
        ),

        pw.SizedBox(height: 8),

        // Count
        pw.Text(
          countText,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),

        pw.Spacer(),

        // Footer
        pw.Text(
          'Created with Artling',
          style: pw.TextStyle(
            fontSize: 10,
            color: _warmGrayColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Artwork page
  // ---------------------------------------------------------------------------

  static pw.Widget _buildArtworkPage({
    required Artwork artwork,
    required String childName,
    required double contentWidth,
  }) {
    final dateFormatter = DateFormat.yMMMMd();
    final displayTitle = artwork.title.trim().isEmpty
        ? 'Untitled'
        : artwork.title.trim();
    final dateStr = dateFormatter.format(artwork.createdAt);
    final caption = artwork.caption.trim();
    final footerText =
        childName.isEmpty ? 'Artling' : 'by $childName \u00B7 Artling';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Artwork image
        if (artwork.imageData != null) ...[
          pw.Center(
            child: pw.ClipRRect(
              horizontalRadius: 12,
              verticalRadius: 12,
              child: pw.ConstrainedBox(
                constraints: pw.BoxConstraints(
                  maxWidth: contentWidth,
                  maxHeight: 480,
                ),
                child: pw.Image(
                  pw.MemoryImage(artwork.imageData!),
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 24),
        ],

        // Title
        pw.Text(
          displayTitle,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _charcoalColor,
          ),
        ),

        pw.SizedBox(height: 6),

        // Date
        pw.Text(
          dateStr,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),

        // Caption
        if (caption.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            caption,
            style: pw.TextStyle(
              fontSize: 13,
              color: _warmGrayColor,
            ),
          ),
        ],

        pw.Spacer(),

        // Page footer
        pw.Text(
          footerText,
          style: pw.TextStyle(
            fontSize: 9,
            color: _warmGrayColor,
          ),
        ),
      ],
    );
  }
}
