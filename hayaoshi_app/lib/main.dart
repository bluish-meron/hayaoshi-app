import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/home_screen.dart';
import 'services/app_services.dart';

/// 広告/課金SDKはAndroid・iOSのみ対応。Windows/Webデスクトップでは初期化しない。
bool get supportsAdsAndPurchases =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supportsAdsAndPurchases) {
    await MobileAds.instance.initialize();
    await purchaseService.init();
  }
  runApp(const HayaoshiApp());
}

class HayaoshiApp extends StatelessWidget {
  const HayaoshiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '早押し機',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
