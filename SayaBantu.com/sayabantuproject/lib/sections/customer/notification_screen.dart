import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // SPACING — mengikuti pola DashboardHeader
  // ============================================================
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
  // ✅ Padding horizontal: mobile 16 / tablet 24 / desktop 28
  // ✅ Tanpa Center + ConstrainedBox — konten nempel kiri
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
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
            color: const Color(0xFFF97316),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER — sama persis dgn "Pekerjaan Saya"
                  // ============================================
                  Text(
                    'Notifikasi',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Semua aktivitas terbaru akan muncul di sini.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: _gapAfterHeader),

                  // ============================================
                  // CONTENT
                  // ============================================
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
        return CompactNotificationCard(
          notification: _notifications[index],
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
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat notifikasi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
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
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 24,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada notifikasi',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Semua aktivitas terbaru akan muncul di sini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}