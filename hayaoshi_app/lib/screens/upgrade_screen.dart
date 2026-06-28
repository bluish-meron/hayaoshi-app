import 'package:flutter/material.dart';

import '../main.dart';
import '../services/app_services.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('広告削除 / 人数制限解除')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '購入すると、広告が消え、参加人数の制限(親機含め$freePlayerLimit人まで)が解除されます',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            if (!supportsAdsAndPurchases)
              const Text('この端末(デスクトップ)では購入機能を利用できません')
            else
              ValueListenableBuilder<bool>(
                valueListenable: purchaseService.isPremium,
                builder: (context, isPremium, _) {
                  if (isPremium) {
                    return const Text(
                      '購入済みです。ご利用ありがとうございます！',
                      style: TextStyle(fontSize: 16),
                    );
                  }
                  return Column(
                    children: [
                      ValueListenableBuilder(
                        valueListenable: purchaseService.product,
                        builder: (context, product, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: product == null
                                  ? null
                                  : purchaseService.buy,
                              child: Text(
                                product == null
                                    ? '商品情報を取得中…'
                                    : '購入する (${product.price})',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: purchaseService.restorePurchases,
                        child: const Text('購入を復元する'),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: purchaseService.lastError,
                        builder: (context, error, _) {
                          if (error == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
