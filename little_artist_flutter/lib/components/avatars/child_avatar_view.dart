import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Circular avatar for a child profile.
///
/// Shows the first letter of the child's name on a colored background.
/// When [avatarImageData] is provided, the image is displayed instead.
/// An optional selection ring highlights the avatar when [isSelected] is true.
class ChildAvatarView extends StatelessWidget {
  const ChildAvatarView({
    super.key,
    required this.name,
    required this.avatarColor,
    this.avatarImageData,
    this.isSelected = false,
    this.size = Brand.avatarSize,
    this.onTap,
  });

  final String name;

  /// Hex color string without leading '#', e.g. "F2784B".
  final String avatarColor;

  final Uint8List? avatarImageData;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;

  Color get _backgroundColor =>
      Color(int.parse('FF$avatarColor', radix: 16));

  @override
  Widget build(BuildContext context) {
    final double ringSize = size + (Brand.avatarRingSize - Brand.avatarSize);

    final Widget avatar = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: Brand.avatarShadow,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _backgroundColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: avatarImageData != null
            ? Image.memory(
                avatarImageData!,
                fit: BoxFit.cover,
                width: size,
                height: size,
              )
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: Brand.title2Font.copyWith(color: Colors.white),
                ),
              ),
      ),
    );

    final Widget content = isSelected
        ? SizedBox(
            width: ringSize,
            height: ringSize,
            child: Center(
              child: Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Brand.primary,
                    width: Brand.avatarRingStroke,
                  ),
                ),
                child: Center(child: avatar),
              ),
            ),
          )
        : SizedBox(
            width: ringSize,
            height: ringSize,
            child: Center(child: avatar),
          );

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}
