// lib/sections/admin/admin_payment_detail_dialog.dart

import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import 'upload_mitra_proof_dialog.dart';

class AdminPaymentDetailDialog extends StatefulWidget {
  final PaymentModel payment;

  const AdminPaymentDetailDialog({super.key, required this.payment});

  @override
  State<AdminPaymentDetailDialog> createState() =>
      _AdminPaymentDetailDialogState();
}

class _AdminPaymentDetailDialogState extends State<AdminPaymentDetailDialog> {
  bool _isProcessing = false;

  // ============================================================
  // VERIFIKASI BUKTI PELANGGAN
  // ============================================================
  Future<void> _verifyProof(String action) async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'approve' ? 'Verifikasi Bukti' : 'Tolak Bukti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action == 'approve'
                  ? 'Konfirmasi bahwa bukti transfer pelanggan valid?'
                  : 'Berikan alasan penolakan bukti transfer pelanggan.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: action == 'approve'
                    ? 'Catatan (opsional)'
                    : 'Alasan penolakan *',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'approve' ? Colors.blue : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'approve' ? 'Verifikasi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (action == 'reject' && noteCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan penolakan wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final success = await PaymentService.verifyCustomerProof(
      paymentId: widget.payment.id,
      action: action,
      note: noteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Bukti berhasil diverifikasi. Siap transfer ke mitra.'
                : 'Bukti ditolak. Pelanggan perlu upload ulang.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memproses. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SETTLE — Transfer ke mitra
  // ============================================================
  Future<void> _settleToMitra() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UploadMitraProofDialog(payment: widget.payment),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // REFUND
  // ============================================================
  Future<void> _refund() async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund ke Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kembalikan dana ${PaymentModel.formatRupiah(widget.payment.totalPaid)} ke pelanggan?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Alasan refund *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (reasonCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan refund wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final success = await PaymentService.refund(
      paymentId: widget.payment.id,
      reason: reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil direfund.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal refund. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
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
      return '${_baseImageUrl()}/api/images/payment_proofs/$afterPaymentProofs';
    }

    return '${_baseImageUrl()}$path';
  }

  // ============================================================
  // BUKA FULLSCREEN IMAGE VIEWER
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
  // WIDGET GAMBAR BUKTI (KLIK UNTUK FULLSCREEN)
  // ============================================================
  Widget _buildProofImage(
    String? path, {
    double height = 200,
    String title = 'Bukti Transfer',
  }) {
    final url = _buildProofImageUrl(path);

    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'Bukti belum diunggah',
            style: TextStyle(color: Colors.grey),
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
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        url,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_in, color: Colors.white, size: 16),
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
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final bank = p.mitraBank ?? {};

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PAY-${p.id.toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          _statusBadge(p),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Pekerjaan', p.jobTitle ?? '-'),
              _infoRow('Pelanggan', p.pelangganName ?? '-'),
              _infoRow('Mitra', p.mitraName ?? '-'),
              _infoRow('Tanggal', p.formattedDate),
              const Divider(height: 25),
              _infoRow('Nilai Pekerjaan',
                  PaymentModel.formatRupiah(p.jobAmount)),
              _infoRow(
                'Komisi (${p.commissionPercent.toStringAsFixed(0)}%)',
                PaymentModel.formatRupiah(p.commissionAmount),
              ),
              _infoRow(
                'Mitra Terima',
                PaymentModel.formatRupiah(p.mitraEarning),
                isBold: true,
              ),
              if (p.customerProofUrl != null) ...[
                const Divider(height: 25),
                const Text(
                  'Bukti Transfer dari Pelanggan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _buildProofImage(
                  p.customerProofUrl,
                  title: 'Bukti Transfer Pelanggan',
                ),
                const SizedBox(height: 10),
                if (p.customerBankName != null)
                  _infoRow('Bank Pengirim', p.customerBankName!),
                if (p.customerAccountName != null)
                  _infoRow('Nama Pengirim', p.customerAccountName!),
              ],
              if (p.canSettleToMitra) ...[
                const Divider(height: 25),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transfer ke Rekening Mitra:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _bankRow('Bank', bank['bank_name']?.toString() ?? '-'),
                      _bankRow('No. Rekening',
                          bank['account_number']?.toString() ?? '-'),
                      _bankRow('Atas Nama',
                          bank['account_name']?.toString() ?? '-'),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumlah:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            PaymentModel.formatRupiah(p.mitraEarning),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (p.mitraProofUrl != null) ...[
                const Divider(height: 25),
                const Text(
                  'Bukti Transfer ke Mitra:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _buildProofImage(
                  p.mitraProofUrl,
                  title: 'Bukti Transfer ke Mitra',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: _buildActions(),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================
  List<Widget> _buildActions() {
    final p = widget.payment;
    final actions = <Widget>[];

    if (p.canVerifyCustomerProof) {
      actions.add(
        TextButton(
          onPressed: _isProcessing ? null : () => _verifyProof('reject'),
          child: const Text('Tolak Bukti',
              style: TextStyle(color: Colors.red)),
        ),
      );
      actions.add(
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _verifyProof('approve'),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Verifikasi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (p.canSettleToMitra) {
      actions.add(
        TextButton(
          onPressed: _isProcessing ? null : _refund,
          child: const Text('Refund',
              style: TextStyle(color: Colors.red)),
        ),
      );
      actions.add(
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _settleToMitra,
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Transfer ke Mitra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    if (p.isPending) {
      actions.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            'Menunggu pelanggan transfer...',
            style: TextStyle(color: Colors.orange, fontSize: 13),
          ),
        ),
      );
    }

    actions.add(
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    );

    return actions;
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'settled':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'waiting_verification':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      case 'refunded':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _baseImageUrl() {
    return 'http://127.0.0.1:8000';
  }
}

// ================================================================
// FULLSCREEN IMAGE VIEWER — FIX: HANYA 1 TOMBOL X
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
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // ✅ HANYA tampilkan Reset Zoom kalau sedang di-zoom
          // Tombol X TIDAK perlu karena fullscreenDialog sudah otomatis
          // menampilkan tombol close di kiri AppBar
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
                child: CircularProgressIndicator(color: Colors.orange),
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