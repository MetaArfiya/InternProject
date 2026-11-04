import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/tracking_model.dart';
import '../../services/api_service.dart';
import '../../services/tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/indonesia_time.dart';
import '../../widgets/tracking_map.dart';
import '../shared/chat_page.dart';
import '../partner/completion_proof_dialog.dart';

class PartnerTrackingPage extends StatefulWidget {
  final int jobId;
  final String jobCode;
  final String title;
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenChat;

  const PartnerTrackingPage({
    super.key,
    required this.jobId,
    required this.jobCode,
    required this.title,
    this.onBack,
    this.onOpenChat,
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
      final response = await ApiService.get('/jobs/${widget.jobId}/tracking');

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
  // MULAI & STOP TRACKING
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
          content: Text('Gagal memulai tracking. Cek izin lokasi browser.'),
        ),
      );
      return;
    }

    await ApiService.post('/jobs/${widget.jobId}/tracking/status', {
      'status': 'menuju',
    });

    if (!mounted) return;
    setState(() => _isTracking = true);
    _loadInitial();
  }

  Future<void> _updateStatus(String status) async {
    await ApiService.post('/jobs/${widget.jobId}/tracking/status', {
      'status': status,
    });
    _loadInitial();
  }

  Future<void> _markArrived() async {
    await TrackingService.instance.stopTracking();
    final response = await ApiService.post(
      '/jobs/${widget.jobId}/tracking/status',
      {'status': 'selesai'},
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() => _isTracking = false);
      await _loadInitial();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status perjalanan.')),
      );
    }
  }

  // ============================================================
  // UPLOAD BUKTI
  // ============================================================
  Future<void> _showUploadProof() async {
    final result = await showDialog<CompletionProofResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompletionProofDialog(jobId: widget.jobId),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti pekerjaan berhasil dikirim.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    }
  }

  // ============================================================
  // BUKA CHAT
  // ============================================================
  void _openChat() {
    if (widget.onOpenChat != null) {
      widget.onOpenChat!(widget.title);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(jobId: widget.jobId, title: widget.title),
      ),
    );
  }

  // ============================================================
  // BUILD (RESPONSIVE LAYOUT)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBack?.call();
      },
      child: Scaffold(
        backgroundColor: AppColors.sectionAltLight,
        appBar: AppBar(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: widget.onBack == null,
          leading: widget.onBack == null
              ? null
              : IconButton(
                  tooltip: 'Kembali ke penawaran aktif',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Detail & Tracking'),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildMap(),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: _buildDetailPanel(isDesktop: true),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight * 0.4,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildMap(),
                            ),
                          ),
                        ),
                        Expanded(child: _buildDetailPanel(isDesktop: false)),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ============================================================
  // KOMPONEN PETA
  // ============================================================
  Widget _buildMap() {
    if (_tracking == null) {
      return Container(
        color: AppColors.grey100,
        child: const Center(child: Text('Data tracking tidak tersedia.')),
      );
    }
    return TrackingMap(tracking: _tracking!, showMitra: _tracking!.isActive);
  }

  // ============================================================
  // KOMPONEN PANEL DETAIL
  // ============================================================
  Widget _buildDetailPanel({required bool isDesktop}) {
    final t = _tracking;
    // Status perjalanan selesai saat mitra mengonfirmasi sudah sampai.
    final bool isArrived = t?.status == 'sampai' || t?.status == 'selesai';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? const BorderRadius.horizontal(left: Radius.circular(20))
            : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.jobCode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(width: 8),
                if (t?.status != null) _statusBadge(t!.status!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 20),

            // Info Jarak & ETA
            if (t != null &&
                (t.distanceKm != null || t.etaMinutes != null)) ...[
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      Icons.straighten,
                      'Jarak',
                      t.distanceKm != null
                          ? '${t.distanceKm!.toStringAsFixed(2)} km'
                          : '-',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoCard(
                      Icons.schedule,
                      'Estimasi',
                      t.etaMinutes != null ? '${t.etaMinutes} menit' : '-',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Alamat & Waktu Mulai
            _infoRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat Tujuan',
              value: t?.destinationAddress?.isNotEmpty == true
                  ? t!.destinationAddress!
                  : '-',
            ),
            if (t?.startedAt != null) ...[
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.play_circle_outline,
                label: 'Waktu Mulai',
                value: _formatDateTime(t!.startedAt!),
              ),
            ],

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 24),

            // TIMELINE PEKERJAAN
            const Text(
              'Timeline Pekerjaan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 16),

            _timelineItem(
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xff16A34A),
              title: 'Pekerjaan Dimulai',
              subtitle: 'Mitra menyetujui harga dan jadwal pelanggan',
              time: t?.startedAt != null
                  ? _formatDateTime(t!.startedAt!)
                  : null,
              isActive: t?.startedAt != null,
            ),
            _timelineItem(
              icon: Icons.construction_outlined,
              iconColor: const Color(0xffF59E0B),
              title: 'Sedang Dikerjakan',
              subtitle: 'Mitra mengerjakan pekerjaan',
              time: t?.startedAt != null && t?.status != 'selesai'
                  ? 'Dalam proses'
                  : null,
              isActive: t?.startedAt != null && t?.status != 'selesai',
            ),
            _timelineItem(
              icon: Icons.upload_file_outlined,
              iconColor: const Color(0xff2563EB),
              title: 'Bukti Diupload',
              subtitle: 'Mitra upload bukti penyelesaian',
              time: null,
              isActive: false,
            ),
            _timelineItem(
              icon: Icons.verified_outlined,
              iconColor: AppColors.primaryTeal,
              title: 'Diverifikasi Pelanggan',
              subtitle: 'Pelanggan menyetujui bukti (ACC)',
              time: null,
              isActive: false,
              isLast: true,
            ),

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 24),

            // TOMBOL AKSI BERDASARKAN STATUS
            if (!_isTracking && !isArrived) ...[
              // 1. Tampil jika BELUM tracking
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _startTracking,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Mulai Perjalanan (GPS)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
              ),
            ] else if (_isTracking && !isArrived) ...[
              // 2. Tampil jika SEDANG tracking (belum sampai)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markArrived,
                      icon: const Icon(Icons.place, size: 16),
                      label: const Text('Sudah Sampai'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 3. Tombol Upload Bukti (Hanya muncul jika sudah "Sampai")
            if (isArrived) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showUploadProof,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text(
                    'Pekerjaan Selesai (Upload Bukti)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.darkTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text(
                  'Chat Pelanggan',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================
  Widget _timelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? time,
    required bool isActive,
    bool isLast = false,
  }) {
    final Color finalColor = isActive ? iconColor : AppColors.grey400;
    final Color bgColor = isActive
        ? iconColor.withValues(alpha: 0.12)
        : AppColors.grey100;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: finalColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isActive
                        ? iconColor.withValues(alpha: 0.4)
                        : AppColors.grey200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.grey900 : AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey600,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isActive ? iconColor : AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? iconColor : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          child: Icon(icon, size: 16, color: AppColors.primaryTeal),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  String _formatDateTime(DateTime dt) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    try {
      // Paksa anggap waktu dari API adalah UTC, lalu tambahkan 7 jam (WIB)
      final utcTime = DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
      );
      final local = utcTime.add(const Duration(hours: 7));

      final d = local.day.toString().padLeft(2, '0');
      final m = bulan[local.month - 1];
      final y = local.year;
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');

      return '$d $m $y • $hh:$mm';
    } catch (e) {
      // Jika gagal, kembalikan format standar tanpa konversi
      final d = dt.day.toString().padLeft(2, '0');
      final m = bulan[dt.month - 1];
      final y = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d $m $y • $hh:$mm';
    }
  }
}
