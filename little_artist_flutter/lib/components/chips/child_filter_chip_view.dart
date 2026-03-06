import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Pill-shaped filter chip for child selection.
///
/// Displays a [label] with an optional color indicator dot derived from
/// [avatarColor]. The chip toggles between selected and unselected states.
class ChildFilterChipView extends StatelessWidget {
  const ChildFilterChipView({
    super.key,
    required this.label,
    this.avatarColor,
    this.isSelected = false,
    this.onTap,
  });

  final String label;

  /// Hex color string without leading '#', e.g. "F2784B".
  final String? avatarColor;

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isSelected ? Brand.primary : Brand.surface;
    final Color textColor = isSelected ? Colors.white : Brand.charcoal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: ShapeDecoration(
          color: bgColor,
          shape: StadiumBorder(
            side: isSelected
                ? BorderSide.none
                : const BorderSide(color: Brand.softTan),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatarColor != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(int.parse('FF$avatarColor', radix: 16)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Brand.subheadlineFont.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
