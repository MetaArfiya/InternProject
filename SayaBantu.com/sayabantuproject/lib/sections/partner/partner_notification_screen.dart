import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../widgets/notification_card.dart';

class PartnerNotificationScreen extends StatefulWidget {
  const PartnerNotificationScreen({super.key});

  @override
  State<PartnerNotificationScreen> createState() =>
      _PartnerNotificationScreenState();
}

class _PartnerNotificationScreenState extends State<PartnerNotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ============================================================
  // FETCH NOTIFIKASI DARI API (endpoint sama: /notifications)
  // Backend filter otomatis berdasarkan role yang login
  // ============================================================
  Future<void> _loadNotifications() async {
  if (!mounted) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await ApiService.get('/notifications');

    debugPrint('🔔 [MITRA] NOTIFICATIONS STATUS: ${response.statusCode}');
    debugPrint('🔔 [MITRA] NOTIFICATIONS BODY: ${response.body}');

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // ✅ SESUAI CONTROLLER: pakai key 'notifications'
      final List<dynamic> rawData = body['notifications'] ?? [];

      final loaded = rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (!mounted) return;

      setState(() {
        _notifications = loaded;
        _isLoading = false;
      });
    } else {
      throw Exception('Gagal memuat notifikasi (${response.statusCode})');
    }
  } catch (e) {
    debugPrint('❌ [MITRA] NOTIFICATIONS ERROR: $e');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorMessage = e.toString();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: double.infinity,
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // HEADER
                // ============================================
                Text(
                  'Notifikasi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lihat informasi terbaru mengenai pekerjaan dan akun kamu.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 24),

                // ============================================
                // CONTENT
                // ============================================
                _buildContent(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState(isDark);
    if (_notifications.isEmpty) return _buildEmptyState(isDark);

    return Column(
      children: _notifications.map((notif) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PartnerNotificationCard(notification: notif),
        );
      }).toList(),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================
  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 52,
            color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Semua aktivitas terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}