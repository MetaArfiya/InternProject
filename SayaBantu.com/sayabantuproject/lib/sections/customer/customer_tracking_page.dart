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

  const CustomerTrackingPage({super.key, required this.jobId});

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
    // Polling tiap 5 detik
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
      final response =
          await ApiService.get('/jobs/${widget.jobId}/tracking');

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
    Navigator.push(
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
        title: const Text('Lacak Mitra'),
        actions: [
          IconButton(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat Mitra',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryTeal),
              )
            : _error != null
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    final t = _tracking;
    if (t == null) {
      return const Center(child: Text('Data tracking tidak tersedia.'));
    }

    final active = t.isActive;

    return Column(
      children: [
        // ========================================================
        // PETA
        // ========================================================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TrackingMap(tracking: t, showMitra: active),
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
                // HEADER — kode job + status badge
                // ------------------------------------------------
                Row(
                  children: [
                    Text(
                      t.jobCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (t.status != null) _statusBadge(t.status!),
                  ],
                ),

                const SizedBox(height: 4),

                // ------------------------------------------------
                // JUDUL PEKERJAAN
                // ------------------------------------------------
                Text(
                  t.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // CARD GRID — Jarak + Estimasi
                // ------------------------------------------------
                if (active &&
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
                // UPDATE TERAKHIR
                // ------------------------------------------------
                if (t.mitraUpdatedAt != null)
                  Row(
                    children: [
                      const Icon(Icons.refresh,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 6),
                      Text(
                        'Posisi diperbarui: ${_timeAgo(t.mitraUpdatedAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 16),

                // ------------------------------------------------
                // TOMBOL CHAT MITRA
                // ------------------------------------------------
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
                      'Chat Mitra',
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
  // HELPER — Info Card (kotak kecil untuk grid 2 kolom)
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
      'menuju': 'Mitra sedang menuju',
      'sampai': 'Mitra sudah sampai',
      'dikerjakan': 'Pekerjaan dikerjakan',
      'selesai': 'Pekerjaan selesai',
    };

    final color = colors[status] ?? AppColors.grey500;
    final label = labels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // HELPER — Time Ago
  // ============================================================

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} detik lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}