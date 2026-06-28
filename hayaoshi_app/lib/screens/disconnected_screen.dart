import 'package:flutter/material.dart';

import 'home_screen.dart';

/// 接続が切れた際に表示する画面。ホームに戻ってやり直してもらう。
class DisconnectedScreen extends StatelessWidget {
  const DisconnectedScreen({super.key, this.message = '接続が切れました'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('接続エラー')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text('相手がアプリを閉じたか、Wi-Fiが切断された可能性があります'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('ホームに戻ってやり直す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
