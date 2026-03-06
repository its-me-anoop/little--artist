import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/premium_provider.dart';
import '../services/haptic_service.dart';
import '../utils/brand_tokens.dart';

/// Full-screen paywall that displays a feature comparison between the free and
/// premium tiers and lets the user subscribe via monthly or yearly plans.
class PaywallView extends ConsumerStatefulWidget {
  const PaywallView({super.key});

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  ProductDetails? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeManagerProvider);
    final monthly = store.monthlyProduct;
    final yearly = store.yearlyProduct;

    // Default to yearly if available.
    _selectedProduct ??= yearly ?? monthly;

    return Scaffold(
      backgroundColor: Brand.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Brand.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Brand.screenPadding,
                ),
                children: [
                  // -------------------------------------------------------------
                  // MARK: - Hero Header
                  // -------------------------------------------------------------
                  _buildHeroHeader(),
                  const SizedBox(height: Brand.sectionSpacing),

                  // -------------------------------------------------------------
                  // MARK: - Feature Comparison
                  // -------------------------------------------------------------
                  _buildFeatureComparison(context),
                  const SizedBox(height: Brand.sectionSpacing),

                  // -------------------------------------------------------------
                  // MARK: - Subscription Cards
                  // -------------------------------------------------------------
                  if (monthly != null)
                    _buildPlanCard(
                      context,
                      product: monthly,
                      label: 'Monthly',
                      isHighlighted: false,
                    ),
                  if (monthly != null && yearly != null)
                    const SizedBox(height: 12),
                  if (yearly != null)
                    _buildPlanCard(
                      context,
                      product: yearly,
                      label: 'Yearly',
                      isHighlighted: true,
                      badge: 'Best Value',
                    ),
                  if (store.products.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Loading plans...',
                        textAlign: TextAlign.center,
                        style: Brand.bodyFont.copyWith(color: Brand.warmGray),
                      ),
                    ),

                  if (store.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      store.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Brand.captionFont.copyWith(color: Brand.dustyRose),
                    ),
                  ],
                  const SizedBox(height: Brand.sectionSpacing),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // MARK: - Bottom Actions
            // -----------------------------------------------------------------
            _buildBottomActions(context, store),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Hero Header
  // ---------------------------------------------------------------------------

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.primary, Color(0xFFE85D2F)],
        ),
        borderRadius: BorderRadius.circular(Brand.radiusCard),
        boxShadow: Brand.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Premium',
            style: Brand.title1Font.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Archive every masterpiece, without limits.',
            style: Brand.bodyFont.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Feature Comparison
  // ---------------------------------------------------------------------------

  Widget _buildFeatureComparison(BuildContext context) {
    const features = [
      _FeatureRow('Children', '2', 'Unlimited'),
      _FeatureRow('Artworks', '50', 'Unlimited'),
      _FeatureRow('Family sharing', null, 'Included'),
      _FeatureRow('Voice memos', null, 'Included'),
      _FeatureRow('Cloud sync', null, 'Included'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Brand.surface,
        borderRadius: BorderRadius.circular(Brand.radiusCard),
        boxShadow: Brand.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Feature',
                    style: Brand.captionFont.copyWith(
                      color: Brand.warmGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: Brand.captionFont.copyWith(
                      color: Brand.warmGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Premium',
                    textAlign: TextAlign.center,
                    style: Brand.captionFont.copyWith(
                      color: Brand.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Brand.softTan),
          ...features.map((f) => _buildFeatureRow(context, f)),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, _FeatureRow feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature.name,
              style: Brand.bodyFont.copyWith(color: Brand.charcoal),
            ),
          ),
          Expanded(
            flex: 2,
            child: feature.freeValue != null
                ? Text(
                    feature.freeValue!,
                    textAlign: TextAlign.center,
                    style: Brand.bodyFont.copyWith(color: Brand.warmGray),
                  )
                : const Icon(Icons.close, size: 20, color: Brand.warmGray),
          ),
          Expanded(
            flex: 2,
            child: feature.premiumValue == 'Included'
                ? const Icon(Icons.check_circle, size: 20, color: Brand.primary)
                : Text(
                    feature.premiumValue,
                    textAlign: TextAlign.center,
                    style: Brand.bodyFont.copyWith(
                      color: Brand.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Plan Card
  // ---------------------------------------------------------------------------

  Widget _buildPlanCard(
    BuildContext context, {
    required ProductDetails product,
    required String label,
    required bool isHighlighted,
    String? badge,
  }) {
    final isSelected = _selectedProduct?.id == product.id;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        setState(() => _selectedProduct = product);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? Brand.primary : Brand.surface,
          borderRadius: BorderRadius.circular(Brand.radiusCard),
          border: Border.all(
            color: isSelected
                ? (isHighlighted ? Colors.white : Brand.primary)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: Brand.cardShadow,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted
                      ? Colors.white
                      : (isSelected ? Brand.primary : Brand.softTan),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHighlighted ? Colors.white : Brand.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: Brand.headlineFont.copyWith(
                          color:
                              isHighlighted ? Colors.white : Brand.charcoal,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isHighlighted
                                ? Colors.white.withValues(alpha: 0.25)
                                : Brand.primaryTint,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badge,
                            style: Brand.caption2Font.copyWith(
                              color: isHighlighted
                                  ? Colors.white
                                  : Brand.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.price,
                    style: Brand.bodyFont.copyWith(
                      color: isHighlighted
                          ? Colors.white.withValues(alpha: 0.9)
                          : Brand.warmGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK: - Bottom Actions
  // ---------------------------------------------------------------------------

  Widget _buildBottomActions(BuildContext context, dynamic store) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Brand.screenPadding,
        12,
        Brand.screenPadding,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Brand.cream,
        border: const Border(
          top: BorderSide(color: Brand.softTan, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subscribe button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: store.isPurchasing || _selectedProduct == null
                  ? null
                  : () {
                      HapticService.medium();
                      store.purchase(_selectedProduct!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Brand.disabled,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Brand.radiusButton),
                ),
                elevation: 0,
              ),
              child: store.isPurchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Subscribe', style: Brand.headlineFont),
            ),
          ),
          const SizedBox(height: 12),

          // Restore purchases
          TextButton(
            onPressed: () {
              HapticService.light();
              ref.read(storeManagerProvider).restorePurchases();
            },
            child: Text(
              'Restore Purchases',
              style: Brand.subheadlineFont.copyWith(color: Brand.warmGray),
            ),
          ),
          const SizedBox(height: 4),

          // Terms & privacy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Open terms of use
                },
                child: Text(
                  'Terms of Use',
                  style: Brand.captionFont.copyWith(
                    color: Brand.warmGray,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '|',
                  style: Brand.captionFont.copyWith(color: Brand.warmGray),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Open privacy policy
                },
                child: Text(
                  'Privacy Policy',
                  style: Brand.captionFont.copyWith(
                    color: Brand.warmGray,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MARK: - Feature Row Model
// ---------------------------------------------------------------------------

class _FeatureRow {
  final String name;
  final String? freeValue;
  final String premiumValue;

  const _FeatureRow(this.name, this.freeValue, this.premiumValue);
}
