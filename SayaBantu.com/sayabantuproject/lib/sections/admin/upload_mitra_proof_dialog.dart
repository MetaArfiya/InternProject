import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';

class UploadMitraProofDialog extends StatefulWidget {
  final PaymentModel payment;

  const UploadMitraProofDialog({super.key, required this.payment});

  @override
  State<UploadMitraProofDialog> createState() =>
      _UploadMitraProofDialogState();
}

class _UploadMitraProofDialogState extends State<UploadMitraProofDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  // ============================================================
  // DESIGN TOKENS — disamakan dengan DashboardHeader / PaymentScreen
  // ============================================================

  static const Color _accent = Color(0xFFF97316);
  static const Color _successColor = Color(0xFF16A34A);
  static const Color _tableBorder = Color(0xFFE5E7EB);
  static const Color _cellText = Color(0xFF111827);
  static const double _radius = 12;

  static const int _maxImageSizeInBytes = 5 * 1024 * 1024; // 5 MB

  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // PILIH FOTO — DENGAN VALIDASI FORMAT & UKURAN
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
          Colors.red,
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
          Colors.red,
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
      _showSnack('Gagal memilih foto: $e', Colors.red);
    }
  }

  // ============================================================
  // BOTTOM SHEET SUMBER FOTO — disamakan dgn style dialog
  // ============================================================

  void _showSourceSheet() {
    final showCamera = !kIsWeb;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
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
                        color: _cellText,
                      ),
                ),
                const SizedBox(height: 6),

                Text(
                  'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                        color: _successColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: _successColor,
                      ),
                    ),
                    title: const Text(
                      'Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle:
                        const Text('Ambil foto bukti transfer sekarang'),
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
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Pilih foto dari galeri perangkat'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
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
        Colors.red,
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
      _showSnack('Bukti transfer ke mitra berhasil dikirim!', Colors.green);
    } else {
      _showSnack(
        result.message ?? 'Gagal mengirim bukti. Coba lagi.',
        Colors.red,
      );
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
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
                      color: _successColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: _successColor,
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
                            color: _cellText,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    splashRadius: 22,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // ============================================
              // CONTENT (scrollable)
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
                          color: _successColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _successColor.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Jumlah yang harus ditransfer',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              PaymentModel.formatRupiah(p.mitraEarning),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _successColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Info rekening mitra
                      const Text(
                        'Rekening Mitra',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2563EB).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2563EB)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _bankRow(
                              'Bank',
                              bank['bank_name']?.toString() ?? '-',
                            ),
                            _bankRow(
                              'No. Rekening',
                              bank['account_number']?.toString() ?? '-',
                            ),
                            _bankRow(
                              'Atas Nama',
                              bank['account_name']?.toString() ?? '-',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Label + info limit
                      const Text(
                        'Bukti Transfer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _cellText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(_radius),
                            border: Border.all(
                              color: _imageBytes != null
                                  ? _successColor
                                  : _tableBorder,
                              width: _imageBytes != null ? 2 : 1,
                            ),
                          ),
                          child: _imageBytes == null
                              ? const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 50,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap untuk upload bukti transfer',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(_radius - 1),
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
                              foregroundColor: _accent,
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
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          prefixIcon:
                              const Icon(Icons.notes, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: _tableBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: _tableBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: _accent,
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
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(
                          color: Color(0xFFD1D5DB),
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
                                color: Colors.white,
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
                        backgroundColor: _successColor,
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
            ],
          ),
        ),
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
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.5,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: _cellText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}