import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../net/host_server.dart';
import '../services/app_services.dart';
import 'host_judge_screen.dart';

class HostQrScreen extends StatefulWidget {
  const HostQrScreen({super.key});

  @override
  State<HostQrScreen> createState() => _HostQrScreenState();
}

class _HostQrScreenState extends State<HostQrScreen> {
  late final HostServer _server = HostServer(
    maxClients: purchaseService.isPremium.value ? null : freeClientLimit,
  );
  final String _sessionId = _generateSessionId();
  String? _qrData;
  String? _error;
  bool _handedOff = false;

  static String _generateSessionId() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      final ip = await _server.start();
      setState(() {
        _qrData = jsonEncode({
          'ip': ip,
          'port': _server.port,
          'session': _sessionId,
        });
      });
    } catch (e) {
      setState(() => _error = 'サーバーの起動に失敗しました: $e');
    }
  }

  @override
  void dispose() {
    // 判定画面に引き渡した場合はそちらのdisposeで停止するため、ここでは閉じない。
    if (!_handedOff) _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('親機 - 子機を接続')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '子機でQRコードを読み取ってください\n(同じWi-Fiに接続してください)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_qrData == null)
              const CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(data: _qrData!, size: 240),
              ),
            const SizedBox(height: 12),
            Text('セッションID: $_sessionId'),
            const SizedBox(height: 24),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _server.connectedNames,
                builder: (context, names, _) {
                  return ListView.builder(
                    itemCount: names.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.smartphone),
                      title: Text(names[index]),
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<List<String>>(
              valueListenable: _server.connectedNames,
              builder: (context, names, _) {
                final limit = _server.maxClients;
                return Text(
                  limit == null
                      ? '接続中の子機: ${names.length}台'
                      : '接続中の子機: ${names.length}/$limit台'
                          ' (無料版は親機含め$freePlayerLimit人まで)',
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<String>>(
              valueListenable: _server.connectedNames,
              builder: (context, names, _) => SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: names.isEmpty
                      ? null
                      : () {
                          _server.closeLobbyAndStart();
                          _handedOff = true;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => HostJudgeScreen(server: _server),
                            ),
                          );
                        },
                  child: const Text('締め切って開始', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
