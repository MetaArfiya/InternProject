import '../utils/indonesia_time.dart';

class ChatMessage {
  final int id;
  final String message;
  final bool isMine;
  final String senderName;
  final String senderRole;
  final String? senderPhoto;
  final String time;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isMine,
    required this.senderName,
    required this.senderRole,
    this.senderPhoto,
    required this.time,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = IndonesiaTime.tryParseApiTimestamp(json['created_at']);

    return ChatMessage(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      isMine: json['is_mine'] ?? false,
      senderName: json['sender_name'] ?? '',
      senderRole: _parseRole(json['sender_role']),
      senderPhoto: json['sender_photo'],
      time: createdAt == null
          ? (json['time'] ?? '')
          : _formatWibTime(createdAt),
      createdAt: createdAt == null
          ? IndonesiaTime.nowWall()
          : IndonesiaTime.toWall(createdAt),
    );
  }

  static String _formatWibTime(DateTime timestamp) {
    final wall = IndonesiaTime.toWall(timestamp);
    return '${wall.hour.toString().padLeft(2, '0')}:'
        '${wall.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // HELPER — parse sender_role
  // Backend kadang kirim sebagai String ("Pelanggan")
  // kadang sebagai Map ({"id":4,"role_name":"Pelanggan"})
  // ============================================================
  static String _parseRole(dynamic raw) {
    if (raw == null) return '';

    if (raw is String) return raw;

    if (raw is Map) {
      return (raw['role_name'] ?? raw['name'] ?? '').toString();
    }

    return raw.toString();
  }
}
