import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Wajib import ini untuk Formatter
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';

class TopupDialog extends StatefulWidget {
  final String role; // 'pelanggan' atau 'mitra'
  const TopupDialog({super.key, required this.role});

  @override
  State<TopupDialog> createState() => _TopupDialogState();
}

class _TopupDialogState extends State<TopupDialog> {
  final _amountController = TextEditingController();
  final _customBankController = TextEditingController();
  final _accountNameController = TextEditingController();
  
  String? _selectedBank;
  XFile? _proofImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  static const Color _primaryColor = AppColors.primaryTeal;
  static const Color _borderColor = Color(0xFFE5E7EB);

  final List<String> _bankList = [
    'BCA', 'Mandiri', 'BNI', 'BRI', 'BSI', 'CIMB Niaga', 
    'Permata', 'Danamon', 'BTN', 'Lainnya'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 70,
      maxWidth: 1600,
    );
    
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _proofImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final bankName = _selectedBank == 'Lainnya' 
        ? _customBankController.text.trim() 
        : _selectedBank;

    // Ambil teks nominal, hapus titik pemisah ribuan sebelum dikirim ke API
    final rawAmount = _amountController.text.replaceAll('.', '');

    if (rawAmount.isEmpty || _proofImage == null || bankName == null || bankName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data dan bukti transfer!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final endpoint = widget.role.toLowerCase() == 'mitra' ? '/mitra/topups' : '/pelanggan/topups';

      final response = await ApiService.postMultipart(
        endpoint,
        {
          'amount': rawAmount, // <-- Kirim angka tanpa titik (misal: 100000)
          'bank_name': bankName,
          'account_name': _accountNameController.text,
        },
        files: {
          'proof': _imageBytes!, 
        },
      );

      final decoded = jsonDecode(response.body);
      
      if ((response.statusCode == 201 || response.statusCode == 200) && decoded['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan topup berhasil dikirim! Menunggu verifikasi Admin.', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(decoded['message'] ?? 'Gagal mengirim topup'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined, color: _primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Topup Saldo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20, color: AppColors.grey500),
                      splashRadius: 22,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // BODY
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Silakan transfer ke: BCA 123-456-789 (PT SayaBantu)',
                        style: TextStyle(fontSize: 13, color: AppColors.grey700, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      
                      // INPUT NOMINAL DENGAN FORMATTER TITIK
                      _buildTextField(
                        controller: _amountController,
                        label: 'Nominal Topup (Rp)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // Formatter khusus untuk pemisah ribuan
                          FilteringTextInputFormatter.digitsOnly,
                          _ThousandsSeparatorFormatter(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // DROPDOWN BANK
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBank,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Bank Pengirim',
                          prefixIcon: const Icon(Icons.account_balance_outlined, size: 19),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.grey900),
                        items: _bankList.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                        onChanged: _isLoading ? null : (val) {
                          setState(() => _selectedBank = val);
                        },
                      ),

                      // JIKA PILIH LAINNYA
                      if (_selectedBank == 'Lainnya') ...[
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _customBankController,
                          label: 'Nama Bank Manual',
                          icon: Icons.edit_outlined,
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      _buildTextField(
                        controller: _accountNameController,
                        label: 'Nama Pemilik Rekening',
                        icon: Icons.person_outline,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text('Bukti Transfer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey900)),
                      const SizedBox(height: 8),
                      
                      InkWell(
                        onTap: _isLoading ? null : _pickImage,
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9, 
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.grey300, width: 1.5),
                            ),
                            child: _imageBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.grey400),
                                      const SizedBox(height: 8),
                                      const Text('Klik untuk upload foto', style: TextStyle(color: AppColors.grey600, fontSize: 13, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      const Text('Format: JPG, PNG, WEBP. Maks 5 MB.', style: TextStyle(color: AppColors.grey400, fontSize: 11)),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand, 
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(9),
                                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha:0.6),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // ACTIONS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context), 
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          foregroundColor: AppColors.grey700,
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Text('Kirim Pengajuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters, // <-- Tambahan parameter
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // <-- Pasang formatter di sini
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM FORMATTER: PEMISAH RIBUAN (TITIK)
// ============================================================
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hanya ambil angka
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format dengan titik setiap 3 digit dari belakang
    final String formatted = _formatNumber(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String s) {
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}