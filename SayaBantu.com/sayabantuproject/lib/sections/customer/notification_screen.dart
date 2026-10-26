import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/notification_card.dart';
import '../shared/chat_page.dart'; // <-- PASTIKAN PATH INI BENAR (Sesuaikan dengan foldermu)

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const double _gapAfterHeader = 16;

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

      debugPrint('🔔 NOTIFICATIONS STATUS: ${response.statusCode}');
      debugPrint('🔔 NOTIFICATIONS BODY: ${response.body}');

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
      debugPrint('❌ NOTIFICATIONS ERROR: $e');

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
      color: AppColors.sectionAltLight, // ← mint muda
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 700;
          final isTablet = width >= 700 && width < 1100;

          final horizontalPadding =
              isMobile ? 16.0 : (isTablet ? 24.0 : 28.0);
          final verticalPadding = isMobile ? 16.0 : 28.0;

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppColors.primaryTeal, // ← dari orange
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Semua aktivitas terbaru akan muncul di sini.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),

                  const SizedBox(height: _gapAfterHeader),

                  _buildContent(context, isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState(context);
    if (_notifications.isEmpty) return _buildEmptyState(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = _notifications[index];

        return CompactNotificationCard(
          notification: notif,
          onTap: () {
            // Cek jika ini notifikasi chat dan ada jobId
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
        );
      },
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================
  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================
  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal, // ← teal
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.15), // ← dari grey soft
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: AppColors.primaryTeal, // ← dari grey
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Semua aktivitas terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}