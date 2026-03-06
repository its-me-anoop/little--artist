import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'premium_manager.dart';

/// Manages App Store / Play Store subscriptions via the `in_app_purchase`
/// plugin. Exposes products, purchase state, and premium status as a
/// [ChangeNotifier] so Riverpod can watch it reactively.
class StoreManager extends ChangeNotifier {
  static const _monthlyId = 'com.flutterly.littleartist.premium.monthly';
  static const _yearlyId = 'com.flutterly.littleartist.premium.yearly';
  static final Set<String> _productIds = {_monthlyId, _yearlyId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = [];
  bool isPremium = false;
  bool isPurchasing = false;
  String? errorMessage;

  ProductDetails? get monthlyProduct =>
      products.where((p) => p.id == _monthlyId).firstOrNull;

  ProductDetails? get yearlyProduct =>
      products.where((p) => p.id == _yearlyId).firstOrNull;

  StoreManager() {
    _init();
  }

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        errorMessage = error.toString();
        notifyListeners();
      },
    );

    await loadProducts();
    await updateSubscriptionStatus();
  }

  /// Fetch product details from the store.
  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      errorMessage = response.error!.message;
      notifyListeners();
      return;
    }
    products = response.productDetails
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    notifyListeners();
  }

  /// Initiate a purchase for the given [product].
  Future<void> purchase(ProductDetails product) async {
    isPurchasing = true;
    errorMessage = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Ask the store to re-deliver any previously purchased subscriptions.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliver(purchase);
        case PurchaseStatus.error:
          isPurchasing = false;
          errorMessage = purchase.error?.message ?? 'Purchase failed';
          notifyListeners();
        case PurchaseStatus.canceled:
          isPurchasing = false;
          notifyListeners();
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // In production, verify the receipt server-side before granting access.
    isPremium = true;
    isPurchasing = false;
    await PremiumManager.setIsPremium(true);
    notifyListeners();
  }

  /// Synchronise with the persisted premium flag on startup.
  Future<void> updateSubscriptionStatus() async {
    await PremiumManager.loadStatus();
    isPremium = PremiumManager.isPremium;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
