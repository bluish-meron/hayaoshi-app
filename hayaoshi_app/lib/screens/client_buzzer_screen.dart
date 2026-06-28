import 'package:flutter/material.dart';

import '../net/client_connection.dart';
import 'disconnected_screen.dart';

class ClientBuzzerScreen extends StatefulWidget {
  const ClientBuzzerScreen({super.key, required this.connection});

  final ClientConnection connection;

  @override
  State<ClientBuzzerScreen> createState() => _ClientBuzzerScreenState();
}

class _ClientBuzzerScreenState extends State<ClientBuzzerScreen> {
  bool _pressed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    widget.connection.lastJudgeCorrect.addListener(_onJudge);
    widget.connection.disconnected.addListener(_onDisconnected);
  }

  void _onJudge() {
    // 新しい問題が始まったら再度押せるようにする
    setState(() => _pressed = false);
  }

  void _onDisconnected() {
    if (_navigated || !widget.connection.disconnected.value) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            const DisconnectedScreen(message: '親機との接続が切れました'),
      ),
    );
  }

  void _onBuzz() {
    if (_pressed) return;
    setState(() => _pressed = true);
    widget.connection.sendBuzz();
  }

  @override
  void dispose() {
    widget.connection.lastJudgeCorrect.removeListener(_onJudge);
    widget.connection.disconnected.removeListener(_onDisconnected);
    if (!_navigated) widget.connection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('子機')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _onBuzz,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pressed ? Colors.grey : Colors.redAccent,
                      boxShadow: _pressed
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        _pressed ? '押した！' : 'PUSH',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<bool?>(
                  valueListenable: widget.connection.lastJudgeCorrect,
                  builder: (context, correct, _) {
                    if (correct == null) return const SizedBox.shrink();
                    return Text(
                      correct ? '正解！' : '不正解',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: correct ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
