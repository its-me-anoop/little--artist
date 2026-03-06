import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Achievement/milestone badge displaying a circular icon with title and
/// description. Dims when not yet unlocked.
class AchievementBadgeView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isUnlocked;
  final Color? color;

  const AchievementBadgeView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isUnlocked = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Brand.primary;

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Brand.subheadlineFont.copyWith(color: Brand.charcoal),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: Brand.caption2Font.copyWith(color: Brand.warmGray),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
