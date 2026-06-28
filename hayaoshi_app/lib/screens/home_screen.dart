import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../widgets/banner_ad_box.dart';
import 'client_scan_screen.dart';
import 'host_qr_screen.dart';
import 'upgrade_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('早押し機'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: purchaseService.isPremium,
            builder: (context, isPremium, _) {
              if (isPremium) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.workspace_premium),
                tooltip: '広告削除・人数制限解除',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'モードを選んでください',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HostQrScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            '親機として始める',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ClientScanScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            '子機として参加する',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}
