import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants.dart';

enum StoreKind { appStore, playStore, unsupported }

/// Native store billing only — App Store (iOS) / Google Play (Android).
/// Never uses web checkout or Stripe.
class BillingService extends ChangeNotifier {
  BillingService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool ready = false;
  bool available = false;
  String? lastError;
  ProductDetails? monthlyProduct;
  ProductDetails? quotaProduct;

  /// Called for purchased / restored events (including restorePurchases).
  void Function(PurchaseDetails purchase)? onVerifiedPurchase;

  final _pending = <String, Completer<PurchaseDetails>>{};

  StoreKind get storeKind {
    if (kIsWeb) return StoreKind.unsupported;
    if (Platform.isIOS) return StoreKind.appStore;
    if (Platform.isAndroid) return StoreKind.playStore;
    return StoreKind.unsupported;
  }

  String get storeLabel {
    switch (storeKind) {
      case StoreKind.appStore:
        return 'App Store';
      case StoreKind.playStore:
        return 'Google Play';
      case StoreKind.unsupported:
        return 'App Store / Google Play';
    }
  }

  bool get supportsStoreBilling =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> init() async {
    if (!supportsStoreBilling) {
      available = false;
      ready = true;
      notifyListeners();
      return;
    }

    available = await _iap.isAvailable();
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        lastError = e.toString();
        notifyListeners();
      },
    );

    if (available) {
      await loadProducts();
    }
    ready = true;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    final ids = <String>{
      AppConstants.productMonthly,
      AppConstants.productQuotaMonthly,
    };
    final res = await _iap.queryProductDetails(ids);
    if (res.error != null) {
      lastError = res.error!.message;
    }
    monthlyProduct = null;
    quotaProduct = null;
    for (final p in res.productDetails) {
      if (p.id == AppConstants.productMonthly) monthlyProduct = p;
      if (p.id == AppConstants.productQuotaMonthly) quotaProduct = p;
    }
    notifyListeners();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final completer = _pending[purchase.productID];
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }
      if (completer != null && !completer.isCompleted) {
        completer.complete(purchase);
        _pending.remove(purchase.productID);
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        onVerifiedPurchase?.call(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  /// Opens the native App Store / Play purchase sheet for a subscription.
  Future<PurchaseDetails> purchaseSubscription({required bool quotaPrice}) async {
    if (kIsWeb) {
      throw Exception('DJ Aiodip is a store app — billing is not available on web.');
    }
    if (!supportsStoreBilling) {
      throw Exception(
        'Subscriptions are only available on iPhone (App Store) and Android (Google Play).',
      );
    }
    if (!available) {
      throw Exception(
        'Store billing is unavailable. Install from $storeLabel / use a real device with a store account.',
      );
    }

    if (monthlyProduct == null && quotaProduct == null) {
      await loadProducts();
    }

    final product = quotaPrice ? (quotaProduct ?? monthlyProduct) : monthlyProduct;
    if (product == null) {
      throw Exception(
        'Store product not found. Create "${quotaPrice ? AppConstants.productQuotaMonthly : AppConstants.productMonthly}" '
        'as a subscription in $storeLabel Connect / Play Console.',
      );
    }

    final completer = Completer<PurchaseDetails>();
    _pending[product.id] = completer;

    final param = PurchaseParam(productDetails: product);
    // Subscriptions use buyNonConsumable in the official plugin API.
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _pending.remove(product.id);
      throw Exception('Could not start $storeLabel purchase.');
    }

    final result = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pending.remove(product.id);
        throw Exception('Purchase timed out. Try again.');
      },
    );

    if (result.status == PurchaseStatus.error) {
      throw Exception(result.error?.message ?? 'Purchase failed');
    }
    if (result.status == PurchaseStatus.canceled) {
      throw Exception('Purchase canceled');
    }
    if (result.status != PurchaseStatus.purchased &&
        result.status != PurchaseStatus.restored) {
      throw Exception('Purchase not completed');
    }
    return result;
  }

  Future<void> restorePurchases() async {
    if (!supportsStoreBilling || !available) {
      throw Exception('Restore is only available on App Store / Google Play.');
    }
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
