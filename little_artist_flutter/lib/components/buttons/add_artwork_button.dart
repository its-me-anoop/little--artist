import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Floating action button for adding new artwork. Uses a custom Container
/// instead of FloatingActionButton to apply the brand FAB shadow.
class AddArtworkButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddArtworkButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: Brand.fabSize,
        height: Brand.fabSize,
        decoration: BoxDecoration(
          color: Brand.primary,
          shape: BoxShape.circle,
          boxShadow: Brand.fabShadow,
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
