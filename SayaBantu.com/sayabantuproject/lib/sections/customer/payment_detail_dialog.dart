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
  bool _isUploading = false;

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
    double height = 180,
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

  @override
  Widget build(BuildContext context) {
    final p = widget.detail.payment;
    final bank = widget.detail.transferTo;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.payment, color: Colors.orange),
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
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total yang harus dibayar',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PaymentModel.formatRupiah(p.totalPaid),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _infoRow('Pekerjaan', p.jobTitle ?? '-'),
              _infoRow('Mitra', p.mitraName ?? '-'),
              _infoRow('Tanggal', p.formattedDate),
              const Divider(height: 28),
              const Text(
                'Transfer ke Rekening:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Setelah transfer, upload bukti transfer agar admin bisa memverifikasi. '
                        'Dana akan diteruskan ke mitra setelah diverifikasi.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.customerProofUrl != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Bukti transfer yang sudah diunggah:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
              if (p.mitraProofUrl != null) ...[
                const Divider(height: 28),
                const Text(
                  'Bukti Transfer ke Mitra:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildProofImage(
                  p.mitraProofUrl,
                  title: 'Bukti Transfer ke Mitra',
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        if (p.canUploadCustomerProof)
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _openUploadDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Bukti Transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
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