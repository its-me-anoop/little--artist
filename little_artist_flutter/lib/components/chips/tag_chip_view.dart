import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Tag display chip with an optional remove button.
///
/// Uses [Brand.primaryTint] as the background and [Brand.primary] for text.
/// When [showRemove] is true a small close icon is displayed on the right.
class TagChipView extends StatelessWidget {
  const TagChipView({
    super.key,
    required this.name,
    this.showRemove = false,
    this.onTap,
    this.onRemove,
  });

  final String name;
  final bool showRemove;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: Brand.primaryTint,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: Brand.captionFont.copyWith(color: Brand.primary),
            ),
            if (showRemove) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Brand.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
