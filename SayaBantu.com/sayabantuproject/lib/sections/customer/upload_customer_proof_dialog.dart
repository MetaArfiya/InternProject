import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';

// ============================================================
// DAFTAR BANK
// ============================================================
const List<String> bankList = [
  'BCA',
  'Mandiri',
  'BNI',
  'BRI',
  'BSI (Syariah)',
  'CIMB Niaga',
  'Permata',
  'Danamon',
  'BTN',
  'OCBC',
  'Panin',
  'Maybank',
  'Bank Mega',
  'Bukopin',
  'Bank Jago',
  'SeaBank',
  'Lainnya',
];

class UploadCustomerProofDialog extends StatefulWidget {
  final PaymentModel payment;

  const UploadCustomerProofDialog({super.key, required this.payment});

  @override
  State<UploadCustomerProofDialog> createState() =>
      _UploadCustomerProofDialogState();
}

class _UploadCustomerProofDialogState extends State<UploadCustomerProofDialog> {
  // === BANK ===
  String? _selectedBank;
  bool _isCustomBank = false;
  final TextEditingController _customBankCtrl = TextEditingController();

  // === REKENING ===
  final TextEditingController _accountNameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // ✅ Batas ukuran (sesuaikan dengan Laravel max:xxxx)
  static const int _maxImageSizeInBytes = 5 * 1024 * 1024; // 5 MB

  // ✅ Format yang diizinkan
  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  // ✅ Pakai Uint8List (bytes)
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  @override
  void dispose() {
    _customBankCtrl.dispose();
    _accountNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPER: nama bank final
  // ============================================================
  String get _finalBankName {
    if (_isCustomBank) return _customBankCtrl.text.trim();
    return _selectedBank?.trim() ?? '';
  }

  // ============================================================
  // PILIH FOTO — DENGAN VALIDASI FORMAT & UKURAN
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
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
        "FOTO BUKTI DIPILIH: ${picked.name} (${bytes.length} bytes)",
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memilih foto: $e', Colors.red);
    }
  }

  // ============================================================
  // HAPUS FOTO
  // ============================================================
  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
  }

  // ============================================================
  // BOTTOM SHEET SUMBER FOTO
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
                // Handle bar
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
      _showSnack('Pilih foto bukti transfer terlebih dahulu.', Colors.red);
      return;
    }
    if (_finalBankName.isEmpty) {
      _showSnack(
        _isCustomBank
            ? 'Isi nama bank pengirim.'
            : 'Pilih bank pengirim terlebih dahulu.',
        Colors.red,
      );
      return;
    }
    if (_accountNameCtrl.text.trim().isEmpty) {
      _showSnack('Isi nama pemilik rekening.', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    final result = await PaymentService.uploadCustomerProof(
      paymentId: widget.payment.id,
      imageBytes: _imageBytes!,
      imageName: _imageName,
      bankName: _finalBankName,
      accountName: _accountNameCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (result.success) {
      Navigator.pop(context, true);
      _showSnack('Bukti transfer berhasil dikirim!', Colors.green);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: Colors.orange),
          SizedBox(width: 10),
          Text('Upload Bukti Transfer'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ============================================
              // PREVIEW FOTO
              // ============================================
              _buildImageSection(),

              const SizedBox(height: 16),

              // ============================================
              // DROPDOWN BANK PENGIRIM
              // ============================================
              DropdownButtonFormField<String>(
                value: _selectedBank,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bank Pengirim',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: bankList
                    .map((bank) => DropdownMenuItem<String>(
                          value: bank,
                          child: Text(bank),
                        ))
                    .toList(),
                onChanged: _isUploading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedBank = value;
                          _isCustomBank = value == 'Lainnya';
                          if (!_isCustomBank) {
                            _customBankCtrl.clear();
                          }
                        });
                      },
              ),

              // ============================================
              // INPUT MANUAL — hanya kalau pilih "Lainnya"
              // ============================================
              if (_isCustomBank) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customBankCtrl,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank (Manual)',
                    hintText: 'Contoh: Bank Daerah, Koperasi, dll',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ============================================
              // NAMA PEMILIK REKENING
              // ============================================
              TextField(
                controller: _accountNameCtrl,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),

              // ============================================
              // CATATAN
              // ============================================
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

              const SizedBox(height: 12),

              // ============================================
              // INFO NOMINAL
              // ============================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pastikan jumlah transfer: '
                        '${PaymentModel.formatRupiah(widget.payment.totalPaid)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
          label: Text(_isUploading ? 'Mengirim...' : 'Kirim Bukti'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================
  Widget _buildImageSection() {
    // Belum ada foto
    if (_imageBytes == null) {
      return InkWell(
        onTap: _isUploading ? null : _showSourceSheet,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xffF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffD1D5DB),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xffFEF3C7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xffD97706),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tambahkan Foto Bukti',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                kIsWeb ? 'Tap untuk pilih foto' : 'Kamera atau Galeri',
                style: const TextStyle(
                  color: Color(0xff6B7280),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'JPG, JPEG, PNG, WEBP · Maks 5 MB',
                style: TextStyle(
                  color: Color(0xff9CA3AF),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sudah ada foto
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD1D5DB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.memory(
            _imageBytes!,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),

          // Gradient bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Ganti Foto
          Positioned(
            left: 12,
            bottom: 12,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : _showSourceSheet,
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Ganti Foto'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff374151),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Tombol Hapus Foto
          Positioned(
            right: 12,
            bottom: 12,
            child: IconButton(
              onPressed: _isUploading ? null : _removeImage,
              tooltip: 'Hapus foto',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ],
      ),
    );
  }
}