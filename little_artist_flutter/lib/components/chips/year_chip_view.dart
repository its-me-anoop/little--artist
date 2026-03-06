import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Year filter chip for timeline navigation.
///
/// Displays a [year] label inside a pill-shaped chip that toggles
/// between selected and unselected visual states.
class YearChipView extends StatelessWidget {
  const YearChipView({
    super.key,
    required this.year,
    this.isSelected = false,
    this.onTap,
  });

  final int year;
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
          shape: const StadiumBorder(),
        ),
        child: Text(
          '$year',
          style: Brand.subheadlineFont.copyWith(color: textColor),
        ),
      ),
    );
  }
}
