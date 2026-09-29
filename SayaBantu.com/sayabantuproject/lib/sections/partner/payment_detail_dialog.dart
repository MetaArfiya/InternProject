import 'package:flutter/material.dart';

import '../../models/payment_model.dart';

class PaymentDetailMitraDialog extends StatefulWidget {
  final PaymentModel payment;

  const PaymentDetailMitraDialog({super.key, required this.payment});

  @override
  State<PaymentDetailMitraDialog> createState() =>
      _PaymentDetailMitraDialogState();
}

class _PaymentDetailMitraDialogState extends State<PaymentDetailMitraDialog> {
  static const Color _accent = Color(0xFFF97316);
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================

  String _buildProofImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.contains('/payment_proofs/')) {
      final afterPaymentProofs = path.split('/payment_proofs/').last;
      return '$_baseUrl/api/images/payment_proofs/$afterPaymentProofs';
    }

    return '$_baseUrl$path';
  }

  void _openFullScreenImage(String? path, String title) {
    final url = _buildProofImageUrl(path);
    if (url.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImageViewer(
          imageUrl: url,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 700;

          final dialogWidth = isMobile
              ? screenWidth - 32
              : (screenWidth * 0.7).clamp(500.0, 640.0);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogHeader(isMobile),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 16 : 22),
                      child: _buildDialogBody(isMobile),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _buildDialogFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildDialogHeader(bool isMobile) {
    final p = widget.payment;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 22,
        isMobile ? 14 : 18,
        isMobile ? 12 : 16,
        isMobile ? 14 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAY-${p.id.toString().padLeft(3, '0')}',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detail Pendapatan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(p),
          SizedBox(width: isMobile ? 4 : 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
            splashRadius: 22,
            tooltip: 'Tutup',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildDialogBody(bool isMobile) {
    final p = widget.payment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTotalBox(p),
        const SizedBox(height: 20),

        // INFO PEKERJAAN
        _sectionLabel('Informasi Pekerjaan'),
        const SizedBox(height: 10),
        _infoRow('Pekerjaan', p.jobTitle ?? '-'),
        _infoRow('Pelanggan', p.pelangganName ?? '-'),
        _infoRow('Tanggal', p.formattedDate),

        const SizedBox(height: 20),

        // RINCIAN PEMBAYARAN
        _sectionLabel('Rincian Pembayaran'),
        const SizedBox(height: 10),
        _infoRow(
          'Nilai pekerjaan',
          PaymentModel.formatRupiah(p.jobAmount),
        ),
        _infoRow(
          'Komisi platform (${p.commissionPercent.toStringAsFixed(0)}%)',
          '- ${PaymentModel.formatRupiah(p.commissionAmount)}',
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pendapatan Anda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              Text(
                PaymentModel.formatRupiah(p.mitraEarning),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // REKENING MITRA
        _buildMitraBankSection(p),

        // BUKTI DARI PELANGGAN
        if (p.customerProofUrl != null) ...[
          const SizedBox(height: 20),
          _sectionLabel('Bukti Transfer Pelanggan'),
          const SizedBox(height: 8),
          _buildProofImage(
            p.customerProofUrl,
            title: 'Bukti Transfer Pelanggan',
          ),
        ],

        // BUKTI KE MITRA
        if (p.mitraProofUrl != null) ...[
          const SizedBox(height: 20),
          _sectionLabel('Bukti Transfer ke Rekening Anda'),
          const SizedBox(height: 8),
          _buildProofImage(
            p.mitraProofUrl,
            title: 'Bukti Transfer ke Mitra',
          ),
        ],

        // TIMELINE
        const SizedBox(height: 20),
        _sectionLabel('Riwayat'),
        const SizedBox(height: 10),
        _buildTimeline(p),
      ],
    );
  }

  Widget _buildTotalBox(PaymentModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Text(
            'Total Pendapatan Anda',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            PaymentModel.formatRupiah(p.mitraEarning),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitraBankSection(PaymentModel p) {
    final bank = p.mitraBank;

    if (bank == null || bank.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Rekening belum terdaftar. Hubungi admin untuk info transfer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Rekening Penerima'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              _bankRow('Bank', bank['bank_name']?.toString() ?? '-'),
              _bankRow(
                  'No. Rekening', bank['account_number']?.toString() ?? '-'),
              _bankRow(
                  'Atas Nama', bank['account_name']?.toString() ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Widget _buildTimeline(PaymentModel p) {
    final items = <Widget>[];

    if (p.createdAt != null) {
      items.add(_timelineItem(
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF6B7280),
        label: 'Pembayaran dibuat',
        date: p.createdAt!,
      ));
    }

    if (p.customerProofUploadedAt != null) {
      items.add(_timelineItem(
        icon: Icons.upload_file,
        color: const Color(0xFF2563EB),
        label: 'Pelanggan upload bukti transfer',
        date: p.customerProofUploadedAt!,
      ));
    }

    if (p.paidAt != null) {
      items.add(_timelineItem(
        icon: Icons.verified_outlined,
        color: const Color(0xFF7C3AED),
        label: 'Pembayaran diverifikasi admin',
        date: p.paidAt!,
      ));
    }

    if (p.mitraProofUploadedAt != null) {
      items.add(_timelineItem(
        icon: Icons.check_circle_outline,
        color: const Color(0xFF16A34A),
        label: 'Dana ditransfer ke rekening Anda',
        date: p.mitraProofUploadedAt!,
      ));
    }

    if (items.isEmpty) {
      return const Text(
        'Belum ada riwayat.',
        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      );
    }

    return Column(children: items);
  }

  Widget _timelineItem({
    required IconData icon,
    required Color color,
    required String label,
    required DateTime date,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(date),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hh:$mm';
  }

  // ============================================================
  // PROOF IMAGE
  // ============================================================

  Widget _buildProofImage(
    String? path, {
    double height = 180,
    String title = 'Bukti Transfer',
  }) {
    final url = _buildProofImageUrl(path);

    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text(
            'Bukti belum diunggah',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openFullScreenImage(path, title),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: height,
                  color: const Color(0xFFF9FAFB),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        color: Colors.grey.shade400, size: 42),
                    const SizedBox(height: 8),
                    const Text(
                      'Gagal memuat gambar',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Perbesar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
  // FOOTER
  // ============================================================

  Widget _buildDialogFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Tutup',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PaymentModel p) {
    final color = _getStatusColor(p.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.statusLabel,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'settled':
        return const Color(0xFF16A34A);
      case 'paid':
        return const Color(0xFF2563EB);
      case 'waiting_verification':
        return const Color(0xFF7C3AED);
      case 'pending':
        return const Color(0xFFD97706);
      case 'refunded':
      case 'failed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ================================================================
// FULLSCREEN IMAGE VIEWER
// ================================================================

class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String title;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.title,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final TransformationController _transformCtrl = TransformationController();
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformCtrl.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformCtrl.removeListener(_onTransformChanged);
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              tooltip: 'Reset Zoom',
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFF97316)),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Text(
          'Pinch untuk zoom • Drag untuk geser',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}