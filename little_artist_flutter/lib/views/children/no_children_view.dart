import 'package:flutter/material.dart';

import '../../utils/brand_tokens.dart';

/// Empty state displayed when no children have been added yet.
///
/// Shows a centered illustration with a prompt to add the first child.
class NoChildrenView extends StatelessWidget {
  final VoidCallback onAddChild;

  const NoChildrenView({
    super.key,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Brand.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Brand.warmGray.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No children yet',
              style: Brand.title2Font.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first child to start',
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddChild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: Brand.buttonPadding,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Brand.radiusButton),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add Child',
                  style: Brand.headlineFont.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
