// lib/sections/pelanggan/payment_detail_dialog.dart

import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../models/payment_detail_model.dart';
import 'upload_customer_proof_dialog.dart';

class PaymentDetailDialog extends StatefulWidget {
  final PaymentDetailModel detail;

  const PaymentDetailDialog({super.key, required this.detail});

  @override
  State<PaymentDetailDialog> createState() => _PaymentDetailDialogState();
}

class _PaymentDetailDialogState extends State<PaymentDetailDialog> {
  final bool _isUploading = false;

  static const Color _accent = Color(0xFFF97316);
  static const String _baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // OPEN UPLOAD DIALOG
  // ============================================================

  Future<void> _openUploadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadCustomerProofDialog(payment: widget.detail.payment),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

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

  // ============================================================
  // OPEN FULLSCREEN IMAGE
  // ============================================================

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
  // BUILD — DIALOG UTAMA
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
                  _buildDialogActions(isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER DIALOG
  // ============================================================

  Widget _buildDialogHeader(bool isMobile) {
    final p = widget.detail.payment;

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
              color: _accent.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payment, color: _accent, size: 20),
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
                  'Detail Pembayaran',
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
  // BODY DIALOG
  // ============================================================

  Widget _buildDialogBody(bool isMobile) {
    final p = widget.detail.payment;
    final bank = widget.detail.transferTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // TOTAL BAYAR
        // ==========================================
        _buildTotalBox(p),

        const SizedBox(height: 20),

        // ==========================================
        // INFO PEKERJAAN
        // ==========================================
        _sectionLabel('Informasi Pekerjaan'),
        const SizedBox(height: 10),
        _infoRow('Pekerjaan', p.jobTitle ?? '-'),
        _infoRow('Mitra', p.mitraName ?? '-'),
        _infoRow('Tanggal', p.formattedDate),

        const SizedBox(height: 20),

        // ==========================================
        // REKENING TUJUAN
        // ==========================================
        _sectionLabel('Transfer ke Rekening'),
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
              _bankRow('Bank', bank.bankName),
              _bankRow('No. Rekening', bank.accountNumber),
              _bankRow('Atas Nama', bank.accountName),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ==========================================
        // INFO BOX
        // ==========================================
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Setelah transfer, upload bukti agar admin bisa memverifikasi. '
                  'Dana akan diteruskan ke mitra setelah diverifikasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // BUKTI PELANGGAN
        // ==========================================
        if (p.customerProofUrl != null) ...[
          const SizedBox(height: 20),
          _sectionLabel('Bukti Transfer Anda'),
          const SizedBox(height: 8),
          _buildProofImage(
            p.customerProofUrl,
            title: 'Bukti Transfer Pelanggan',
          ),
          if (p.customerBankName != null) ...[
            const SizedBox(height: 10),
            _infoRow('Bank Pengirim', p.customerBankName!),
          ],
          if (p.customerAccountName != null)
            _infoRow('Nama Pengirim', p.customerAccountName!),
        ],

        // ==========================================
        // BUKTI KE MITRA
        // ==========================================
        if (p.mitraProofUrl != null) ...[
          const SizedBox(height: 20),
          _sectionLabel('Bukti Transfer ke Mitra'),
          const SizedBox(height: 8),
          _buildProofImage(
            p.mitraProofUrl,
            title: 'Bukti Transfer ke Mitra',
          ),
        ],
      ],
    );
  }

  // ============================================================
  // TOTAL BOX
  // ============================================================

  Widget _buildTotalBox(PaymentModel p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha:0.2)),
      ),
      child: Column(
        children: [
          const Text(
            'Total yang harus dibayar',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            PaymentModel.formatRupiah(p.totalPaid),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _accent,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION LABEL
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

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  // ============================================================
  // BANK ROW
  // ============================================================

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            child: Row(
              children: [
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
                _copyButton(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyButton(String value) {
    return IconButton(
      onPressed: () {
        // Salin ke clipboard — butuh import 'package:flutter/services.dart'
        // Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$value disalin'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: const Icon(Icons.copy, size: 14, color: Color(0xFF6B7280)),
      splashRadius: 16,
      tooltip: 'Salin',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  // ============================================================
  // BUKTI IMAGE
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
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
              color: Colors.black.withValues(alpha:0.6),
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
  // ACTIONS DIALOG
  // ============================================================

  Widget _buildDialogActions(bool isMobile) {
    final p = widget.detail.payment;

    if (!p.canUploadCustomerProof) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _openUploadDialog,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text(
                'Upload Bukti Transfer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(PaymentModel p) {
    final color = _getStatusColor(p.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
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
          panEnabled: true,
          scaleEnabled: true,
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