import 'package:flutter/material.dart';

import '../../models/database.dart';
import '../../utils/brand_tokens.dart';
import 'child_avatar_view.dart';

/// Horizontal scrollable row of child avatars with an "All" option.
///
/// When [selectedChildId] is null the "All" chip is highlighted.
/// Tapping a child avatar or the "All" chip calls [onChildSelected].
class ChildSliderView extends StatelessWidget {
  const ChildSliderView({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChildSelected,
  });

  final List<Child> children;

  /// Currently selected child ID, or null for "All".
  final int? selectedChildId;

  final ValueChanged<int?> onChildSelected;

  @override
  Widget build(BuildContext context) {
    final bool allSelected = selectedChildId == null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
      child: Row(
        children: [
          // "All" chip
          _AllChip(
            isSelected: allSelected,
            onTap: () => onChildSelected(null),
          ),
          const SizedBox(width: 12),
          // Child avatars
          ...children.map((child) {
            final bool selected = selectedChildId == child.id;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChildAvatarView(
                name: child.name,
                avatarColor: child.avatarColor,
                avatarImageData: child.avatarImageData,
                isSelected: selected,
                onTap: () => onChildSelected(child.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// MARK: - All Chip

class _AllChip extends StatelessWidget {
  const _AllChip({
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double ringSize = Brand.avatarRingSize;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: Brand.avatarShadow,
        ),
        child: SizedBox(
          width: ringSize,
          height: ringSize,
          child: Center(
            child: Container(
              width: Brand.avatarSize,
              height: Brand.avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Brand.primary : Brand.warmGray,
                border: isSelected
                    ? Border.all(
                        color: Brand.primary,
                        width: Brand.avatarRingStroke,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  'All',
                  style: Brand.subheadlineFont.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
