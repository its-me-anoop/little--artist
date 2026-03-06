import 'package:flutter/material.dart';

import '../../models/database.dart';
import '../../utils/brand_tokens.dart';

/// Gallery thumbnail card that displays an artwork's image with a title overlay
/// and optional favorite indicator.
class ArtworkThumbnailView extends StatelessWidget {
  final Artwork artwork;
  final VoidCallback? onTap;

  const ArtworkThumbnailView({
    super.key,
    required this.artwork,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = artwork.thumbnailData ?? artwork.imageData;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Brand.thumbnailWidth,
        height: Brand.thumbnailHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Brand.radiusCard),
          boxShadow: Brand.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Brand.radiusCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image or placeholder
              if (imageBytes != null)
                Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Brand.surface,
                  child: const Center(
                    child: Icon(
                      Icons.palette_outlined,
                      size: 40,
                      color: Brand.warmGray,
                    ),
                  ),
                ),

              // Gradient scrim at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 64,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x99000000), // black 60%
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Title overlay
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  artwork.title,
                  style: Brand.captionFont.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Favorite heart
              if (artwork.isFavorited)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite,
                    size: 20,
                    color: Brand.dustyRose,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
