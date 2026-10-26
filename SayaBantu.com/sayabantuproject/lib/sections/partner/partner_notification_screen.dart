import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notification_card.dart';
import '../shared/chat_page.dart'; // <-- PASTIKAN PATH INI BENAR (Sesuaikan dengan foldermu)

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

  // ============================================================
  // DESIGN TOKENS
  // ============================================================

  static const Color _accent = AppColors.primaryTeal;
  static const double _gapAfterHeader = 16;
  static const double _gapBetweenSections = 16;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ============================================================
  // FETCH NOTIFIKASI DARI API
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

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.sectionAltLight,
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: _accent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1100;

            final horizontalPadding =
                isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
            final verticalPadding = isMobile ? 16.0 : 28.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: _gapAfterHeader),
                  _buildContent(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Lihat informasi terbaru mengenai pekerjaan dan akun kamu.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: _accent),
        ),
      );
    }

    if (_errorMessage != null) return _buildErrorState(context);
    if (_notifications.isEmpty) return _buildEmptyState(context);

    return Column(
      children: [
        for (int i = 0; i < _notifications.length; i++) ...[
          // GANTI MENJADI CompactNotificationCard DAN TAMBAHKAN onTap
          CompactNotificationCard(
            notification: _notifications[i],
            onTap: () {
              final notif = _notifications[i];
              // Cek jika notifikasi bertipe chat dan ada jobId
              if (notif.type == 'chat' && notif.jobId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      jobId: notif.jobId!,
                      title: 'Chat Koordinasi',
                    ),
                  ),
                );
              }
            },
          ),
          if (i != _notifications.length - 1)
            const SizedBox(height: _gapBetweenSections),
        ],
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFDC2626),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 34,
              color: _accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada notifikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua aktivitas terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }
}