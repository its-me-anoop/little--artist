import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Small pill badge indicating that content is shared.
///
/// Displays a share icon and "Shared" label in a compact tinted pill.
class SharedBadgeView extends StatelessWidget {
  const SharedBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Brand.primaryTint,
        borderRadius: BorderRadius.circular(100), // fully rounded pill
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people,
            size: 12,
            color: Brand.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Shared',
            style: Brand.caption2Font.copyWith(color: Brand.primary),
          ),
        ],
      ),
    );
  }
}
