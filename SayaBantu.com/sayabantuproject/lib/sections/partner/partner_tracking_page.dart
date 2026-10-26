import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/tracking_model.dart';
import '../../services/api_service.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tracking_map.dart';
import '../shared/chat_page.dart';

class PartnerTrackingPage extends StatefulWidget {
  final int jobId;
  final String jobCode;
  final String title;

  const PartnerTrackingPage({
    super.key,
    required this.jobId,
    required this.jobCode,
    required this.title,
  });

  @override
  State<PartnerTrackingPage> createState() => _PartnerTrackingPageState();
}

class _PartnerTrackingPageState extends State<PartnerTrackingPage> {
  TrackingModel? _tracking;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    TrackingService.instance.stopTracking();
    super.dispose();
  }

  // ============================================================
  // LOAD INITIAL
  // ============================================================

  Future<void> _loadInitial() async {
    try {
      final response =
          await ApiService.get('/jobs/${widget.jobId}/tracking');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          if (!mounted) return;
          setState(() {
            _tracking = TrackingModel.fromJson(
              Map<String, dynamic>.from(body['data']),
            );
            _isTracking = TrackingService.instance.isRunning;
          });
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // ============================================================
  // MULAI TRACKING
  // ============================================================

  Future<void> _startTracking() async {
    final ok = await TrackingService.instance.startTracking(
      widget.jobId,
      interval: const Duration(seconds: 10),
    );

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Gagal memulai tracking. Cek izin lokasi browser.'),
        ),
      );
      return;
    }

    await ApiService.post(
      '/jobs/${widget.jobId}/tracking/status',
      {'status': 'menuju'},
    );

    if (!mounted) return;
    setState(() => _isTracking = true);
    _loadInitial();
  }

  // ============================================================
  // STOP TRACKING
  // ============================================================

  Future<void> _stopTracking() async {
    await TrackingService.instance.stopTracking();
    await ApiService.post('/jobs/${widget.jobId}/tracking/stop', {});
    if (!mounted) return;
    setState(() => _isTracking = false);
    _loadInitial();
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(String status) async {
    await ApiService.post(
      '/jobs/${widget.jobId}/tracking/status',
      {'status': status},
    );
    _loadInitial();
  }

  // ============================================================
  // BUKA CHAT
  // ============================================================

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          jobId: widget.jobId,
          title: widget.title,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tracking Perjalanan'),
        actions: [
          IconButton(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat Pelanggan',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryTeal,
                ),
              )
            : _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

    Widget _buildBody() {
    final t = _tracking;

    return Column(
      children: [
        // ========================================================
        // PETA
        // ========================================================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: t == null
                ? const Center(
                    child: Text('Data tracking tidak tersedia.'),
                  )
                : TrackingMap(tracking: t, showMitra: t.isActive),
          ),
        ),

        // ========================================================
        // PANEL BAWAH
        // ========================================================
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // HEADER — kode + chip status
                // ------------------------------------------------
                Row(
                  children: [
                    Text(
                      widget.jobCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (t?.status != null) _statusBadge(t!.status!),
                  ],
                ),

                const SizedBox(height: 4),

                // ------------------------------------------------
                // JUDUL PEKERJAAN
                // ------------------------------------------------
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // CARD GRID — Jarak + Estimasi (2 kolom)
                // ------------------------------------------------
                if (t != null &&
                    (t.distanceKm != null || t.etaMinutes != null)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          Icons.straighten,
                          'Jarak ke Tujuan',
                          t.distanceKm != null
                              ? '${t.distanceKm!.toStringAsFixed(2)} km'
                              : '-',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          Icons.schedule,
                          'Estimasi Tiba',
                          t.etaMinutes != null
                              ? '${t.etaMinutes} menit'
                              : '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ------------------------------------------------
                // ALAMAT TUJUAN (full width)
                // ------------------------------------------------
                _infoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Tujuan',
                  value: t?.destinationAddress?.isNotEmpty == true
                      ? t!.destinationAddress!
                      : '-',
                ),

                // ------------------------------------------------
                // MULAI PERJALANAN (kalau ada)
                // ------------------------------------------------
                if (t?.startedAt != null) ...[
                  const SizedBox(height: 12),
                  _infoRow(
                    icon: Icons.play_circle_outline,
                    label: 'Mulai Perjalanan',
                    value: _formatDateTime(t!.startedAt!),
                  ),
                ],

                // ------------------------------------------------
                // UPDATE TERAKHIR
                // ------------------------------------------------
                if (t?.mitraUpdatedAt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.refresh,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 6),
                      Text(
                        'Posisi diperbarui: ${_timeAgo(t!.mitraUpdatedAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 16),

                // ------------------------------------------------
                // TOMBOL AKSI
                // ------------------------------------------------
                if (!_isTracking)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _startTracking,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Mulai Perjalanan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus('sampai'),
                          icon: const Icon(Icons.place, size: 16),
                          label: const Text('Sudah Sampai'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: AppColors.primaryTeal,
                            side: const BorderSide(
                              color: AppColors.primaryTeal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus('selesai'),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Selesai'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            foregroundColor: AppColors.success,
                            side: const BorderSide(
                              color: AppColors.success,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton.icon(
                      onPressed: _stopTracking,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Hentikan Tracking'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
                ],

                // ------------------------------------------------
                // TOMBOL CHAT
                // ------------------------------------------------
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Chat Pelanggan',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(
                        color: AppColors.primaryTeal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPER — Info Card (kartu kotak untuk grid 2 kolom)
  // ============================================================

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER — Status Badge
  // ============================================================

  Widget _statusBadge(String status) {
    final colors = {
      'menuju': const Color(0xFF0F766E),
      'sampai': const Color(0xFF2563EB),
      'dikerjakan': const Color(0xFFF59E0B),
      'selesai': const Color(0xFF16A34A),
    };
    final labels = {
      'menuju': 'Menuju Lokasi',
      'sampai': 'Sudah Sampai',
      'dikerjakan': 'Dikerjakan',
      'selesai': 'Selesai',
    };

    final color = colors[status] ?? AppColors.grey500;
    final label = labels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // HELPER — Info Row
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey900,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPER — Format DateTime
  // ============================================================

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final d = local.day.toString().padLeft(2, '0');
    final m = bulan[local.month - 1];
    final y = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d $m $y • $hh:$mm';
  }

  // ============================================================
  // HELPER — Time Ago
  // ============================================================

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik lalu';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    return '${diff.inDays} hari lalu';
  }
}