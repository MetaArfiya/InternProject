import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/page_header.dart';
import '../../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await ApiService.get('/notifications');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // 🛠️ AMBIL LIST DARI KEY 'notifications' SESUAI DEBUG
        List dataList = [];
        if (jsonResponse is Map && jsonResponse['notifications'] is List) {
          dataList = jsonResponse['notifications'];
        } else if (jsonResponse is List) {
          dataList = jsonResponse;
        }

        setState(() {
          _notifications = dataList.map((item) {
            final notificationData = item is Map ? (item['data'] ?? {}) : {};
            final String dbType = item is Map ? (item['type'] ?? '') : '';

            // 🛠️ AMBIL TITLE & MESSAGE (Utamakan dari data database, jika kosong gunakan fallback)
            String title = notificationData['title'] ?? notificationData['tittle'] ?? '';
            String message = notificationData['message'] ?? '';

            // Jika judul kosong, tentukan berdasarkan tipe notifikasi
            if (title.isEmpty) {
              if (dbType.contains('NewBidReceived')) {
                title = 'Penawaran Baru';
              } else if (dbType.contains('BidAccepted')) {
                title = 'Penawaran Diterima';
              } else if (dbType.contains('JobProcessedNotification')) {
                title = 'Pekerjaan Diproses';
              } else if (dbType.contains('JobCompletedNotification')) {
                title = 'Pekerjaan Selesai';
              } else if (dbType.contains('WelcomeNotification')) {
                title = 'Selamat Datang';
              } else {
                title = 'Notifikasi Baru';
              }
            }

            // Jika message kosong di data, berikan pesan default
            if (message.isEmpty) {
              message = 'Anda memiliki aktivitas baru.';
            }
            
            return NotificationModel(
              title: title,
              message: message,
              time: _formatTimestamp(item is Map ? item['created_at'] : null),
              type: _mapNotificationType(dbType),
            );
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat notifikasi (Kode: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
        _isLoading = false;
      });
    }
  }

  String _mapNotificationType(String? dbType) {
    if (dbType == null) return 'system';
    if (dbType.contains('NewBidReceived')) return 'offer';
    if (dbType.contains('JobProcessedNotification')) return 'progress';
    if (dbType.contains('JobCompletedNotification')) return 'done';
    return 'system';
  }

  String _formatTimestamp(String? dateStr) {
    if (dateStr == null) return 'Baru saja';
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(dateTime);
      if (diff.inMinutes < 60) {
        return "${diff.inMinutes} menit lalu";
      } else if (diff.inHours < 24) {
        return "${diff.inHours} jam lalu";
      } else {
        return "${diff.inDays} hari lalu";
      }
    } catch (_) {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: "Notifikasi",
                    subtitle: "Semua aktivitas terbaru akan muncul di sini.",
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                            ? Center(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : _notifications.isEmpty
                                ? const Center(
                                    child: Text(
                                      "Belum ada notifikasi.",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _notifications.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      return NotificationCard(
                                        notification: _notifications[index],
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}