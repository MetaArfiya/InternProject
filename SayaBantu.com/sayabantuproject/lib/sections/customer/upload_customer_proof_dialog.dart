import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/payment_model.dart';
import '../../services/payment_service.dart';

class UploadCustomerProofDialog extends StatefulWidget {
  final PaymentModel payment;

  const UploadCustomerProofDialog({super.key, required this.payment});

  @override
  State<UploadCustomerProofDialog> createState() =>
      _UploadCustomerProofDialogState();
}

class _UploadCustomerProofDialogState extends State<UploadCustomerProofDialog> {
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accountNameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  // ✅ Pakai Uint8List (bytes) — cocok dengan ApiService.postMultipart
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name;
    });
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_imageBytes == null) {
      _showSnack('Pilih foto bukti transfer terlebih dahulu.', Colors.red);
      return;
    }
    if (_bankNameCtrl.text.trim().isEmpty) {
      _showSnack('Isi nama bank pengirim.', Colors.red);
      return;
    }
    if (_accountNameCtrl.text.trim().isEmpty) {
      _showSnack('Isi nama pemilik rekening.', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    final success = await PaymentService.uploadCustomerProof(
      paymentId: widget.payment.id,
      imageBytes: _imageBytes!,
      bankName: _bankNameCtrl.text.trim(),
      accountName: _accountNameCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (success) {
      Navigator.pop(context, true);
      _showSnack('Bukti transfer berhasil dikirim!', Colors.green);
    } else {
      _showSnack('Gagal mengirim bukti. Coba lagi.', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              // Preview gambar
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
                              'Tap untuk pilih foto bukti transfer',
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

              const SizedBox(height: 16),

              TextField(
                controller: _bankNameCtrl,
                enabled: !_isUploading,
                decoration: const InputDecoration(
                  labelText: 'Bank Pengirim',
                  hintText: 'Contoh: BCA, Mandiri, BNI',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 12),

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

              // Info nominal
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
                        'Pastikan jumlah transfer: ${PaymentModel.formatRupiah(widget.payment.totalPaid)}',
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
}