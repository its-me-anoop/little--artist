import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Stats display card for milestones showing an icon, value, and label.
class StatCardView extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const StatCardView({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Brand.radiusCard),
        boxShadow: Brand.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: iconColor ?? Brand.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Brand.title2Font.copyWith(color: Brand.charcoal),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Brand.captionFont.copyWith(color: Brand.warmGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
