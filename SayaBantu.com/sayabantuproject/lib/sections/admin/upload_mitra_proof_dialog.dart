import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../theme/admin_theme.dart';
import '../../theme/admin_theme_provider.dart';
import '../../theme/app_colors.dart';

class UploadMitraProofDialog extends StatefulWidget {
  final PaymentModel payment;

  const UploadMitraProofDialog({super.key, required this.payment});

  @override
  State<UploadMitraProofDialog> createState() =>
      _UploadMitraProofDialogState();
}

class _UploadMitraProofDialogState
    extends State<UploadMitraProofDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  // ============================================================
  // TOKENS
  // ============================================================

  static const double _radius = 12;

  static const int _maxImageSizeInBytes = 5 * 1024 * 1024; // 5 MB

  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  // ============================================================
  // THEME
  // ============================================================

  AdminTheme get theme => AdminThemeProvider.of(context);

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (picked == null) return;

      final lowerName = picked.name.toLowerCase();
      final hasValidExtension =
          _allowedExtensions.any((ext) => lowerName.endsWith(ext));

      if (!hasValidExtension) {
        if (!mounted) return;
        _showSnack(
          'Format foto harus JPG, JPEG, PNG, atau WEBP.',
          error: true,
        );
        return;
      }

      final bytes = await picked.readAsBytes();

      if (bytes.length > _maxImageSizeInBytes) {
        if (!mounted) return;
        final sizeMb = (bytes.length / 1024 / 1024).toStringAsFixed(2);
        final maxMb =
            (_maxImageSizeInBytes / 1024 / 1024).toStringAsFixed(0);
        _showSnack(
          'Ukuran foto terlalu besar ($sizeMb MB). Maksimal $maxMb MB.',
          error: true,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });

      debugPrint(
        "FOTO BUKTI MITRA DIPILIH: ${picked.name} (${bytes.length} bytes)",
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memilih foto: $e', error: true);
    }
  }

  // ============================================================
  // BOTTOM SHEET SUMBER FOTO
  // ============================================================

  void _showSourceSheet() {
    final showCamera = !kIsWeb;
    final t = theme;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return AdminThemeProvider(
          theme: t,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text(
                    showCamera ? 'Pilih Sumber Foto' : 'Pilih Foto',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.cellText,
                        ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (showCamera) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: t.success,
                        ),
                      ),
                      title: const Text(
                        'Kamera',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Ambil foto bukti transfer sekarang',
                      ),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.infoBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.infoBlue,
                      ),
                    ),
                    title: const Text(
                      'Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        const Text('Pilih foto dari galeri perangkat'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _pickImage(ImageSource.gallery);
                    },
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(bottomSheetContext),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.grey700,
                        side: const BorderSide(
                          color: AppColors.grey300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<void> _upload() async {
    if (_imageBytes == null) {
      _showSnack(
        'Pilih foto bukti transfer ke mitra terlebih dahulu.',
        error: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    final result = await PaymentService.settleToMitra(
      paymentId: widget.payment.id,
      imageBytes: _imageBytes!,
      imageName: _imageName,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result.success) {
      Navigator.pop(context, true);
      _showSnack('Bukti transfer ke mitra berhasil dikirim!');
    } else {
      _showSnack(
        result.message ?? 'Gagal mengirim bukti. Coba lagi.',
        error: true,
      );
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    final t = theme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? t.danger : t.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final bank = widget.payment.mitraBank ?? {};
    final p = widget.payment;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                      color: t.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.send,
                      color: t.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transfer ke Mitra',
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
                    onPressed: _isUploading
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
                      // Info nominal
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: t.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: t.success.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Jumlah yang harus ditransfer',
                              style: TextStyle(
                                color: t.mutedText,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              PaymentModel.formatRupiah(
                                p.mitraEarning,
                              ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: t.success,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Info rekening mitra
                      Text(
                        'Rekening Mitra',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: t.cellText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.infoBlue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _bankRow(
                              'Bank',
                              bank['bank_name']?.toString() ?? '-',
                              t,
                            ),
                            _bankRow(
                              'No. Rekening',
                              bank['account_number']?.toString() ?? '-',
                              t,
                            ),
                            _bankRow(
                              'Atas Nama',
                              bank['account_name']?.toString() ?? '-',
                              t,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Label + info limit
                      Text(
                        'Bukti Transfer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: t.cellText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: t.mutedText,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Pilih gambar
                      GestureDetector(
                        onTap: _isUploading ? null : _showSourceSheet,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius:
                                BorderRadius.circular(_radius),
                            border: Border.all(
                              color: _imageBytes != null
                                  ? t.success
                                  : t.border,
                              width: _imageBytes != null ? 2 : 1,
                            ),
                          ),
                          child: _imageBytes == null
                              ? Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons
                                          .add_photo_alternate_outlined,
                                      size: 50,
                                      color: AppColors.grey400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap untuk upload bukti transfer',
                                      style: TextStyle(
                                        color: t.mutedText,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(
                                    _radius - 1,
                                  ),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),

                      if (_imageBytes != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed:
                                _isUploading ? null : _showSourceSheet,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Ganti Foto',
                              style: TextStyle(fontSize: 12.5),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: t.accent,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: _noteCtrl,
                        enabled: !_isUploading,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText:
                              'Contoh: Transfer via BCA mobile banking',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: t.headerText,
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey400,
                          ),
                          prefixIcon:
                              const Icon(Icons.notes, size: 18),
                          filled: true,
                          fillColor: AppColors.grey50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: t.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: t.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ============================================
              // ACTIONS
              // ============================================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        foregroundColor: AppColors.grey700,
                        side: const BorderSide(
                          color: AppColors.grey300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _upload,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                        _isUploading
                            ? 'Mengirim...'
                            : 'Konfirmasi Transfer',
                        style: const TextStyle(
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
                          borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _bankRow(String label, String value, AdminTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: t.mutedText,
                fontSize: 12.5,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: t.mutedText,
              fontSize: 12.5,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: t.cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}