import 'dart:convert';

/// 改行区切りJSONでソケット越しにやり取りするメッセージのエンコード/デコード。
class WireMessage {
  static String encode(Map<String, dynamic> data) => '${jsonEncode(data)}\n';

  /// バッファに溜まったバイト列から、改行で区切られた完全な行だけを取り出す。
  /// 残りは呼び出し元のバッファに残す。
  static List<Map<String, dynamic>> drainLines(StringBuffer buffer) {
    final text = buffer.toString();
    final lines = text.split('\n');
    if (lines.isEmpty) return [];
    final incomplete = lines.removeLast();
    buffer
      ..clear()
      ..write(incomplete);
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }
}

class BuzzEvent {
  BuzzEvent(this.name, this.time, this.arrivalSeq);

  final String name;
  final DateTime time;

  /// 親機がこの早押しを受信した順番。タイムスタンプが完全に一致した場合の
  /// タイブレークに使う(受信順を優先=先にパケットが届いた方を早押し勝ちとする)。
  final int arrivalSeq;
}
