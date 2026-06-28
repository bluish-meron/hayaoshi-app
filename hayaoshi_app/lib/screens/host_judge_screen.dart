import 'package:flutter/material.dart';

import '../net/host_server.dart';
import '../net/messages.dart';
import 'home_screen.dart';

class HostJudgeScreen extends StatefulWidget {
  const HostJudgeScreen({super.key, required this.server});

  final HostServer server;

  @override
  State<HostJudgeScreen> createState() => _HostJudgeScreenState();
}

class _HostJudgeScreenState extends State<HostJudgeScreen> {
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    widget.server.connectedNames.addListener(_onClientsChanged);
  }

  void _onClientsChanged() {
    if (_alertShown) return;
    if (widget.server.connectedNames.value.isEmpty) {
      _alertShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('子機が切断されました'),
          content: const Text('すべての子機との接続が切れました。子機がアプリを閉じたか、Wi-Fiが切断された可能性があります。'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.server.connectedNames.removeListener(_onClientsChanged);
    widget.server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('親機 - 判定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '解答順をリセット',
            onPressed: widget.server.resetBuzzes,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<BuzzEvent>>(
        valueListenable: widget.server.buzzOrder,
        builder: (context, buzzOrder, _) {
          final top = buzzOrder.isNotEmpty ? buzzOrder.first : null;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      top == null ? '解答者待ち…' : '解答者: ${top.name}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: top == null
                            ? null
                            : () => widget.server.judgeTopAnswer(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('正解', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: top == null
                            ? null
                            : () => widget.server.judgeTopAnswer(false),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('誤答', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('解答順', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: buzzOrder.length,
                    itemBuilder: (context, index) {
                      final entry = buzzOrder[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(entry.name),
                        trailing: Text(
                          entry.time.toIso8601String().substring(11, 23),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
