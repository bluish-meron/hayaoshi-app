import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../main.dart';
import '../services/app_services.dart';

/// Googleが配布しているテスト用バナー広告ユニットID。
/// 本番リリース前に、AdMobで取得した自分の広告ユニットIDに置き換えること。
const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// プレミアム購入済みなら何も表示しない、それ以外はバナー広告を表示するウィジェット。
class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});

  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!supportsAdsAndPurchases) return;
    purchaseService.isPremium.addListener(_onPremiumChanged);
    if (!purchaseService.isPremium.value) {
      _loadAd();
    }
  }

  void _onPremiumChanged() {
    if (purchaseService.isPremium.value) {
      _bannerAd?.dispose();
      setState(() {
        _bannerAd = null;
        _loaded = false;
      });
    } else if (_bannerAd == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _testBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    if (supportsAdsAndPurchases) {
      purchaseService.isPremium.removeListener(_onPremiumChanged);
    }
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsAdsAndPurchases ||
        purchaseService.isPremium.value ||
        !_loaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
