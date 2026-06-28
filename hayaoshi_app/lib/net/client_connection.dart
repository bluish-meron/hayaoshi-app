import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'messages.dart';

/// 子機側のTCPクライアント。親機への接続、NTP方式の時刻同期、早押し送信を行う。
class ClientConnection {
  ClientConnection({required this.name});

  final String name;

  Socket? _socket;
  final StringBuffer _buffer = StringBuffer();
  Completer<int>? _pendingSync;

  Duration _offset = Duration.zero;

  final ValueNotifier<bool> started = ValueNotifier(false);
  final ValueNotifier<bool?> lastJudgeCorrect = ValueNotifier(null);
  final ValueNotifier<bool> disconnected = ValueNotifier(false);
  final ValueNotifier<String?> rejectedReason = ValueNotifier(null);

  bool _disposed = false;

  Future<void> connect(String ip, int port) async {
    _socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 8),
    );
    _socket!.listen(
      (data) {
        _buffer.write(utf8.decode(data, allowMalformed: true));
        for (final msg in WireMessage.drainLines(_buffer)) {
          _handleMessage(msg);
        }
      },
      onDone: _markDisconnected,
      onError: (_) => _markDisconnected(),
    );
  _send({'type': 'hello', 'name': name});
  }

  void _markDisconnected() {
    if (_disposed) return;
    started.value = false;
    disconnected.value = true;
  }

  void _handleMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'sync_res':
        _pendingSync?.complete(msg['serverTime'] as int);
      case 'start':
        started.value = true;
      case 'judge':
        lastJudgeCorrect.value = msg['correct'] as bool;
      case 'reject':
        rejectedReason.value = (msg['reason'] as String?) ?? 'unknown';
    }
  }

  /// 往復遅延を複数回計測し、最小RTTのサンプルからクロックのオフセットを推定する(NTP方式)。
  Future<void> syncClock({int samples = 5}) async {
    Duration bestRtt = const Duration(days: 999);
    Duration bestOffset = Duration.zero;

    for (var i = 0; i < samples; i++) {
      final completer = Completer<int>();
      _pendingSync = completer;

      final t0 = DateTime.now().toUtc().microsecondsSinceEpoch;
      _send({'type': 'sync_req', 't0': t0});

      final serverTime = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      final t3 = DateTime.now().toUtc().microsecondsSinceEpoch;

      final rtt = Duration(microseconds: t3 - t0);
      final estimatedOffset = Duration(
        microseconds: serverTime - ((t0 + t3) ~/ 2),
      );

      if (rtt < bestRtt) {
        bestRtt = rtt;
        bestOffset = estimatedOffset;
      }
    }

    _offset = bestOffset;
  }

  DateTime correctedNow() => DateTime.now().toUtc().add(_offset);

  void sendBuzz() {
    _send({
      'type': 'buzz',
      'name': name,
      'time': correctedNow().toIso8601String(),
    });
  }

  void _send(Map<String, dynamic> data) {
    _socket?.write(WireMessage.encode(data));
  }

  void dispose() {
    _disposed = true;
    _socket?.destroy();
  }
}
