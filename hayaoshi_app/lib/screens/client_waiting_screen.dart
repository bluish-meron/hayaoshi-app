import 'dart:math';

import 'package:flutter/material.dart';

import '../net/client_connection.dart';
import 'client_buzzer_screen.dart';
import 'disconnected_screen.dart';

class ClientWaitingScreen extends StatefulWidget {
  const ClientWaitingScreen({
    super.key,
    required this.ip,
    required this.port,
    required this.sessionId,
  });

  final String ip;
  final int port;
  final String sessionId;

  @override
  State<ClientWaitingScreen> createState() => _ClientWaitingScreenState();
}

class _ClientWaitingScreenState extends State<ClientWaitingScreen> {
  late final ClientConnection _connection = ClientConnection(
    name: '子機${Random().nextInt(9000) + 1000}',
  );

  String _status = '接続しています…';
  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _connect();
    _connection.started.addListener(_onStarted);
    _connection.disconnected.addListener(_onDisconnected);
    _connection.rejectedReason.addListener(_onRejected);
  }

  Future<void> _connect() async {
    try {
      await _connection.connect(widget.ip, widget.port);
      setState(() => _status = '時刻を同期しています…');
      await _connection.syncClock();
      setState(() => _status = '親機が締め切るまでお待ちください');
    } catch (e) {
      setState(() => _error = '接続に失敗しました: $e');
    }
  }

  void _onStarted() {
    if (_navigated || !_connection.started.value) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClientBuzzerScreen(connection: _connection),
      ),
    );
  }

  void _onDisconnected() {
    if (_navigated || !_connection.disconnected.value) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const DisconnectedScreen(message: '親機との接続が切れました'),
      ),
    );
  }

  void _onRejected() {
    if (_navigated || _connection.rejectedReason.value == null) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DisconnectedScreen(
          message: 'このセッションは満員です\n(無料版は同時に参加できる人数に上限があります)',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connection.started.removeListener(_onStarted);
    _connection.disconnected.removeListener(_onDisconnected);
    _connection.rejectedReason.removeListener(_onRejected);
    if (!_navigated) _connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('接続')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error == null) const CircularProgressIndicator(),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else
              Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('セッションID: ${widget.sessionId}'),
          ],
        ),
      ),
    );
  }
}
