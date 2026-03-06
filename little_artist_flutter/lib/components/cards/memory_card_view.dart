import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/database.dart';
import '../../utils/brand_tokens.dart';

/// "On this day" memory card showing an artwork from a previous year.
class MemoryCardView extends StatelessWidget {
  final Artwork artwork;
  final int yearsAgo;
  final VoidCallback? onTap;

  const MemoryCardView({
    super.key,
    required this.artwork,
    required this.yearsAgo,
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
                width: 100,
                height: 100,
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
                            size: 32,
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
                  // "X years ago" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Brand.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      yearsAgo == 1 ? '1 year ago' : '$yearsAgo years ago',
                      style:
                          Brand.caption2Font.copyWith(color: Brand.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artwork.title,
                    style: Brand.headlineFont.copyWith(color: Brand.charcoal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: Brand.captionFont.copyWith(color: Brand.warmGray),
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
