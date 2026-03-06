import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses and resizes images for storage and thumbnail generation.
class ImageProcessingService {
  static const int _mainMaxDimension = 2048;
  static const int _thumbnailMaxDimension = 512;
  static const int _mainQuality = 70;
  static const int _thumbnailQuality = 60;

  /// Compresses [imageBytes] for storage and generates a thumbnail.
  ///
  /// Returns a record with `imageData` (max 2048px, quality 70) and
  /// `thumbnailData` (max 512px, quality 60).
  Future<({Uint8List imageData, Uint8List thumbnailData})> processForStorage(
    Uint8List imageBytes,
  ) async {
    final imageData = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: _mainMaxDimension,
      minHeight: _mainMaxDimension,
      quality: _mainQuality,
      format: CompressFormat.jpeg,
    );

    final thumbnailData = await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: _thumbnailMaxDimension,
      minHeight: _thumbnailMaxDimension,
      quality: _thumbnailQuality,
      format: CompressFormat.jpeg,
    );

    return (
      imageData: Uint8List.fromList(imageData),
      thumbnailData: Uint8List.fromList(thumbnailData),
    );
  }

  /// Generates a thumbnail from [imageBytes] (max 512px, quality 60).
  ///
  /// Returns `null` on failure.
  Future<Uint8List?> generateThumbnail(Uint8List imageBytes) async {
    try {
      final data = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: _thumbnailMaxDimension,
        minHeight: _thumbnailMaxDimension,
        quality: _thumbnailQuality,
        format: CompressFormat.jpeg,
      );
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
}
