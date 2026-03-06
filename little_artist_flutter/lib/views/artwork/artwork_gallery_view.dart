import 'package:flutter/material.dart';

import '../../components/cards/artwork_thumbnail_view.dart';
import '../../models/database.dart';
import '../../utils/brand_tokens.dart';

/// Grid of artwork thumbnails displayed in a 2-column layout.
class ArtworkGalleryView extends StatelessWidget {
  final List<Artwork> artworks;
  final void Function(Artwork) onArtworkTap;

  const ArtworkGalleryView({
    super.key,
    required this.artworks,
    required this.onArtworkTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Brand.gallerySpacing / 2,
        mainAxisSpacing: Brand.gallerySpacing / 2,
        childAspectRatio: Brand.thumbnailWidth / Brand.thumbnailHeight,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final artwork = artworks[index];
        return ArtworkThumbnailView(
          artwork: artwork,
          onTap: () => onArtworkTap(artwork),
        );
      },
    );
  }
}
