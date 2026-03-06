import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Empty state view displayed when no artworks exist in the gallery.
class NoArtworkView extends StatelessWidget {
  const NoArtworkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.palette,
              size: 80,
              color: Brand.warmGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No artwork yet',
              style: Brand.title2Font.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(height: 8),
            Text(
              "Capture your child's first masterpiece!",
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
