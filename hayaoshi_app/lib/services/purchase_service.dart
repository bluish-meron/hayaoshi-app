import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「広告削除＋人数制限解除」の買い切り課金を管理する。
///
/// Google Playコンソールでアプリ内アイテムを作成し、productIdを
/// [_productId]と一致させること。コンソール側で商品が未作成のうちは
/// queryProductDetailsが空を返すため、購入ボタンは自動的に無効化される。
class PurchaseService {
  static const _productId = 'remove_ads_unlock';
  static const _prefsKey = 'is_premium';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final ValueNotifier<bool> isPremium = ValueNotifier(false);
  final ValueNotifier<ProductDetails?> product = ValueNotifier(null);
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPremium.value = prefs.getBool(_prefsKey) ?? false;

    final available = await _iap.isAvailable();
    if (!available) {
      lastError.value = 'この端末ではストアの購入機能が利用できません';
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => lastError.value = '購入処理でエラーが発生しました: $e',
    );

    final response = await _iap.queryProductDetails({_productId});
    if (response.error != null) {
      lastError.value = '商品情報の取得に失敗しました: ${response.error}';
      return;
    }
    if (response.productDetails.isNotEmpty) {
      product.value = response.productDetails.first;
    } else {
      lastError.value = 'Play Console側で商品(remove_ads_unlock)が未作成です';
    }
  }

  Future<void> buy() async {
    final p = product.value;
    if (p == null) return;
    final param = PurchaseParam(productDetails: p);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _productId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        await _setPremium(true);
      }
      if (purchase.status == PurchaseStatus.error) {
        lastError.value = purchase.error?.message ?? '購入に失敗しました';
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    isPremium.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
