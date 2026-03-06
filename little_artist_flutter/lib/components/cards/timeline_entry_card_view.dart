import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/database.dart';
import '../../utils/brand_tokens.dart';

/// Card for the timeline view showing an artwork entry with image, title,
/// caption, date, and optional child name badge.
class TimelineEntryCardView extends StatelessWidget {
  final Artwork artwork;
  final String? childName;
  final VoidCallback? onTap;

  const TimelineEntryCardView({
    super.key,
    required this.artwork,
    this.childName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = artwork.thumbnailData ?? artwork.imageData;
    final dateText = DateFormat.yMMMd().format(artwork.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Brand.surface,
          borderRadius: BorderRadius.circular(Brand.radiusCard),
          boxShadow: Brand.cardShadow,
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(Brand.radiusImage),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Brand.cream,
                        child: const Center(
                          child: Icon(
                            Icons.palette_outlined,
                            size: 28,
                            color: Brand.warmGray,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    artwork.title,
                    style: Brand.headlineFont.copyWith(color: Brand.charcoal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artwork.caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      artwork.caption,
                      style: Brand.captionFont.copyWith(color: Brand.warmGray),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        dateText,
                        style:
                            Brand.caption2Font.copyWith(color: Brand.warmGray),
                      ),
                      if (childName != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Brand.primaryTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            childName!,
                            style: Brand.caption2Font
                                .copyWith(color: Brand.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
