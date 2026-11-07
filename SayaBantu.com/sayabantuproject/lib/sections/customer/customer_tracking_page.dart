import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/tracking_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/tracking_map.dart';
import '../shared/chat_page.dart';

class CustomerTrackingPage extends StatefulWidget {
  final int jobId;
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenChat;

  const CustomerTrackingPage({
    super.key,
    required this.jobId,
    this.onBack,
    this.onOpenChat,
  });

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  TrackingModel? _tracking;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Polling tiap 5 detik agar posisi mitra selalu update
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // FETCH DATA
  // ============================================================
  Future<void> _fetch() async {
    try {
      final response = await ApiService.get('/jobs/${widget.jobId}/tracking');

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Gagal memuat (${response.statusCode})';
          });
        }
        return;
      }

      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = body['message']?.toString() ?? 'Gagal memuat';
          });
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _tracking = TrackingModel.fromJson(
          Map<String, dynamic>.from(body['data']),
        );
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  // ============================================================
  // BUKA CHAT
  // ============================================================
  void _openChat() {
    final title = _tracking?.title ?? 'Pekerjaan #${widget.jobId}';
    if (widget.onOpenChat != null) {
      widget.onOpenChat!(title);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          jobId: widget.jobId,
          title: title,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD (RESPONSIVE LAYOUT)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sectionAltLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.onBack == null,
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Kembali',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: const Text('Lacak Mitra'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryTeal),
              )
            : _error != null
                ? _buildError()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 900;

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KIRI: Peta
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
                            // KANAN: Detail
                            Expanded(
                              flex: 4,
                              child: _buildDetailPanel(isDesktop: true),
                            ),
                          ],
                        );
                      }

                      // MOBILE: Atas-Bawah
                      return Column(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight * 0.45,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildMap(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailPanel(isDesktop: false),
                          ),
                        ],
                      );
                    },
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
    final active = t?.isActive ?? false;

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
            // Header Kode & Status
            Row(
              children: [
                Text(
                  t?.jobCode ?? '#JOB-${widget.jobId}',
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

            // Judul Pekerjaan
            Text(
              t?.title ?? 'Pekerjaan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 20),

            // Info Jarak & ETA (Hanya muncul jika mitra sedang aktif jalan)
            if (active && (t?.distanceKm != null || t?.etaMinutes != null)) ...[
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      Icons.straighten,
                      'Jarak',
                      t?.distanceKm != null
                          ? '${t!.distanceKm!.toStringAsFixed(2)} km'
                          : '-',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoCard(
                      Icons.schedule,
                      'Estimasi',
                      t?.etaMinutes != null ? '${t!.etaMinutes} menit' : '-',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Alamat & Waktu Mulai
            if (t?.pickupAddress?.isNotEmpty == true) ...[
              _infoRow(
                icon: Icons.store_outlined,
                label: 'Lokasi Ambil',
                value: t!.pickupAddress!,
              ),
              const SizedBox(height: 12),
            ],
            _infoRow(
              icon: Icons.location_on_outlined,
              label: t?.pickupAddress?.isNotEmpty == true
                  ? 'Lokasi Serah / Tujuan'
                  : 'Alamat Tujuan',
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

            // Update Terakhir
            if (t?.mitraUpdatedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.refresh, size: 14, color: AppColors.grey500),
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

            const SizedBox(height: 24),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 24),

            // Tombol Chat
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text(
                  'Chat Mitra',
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
  // HELPER WIDGETS & FORMATTERS
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
      'mengantar': const Color(0xFF0F766E),
      'sampai': const Color(0xFF2563EB),
      'dikerjakan': const Color(0xFFF59E0B),
      'selesai': const Color(0xFF16A34A),
    };
    final labels = {
      'menuju': 'Menuju Lokasi',
      'mengantar': 'Mitra Mengantar ke Lokasi Serah',
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
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    try {
      // Kita anggap waktu dari server adalah UTC.
      // Buat objek UTC manual dari dt, lalu tambahkan 7 jam.
      final utcTime = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      final local = utcTime.add(const Duration(hours: 7));

      final d = local.day.toString().padLeft(2, '0');
      final m = bulan[local.month - 1];
      final y = local.year;
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      
      return '$d $m $y • $hh:$mm';
    } catch (e) {
      // Jika gagal, kembalikan format standar
      final d = dt.day.toString().padLeft(2, '0');
      final m = bulan[dt.month - 1];
      final y = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d $m $y • $hh:$mm';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _fetch();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
