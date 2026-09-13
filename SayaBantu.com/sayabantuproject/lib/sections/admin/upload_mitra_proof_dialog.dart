import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  bool _isUploading = false;

  @override
  void dispose() {
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
    setState(() => _imageBytes = bytes);
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
      _showSnack(
        'Pilih foto bukti transfer ke mitra terlebih dahulu.',
        Colors.red,
      );
      return;
    }

    setState(() => _isUploading = true);

    final success = await PaymentService.settleToMitra(
      paymentId: widget.payment.id,
      imageBytes: _imageBytes!,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (success) {
      Navigator.pop(context, true);
      _showSnack('Bukti transfer ke mitra berhasil dikirim!', Colors.green);
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
            child: Text(label,
                style: const TextStyle(color: Colors.grey)),
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