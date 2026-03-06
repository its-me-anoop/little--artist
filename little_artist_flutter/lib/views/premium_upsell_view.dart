import 'package:flutter/material.dart';

import '../utils/brand_tokens.dart';

/// A compact card dialog that prompts the user to upgrade to premium when they
/// hit a free-tier limit. Designed for use with [showDialog].
///
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => PremiumUpsellView(
///     title: 'Child Limit Reached',
///     message: 'Upgrade to premium for unlimited children.',
///     onUpgrade: () { ... },
///     onDismiss: () => Navigator.pop(context),
///   ),
/// );
/// ```
class PremiumUpsellView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  const PremiumUpsellView({
    super.key,
    required this.title,
    required this.message,
    required this.onUpgrade,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Brand.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Brand.radiusSheet),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Brand.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 32,
                color: Brand.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: Brand.title3Font.copyWith(color: Brand.charcoal),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Brand.bodyFont.copyWith(color: Brand.warmGray),
            ),
            const SizedBox(height: 24),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Brand.radiusButton),
                  ),
                  elevation: 0,
                ),
                child: Text('Upgrade', style: Brand.headlineFont),
              ),
            ),
            const SizedBox(height: 8),

            // Not Now button
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Not Now',
                style: Brand.subheadlineFont.copyWith(color: Brand.warmGray),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
