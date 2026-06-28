import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'messages.dart';

class _ConnectedClient {
  _ConnectedClient(this.socket);

  final Socket socket;
  String name = '(接続中)';
  final StringBuffer buffer = StringBuffer();
}

/// 親機側のTCPサーバー。子機からの接続、時刻同期要求、早押し通知を処理する。
class HostServer {
  /// [maxClients]がnullなら人数無制限(課金済み)。指定すると、それを超える接続は拒否する。
  HostServer({this.maxClients});

  final int? maxClients;

  ServerSocket? _server;
  final List<_ConnectedClient> _clients = [];

  final ValueNotifier<List<String>> connectedNames = ValueNotifier([]);
  final ValueNotifier<List<BuzzEvent>> buzzOrder = ValueNotifier([]);

  int get port => _server?.port ?? 0;

  Future<String> start() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleConnection);
    return await _resolveLocalIp();
  }

  void _handleConnection(Socket socket) {
    final limit = maxClients;
    if (limit != null && _clients.length >= limit) {
      socket.write(
        WireMessage.encode({'type': 'reject', 'reason': 'full'}),
      );
      socket.close();
      return;
    }

    final client = _ConnectedClient(socket);
    _clients.add(client);

    socket.listen(
      (data) {
        client.buffer.write(utf8.decode(data, allowMalformed: true));
        for (final msg in WireMessage.drainLines(client.buffer)) {
          _handleMessage(client, msg);
        }
      },
      onDone: () => _removeClient(client),
      onError: (_) => _removeClient(client),
    );
  }

  void _handleMessage(_ConnectedClient client, Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'hello':
        client.name = (msg['name'] as String?) ?? client.name;
        _notifyNames();
      case 'sync_req':
        final serverTime = DateTime.now().toUtc().microsecondsSinceEpoch;
        _send(client.socket, {
          'type': 'sync_res',
          't0': msg['t0'],
          'serverTime': serverTime,
        });
      case 'buzz':
        final time = DateTime.parse(msg['time'] as String);
        _addBuzz(client.name, time);
    }
  }

  int _arrivalCounter = 0;

  void _addBuzz(String name, DateTime time) {
    final list = List<BuzzEvent>.from(buzzOrder.value);
    if (list.any((e) => e.name == name)) return;
    list.add(BuzzEvent(name, time, _arrivalCounter++));
    // タイムスタンプが同一(マイクロ秒単位でも区別できない)場合は、
    // 親機への到着順(arrivalSeq)を優先してタイブレークする。
    // List.sortは同値要素の順序を保証しないため、time.compareToだけでは決定的にならない。
    list.sort((a, b) {
      final cmp = a.time.compareTo(b.time);
      return cmp != 0 ? cmp : a.arrivalSeq.compareTo(b.arrivalSeq);
    });
    buzzOrder.value = list;
  }

  void _removeClient(_ConnectedClient client) {
    _clients.remove(client);
    _notifyNames();
  }

  void _notifyNames() {
    connectedNames.value = _clients.map((c) => c.name).toList();
  }

  void closeLobbyAndStart() {
    for (final client in _clients) {
      _send(client.socket, {'type': 'start'});
    }
  }

  void judgeTopAnswer(bool correct) {
    if (buzzOrder.value.isEmpty) return;
    final top = buzzOrder.value.first;
    final client = _clients.firstWhere(
      (c) => c.name == top.name,
      orElse: () => _clients.first,
    );
    _send(client.socket, {'type': 'judge', 'correct': correct});
    buzzOrder.value = buzzOrder.value.skip(1).toList();
  }

  void resetBuzzes() {
    buzzOrder.value = [];
  }

  void _send(Socket socket, Map<String, dynamic> data) {
    socket.write(WireMessage.encode(data));
  }

  Future<String> _resolveLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }

  void dispose() {
    for (final client in _clients) {
      client.socket.destroy();
    }
    _server?.close();
  }
}
