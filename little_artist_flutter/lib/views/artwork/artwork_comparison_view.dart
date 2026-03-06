import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Side-by-side artwork comparison with a draggable vertical divider.
///
/// Overlays [beforeImage] and [afterImage] in a stack. The user drags
/// a vertical divider to reveal more or less of each image.
class ArtworkComparisonView extends StatefulWidget {
  /// The "before" image data shown on the left side.
  final Uint8List beforeImage;

  /// The "after" image data shown on the right side.
  final Uint8List afterImage;

  const ArtworkComparisonView({
    super.key,
    required this.beforeImage,
    required this.afterImage,
  });

  @override
  State<ArtworkComparisonView> createState() => _ArtworkComparisonViewState();
}

class _ArtworkComparisonViewState extends State<ArtworkComparisonView> {
  /// Divider position as a fraction of the total width (0.0-1.0).
  double _dividerPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final dividerX = _dividerPosition * width;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dividerPosition =
                  (details.localPosition.dx / width).clamp(0.05, 0.95);
            });
          },
          child: Stack(
            children: [
              // After image (full width, below)
              Positioned.fill(
                child: Image.memory(
                  widget.afterImage,
                  fit: BoxFit.cover,
                ),
              ),

              // Before image (clipped to divider position)
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(dividerX),
                  child: Image.memory(
                    widget.beforeImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Labels
              Positioned(
                top: 12,
                left: 12,
                child: _buildLabel('Before'),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildLabel('After'),
              ),

              // Divider line
              Positioned(
                left: dividerX - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white,
                ),
              ),

              // Divider handle
              Positioned(
                left: dividerX - 16,
                top: height / 2 - 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left, size: 14, color: Brand.charcoal),
                      Icon(Icons.chevron_right, size: 14, color: Brand.charcoal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Brand.radiusField),
      ),
      child: Text(
        text,
        style: Brand.captionFont.copyWith(color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MARK: - Custom Clipper
// ---------------------------------------------------------------------------

/// Clips to the left side of the widget up to [dividerX].
class _LeftClipper extends CustomClipper<Rect> {
  final double dividerX;

  _LeftClipper(this.dividerX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, dividerX, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) =>
      oldClipper.dividerX != dividerX;
}
