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
  State<UploadMitraProofDialog> createState() => _UploadMitraProofDialogState();
}

class _UploadMitraProofDialogState extends State<UploadMitraProofDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  // ✅ Batas ukuran (sesuaikan dengan Laravel max:xxxx)
  static const int _maxImageSizeInBytes = 5 * 1024 * 1024; // 5 MB

  // ✅ Format yang diizinkan
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

      // ✅ VALIDASI EKSTENSI
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

      // Baca bytes
      final bytes = await picked.readAsBytes();

      // ✅ VALIDASI UKURAN
      if (bytes.length > _maxImageSizeInBytes) {
        if (!mounted) return;
        final sizeMb = (bytes.length / 1024 / 1024).toStringAsFixed(2);
        final maxMb = (_maxImageSizeInBytes / 1024 / 1024).toStringAsFixed(0);
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
  // BOTTOM SHEET SUMBER FOTO
  // ============================================================
  void _showSourceSheet() {
    // ✅ Kamera hanya di native (Android/iOS), tidak di Web
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
                    color: const Color(0xffD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  showCamera ? 'Pilih Sumber Foto' : 'Pilih Foto',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // ✅ Info limit
                Text(
                  'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // KAMERA
                if (showCamera) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xffDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xff16A34A),
                      ),
                    ),
                    title: const Text(
                      'Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Ambil foto bukti transfer sekarang'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // GALERI
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xffDBEAFE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xff2563EB),
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

                // Batal
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
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
  // UPLOAD — DENGAN PARSING ERROR DARI BACKEND
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

    // ✅ Panggil service versi baru yang return UploadResult
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

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.send, color: Colors.green),
          SizedBox(width: 10),
          Text('Transfer ke Mitra'),
        ],
      ),
      content: SizedBox(
        width: 480,
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
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Jumlah yang harus ditransfer',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PaymentModel.formatRupiah(p.mitraEarning),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info rekening mitra
              const Text(
                'Rekening Mitra:',
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
                    _bankRow('Bank', bank['bank_name']?.toString() ?? '-'),
                    _bankRow('No. Rekening',
                        bank['account_number']?.toString() ?? '-'),
                    _bankRow('Atas Nama',
                        bank['account_name']?.toString() ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Label + info limit
              const Text(
                'Bukti Transfer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Format: JPG, JPEG, PNG, WEBP · Maks 5 MB',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),

              // Pilih gambar
              GestureDetector(
                onTap: _isUploading ? null : _showSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageBytes != null
                          ? Colors.green
                          : Colors.grey.shade400,
                      width: _imageBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap untuk upload bukti transfer',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),

              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: _isUploading ? null : _showSourceSheet,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Ganti Foto'),
                  ),
                ),

              const SizedBox(height: 12),

              TextField(
                controller: _noteCtrl,
                enabled: !_isUploading,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
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
              : const Icon(Icons.send),
          label: Text(_isUploading ? 'Mengirim...' : 'Konfirmasi Transfer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
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
}