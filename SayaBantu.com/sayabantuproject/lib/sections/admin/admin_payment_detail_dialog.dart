import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';
import 'upload_mitra_proof_dialog.dart';

class AdminPaymentDetailDialog extends StatefulWidget {
  final PaymentModel payment;

  const AdminPaymentDetailDialog({super.key, required this.payment});

  @override
  State<AdminPaymentDetailDialog> createState() =>
      _AdminPaymentDetailDialogState();
}

class _AdminPaymentDetailDialogState
    extends State<AdminPaymentDetailDialog> {
  bool _isProcessing = false;

  // ============================================================
  // TOKENS
  // ============================================================

  static const double _radius = 10;

  // ============================================================
  // THEME — ambil dari context yang disediakan AdminThemeProvider
  // ============================================================

  AdminTheme _themeOf(BuildContext context) =>
      AdminThemeProvider.of(context);

  // ============================================================
  // VERIFIKASI BUKTI PELANGGAN
  // ============================================================

  Future<void> _verifyProof(String action) async {
    final noteCtrl = TextEditingController();
    final isApprove = action == 'approve';
    final t = _themeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: (isApprove
                                    ? AppColors.infoBlue
                                    : t.danger)
                                .withValues(alpha:0.12),
                            borderRadius:
                                BorderRadius.circular(_radius),
                          ),
                          child: Icon(
                            isApprove
                                ? Icons.verified_outlined
                                : Icons.cancel_outlined,
                            color: isApprove
                                ? AppColors.infoBlue
                                : t.danger,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isApprove
                                ? 'Verifikasi Bukti'
                                : 'Tolak Bukti',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: t.cellText,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: t.headerText,
                          ),
                          splashRadius: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: t.divider),
                    const SizedBox(height: 16),

                    Text(
                      isApprove
                          ? 'Konfirmasi bahwa bukti transfer pelanggan valid?'
                          : 'Berikan alasan penolakan bukti transfer pelanggan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isApprove
                            ? 'Catatan (opsional)'
                            : 'Alasan penolakan *',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey400,
                        ),
                        filled: true,
                        fillColor: AppColors.grey50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(color: t.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(color: t.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(
                            color: t.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              foregroundColor: AppColors.grey700,
                              side: const BorderSide(
                                color: AppColors.grey300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isApprove
                                  ? AppColors.infoBlue
                                  : t.danger,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: Text(
                              isApprove ? 'Verifikasi' : 'Tolak',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    if (action == 'reject' && noteCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      _showSnack('Alasan penolakan wajib diisi.', error: true);
      return;
    }

    setState(() => _isProcessing = true);

    final result = await PaymentService.verifyCustomerProof(
      paymentId: widget.payment.id,
      action: action,
      note: noteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      Navigator.pop(context, true);
      _showSnack(
        action == 'approve'
            ? 'Bukti berhasil diverifikasi. Siap transfer ke mitra.'
            : 'Bukti ditolak. Pelanggan perlu upload ulang.',
      );
    } else {
      _showSnack(
        result.message ?? 'Gagal memproses. Coba lagi.',
        error: true,
      );
    }
  }

  // ============================================================
  // SETTLE
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
    final t = _themeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AdminThemeProvider(
          theme: t,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: t.danger.withValues(alpha:0.12),
                            borderRadius:
                                BorderRadius.circular(_radius),
                          ),
                          child: Icon(
                            Icons.assignment_return_outlined,
                            color: t.danger,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Refund ke Pelanggan',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: t.cellText,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: t.headerText,
                          ),
                          splashRadius: 22,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(height: 1, color: t.divider),
                    const SizedBox(height: 16),

                    Text(
                      'Kembalikan dana ${PaymentModel.formatRupiah(widget.payment.totalPaid)} ke pelanggan?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Alasan refund *',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grey400,
                        ),
                        filled: true,
                        fillColor: AppColors.grey50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(color: t.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(color: t.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(_radius),
                          borderSide: BorderSide(
                            color: t.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              foregroundColor: AppColors.grey700,
                              side: const BorderSide(
                                color: AppColors.grey300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.danger,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size(0, 46),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_radius),
                              ),
                            ),
                            child: const Text(
                              'Refund',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    if (reasonCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      _showSnack('Alasan refund wajib diisi.', error: true);
      return;
    }

    setState(() => _isProcessing = true);

    final result = await PaymentService.refund(
      paymentId: widget.payment.id,
      reason: reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      Navigator.pop(context, true);
      _showSnack('Pembayaran berhasil direfund.');
    } else {
      _showSnack(
        result.message ?? 'Gagal refund. Coba lagi.',
        error: true,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    final t = _themeOf(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? t.danger : t.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  String _baseImageUrl() => 'http://127.0.0.1:8000';

  // ============================================================
  // FULLSCREEN VIEWER
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
  // WIDGET GAMBAR BUKTI
  // ============================================================

  Widget _buildProofImage(
    String? path, {
    double height = 200,
    String title = 'Bukti Transfer',
  }) {
    final t = _themeOf(context);
    final url = _buildProofImageUrl(path);

    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Text(
            'Bukti belum diunggah',
            style: TextStyle(
              color: t.headerText,
              fontSize: 12.5,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openFullScreenImage(path, title),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Image.network(
              url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: height,
                  color: AppColors.grey50,
                  child: Center(
                    child: CircularProgressIndicator(color: t.accent),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: t.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      color: AppColors.grey400,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(
                        color: t.headerText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Text(
                        url,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.grey400,
                          fontSize: 10,
                        ),
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
              color: AppColors.black.withValues(alpha:0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.zoom_in,
                  color: AppColors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Perbesar',
                  style: TextStyle(
                    color: AppColors.white,
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
    final t = _themeOf(context);
    final p = widget.payment;
    final bank = p.mitraBank ?? {};

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================
              // HEADER
              // ============================================
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: t.accent.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: t.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PAY-${p.id.toString().padLeft(3, '0')}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.cellText,
                          ),
                    ),
                  ),
                  _statusBadge(p, t),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: t.headerText,
                    ),
                    splashRadius: 22,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: t.divider),
              const SizedBox(height: 16),

              // ============================================
              // CONTENT
              // ============================================
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _infoRow('Pekerjaan', p.jobTitle ?? '-', t),
                      _infoRow('Pelanggan', p.pelangganName ?? '-', t),
                      _infoRow('Mitra', p.mitraName ?? '-', t),
                      _infoRow('Tanggal', p.formattedDate, t),

                      Divider(height: 25, color: t.divider),

                      _infoRow(
                        'Nilai Pekerjaan',
                        PaymentModel.formatRupiah(p.jobAmount),
                        t,
                      ),
                      _infoRow(
                        'Komisi (${p.commissionPercent.toStringAsFixed(0)}%)',
                        PaymentModel.formatRupiah(p.commissionAmount),
                        t,
                      ),
                      _infoRow(
                        'Mitra Terima',
                        PaymentModel.formatRupiah(p.mitraEarning),
                        t,
                        isBold: true,
                      ),

                      // Bukti dari pelanggan
                      if (p.customerProofUrl != null) ...[
                        Divider(height: 25, color: t.divider),
                        Text(
                          'Bukti Transfer dari Pelanggan',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: t.cellText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildProofImage(
                          p.customerProofUrl,
                          title: 'Bukti Transfer Pelanggan',
                        ),
                        const SizedBox(height: 10),
                        if (p.customerBankName != null)
                          _infoRow(
                            'Bank Pengirim',
                            p.customerBankName!,
                            t,
                          ),
                        if (p.customerAccountName != null)
                          _infoRow(
                            'Nama Pengirim',
                            p.customerAccountName!,
                            t,
                          ),
                      ],

                      // Rekening mitra
                      if (p.canSettleToMitra) ...[
                        Divider(height: 25, color: t.divider),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: t.success.withValues(alpha:0.06),
                            borderRadius:
                                BorderRadius.circular(_radius),
                            border: Border.all(
                              color: t.success.withValues(alpha:0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transfer ke Rekening Mitra',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: t.cellText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _bankRow(
                                'Bank',
                                bank['bank_name']?.toString() ?? '-',
                                t,
                              ),
                              _bankRow(
                                'No. Rekening',
                                bank['account_number']?.toString() ??
                                    '-',
                                t,
                              ),
                              _bankRow(
                                'Atas Nama',
                                bank['account_name']?.toString() ?? '-',
                                t,
                              ),
                              Divider(height: 18, color: t.divider),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Jumlah:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: t.cellText,
                                    ),
                                  ),
                                  Text(
                                    PaymentModel.formatRupiah(
                                      p.mitraEarning,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: t.success,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Bukti transfer ke mitra
                      if (p.mitraProofUrl != null) ...[
                        Divider(height: 25, color: t.divider),
                        Text(
                          'Bukti Transfer ke Mitra',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: t.cellText,
                          ),
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

              const SizedBox(height: 20),

              // ============================================
              // ACTIONS
              // ============================================
              _buildActions(t),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(AdminTheme t) {
    final p = widget.payment;

    // Pending — belum ada aksi
    if (p.isPending) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: t.accent.withValues(alpha:0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_top,
                    color: t.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menunggu pelanggan transfer...',
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: AppColors.grey700,
              side: const BorderSide(color: AppColors.grey300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Kiri: tombol sekunder
        if (p.canVerifyCustomerProof)
          TextButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _verifyProof('reject'),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text(
              'Tolak',
              style: TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: t.danger,
            ),
          ),

        if (p.canSettleToMitra)
          TextButton.icon(
            onPressed: _isProcessing ? null : _refund,
            icon: const Icon(
              Icons.assignment_return_outlined,
              size: 16,
            ),
            label: const Text(
              'Refund',
              style: TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: t.danger,
            ),
          ),

        const Spacer(),

        // Tutup
        if (!p.canVerifyCustomerProof && !p.canSettleToMitra)
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: AppColors.grey700,
              side: const BorderSide(color: AppColors.grey300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Aksi utama
        if (p.canVerifyCustomerProof) ...[
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _verifyProof('approve'),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 18),
            label: const Text(
              'Verifikasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.infoBlue,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, 46),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),
        ],

        if (p.canSettleToMitra) ...[
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _settleToMitra,
            icon: const Icon(Icons.send, size: 18),
            label: const Text(
              'Transfer ke Mitra',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.success,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, 46),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _infoRow(
    String label,
    String value,
    AdminTheme t, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: t.headerText,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 13.5 : 13,
                fontWeight:
                    isBold ? FontWeight.w700 : FontWeight.w500,
                color: t.cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value, AdminTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: t.headerText,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: t.headerText,
              fontSize: 12.5,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: t.cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PaymentModel p, AdminTheme t) {
    final color = _getStatusColor(p.status, t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
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

  Color _getStatusColor(String status, AdminTheme t) {
    switch (status) {
      case 'settled':
        return t.success;
      case 'paid':
        return AppColors.infoBlue;
      case 'waiting_verification':
        return AppColors.purple;
      case 'pending':
        return t.accent;
      case 'refunded':
      case 'failed':
        return t.danger;
      default:
        return t.headerText;
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
  State<_FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState
    extends State<_FullScreenImageViewer> {
  final TransformationController _transformCtrl =
      TransformationController();
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
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
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
                child: CircularProgressIndicator(
                  color: AppColors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: AppColors.grey400,
                    size: 64,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Text(
          'Pinch untuk zoom • Drag untuk geser',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}