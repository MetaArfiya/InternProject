import 'dart:convert';

import '../models/chat_message.dart';
import 'api_service.dart';

class ChatService {
  static Future<List<ChatMessage>> getMessages(int jobId) async {
    final res = await ApiService.get('/jobs/$jobId/chat');

    if (res.statusCode != 200) {
      throw Exception(
        'Gagal memuat pesan (${res.statusCode}): ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat pesan.');
    }

    final list = (body['data'] as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    return list;
  }

  static Future<ChatMessage> sendMessage(int jobId, String message) async {
    final res = await ApiService.post(
      '/jobs/$jobId/chat',
      {'message': message},
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Gagal kirim pesan (${res.statusCode}): ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal kirim pesan.');
    }

    return ChatMessage.fromJson(body['data'] as Map<String, dynamic>);
  }
}