import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'client_waiting_screen.dart';

class ClientScanScreen extends StatefulWidget {
  const ClientScanScreen({super.key});

  @override
  State<ClientScanScreen> createState() => _ClientScanScreenState();
}

class _ClientScanScreenState extends State<ClientScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final ip = data['ip'] as String?;
    final port = data['port'] as int?;
    final session = data['session'] as String?;
    if (ip == null || port == null || session == null) return;

    _handled = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ClientWaitingScreen(ip: ip, port: port, sessionId: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('子機 - QRコードを読み取る')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
