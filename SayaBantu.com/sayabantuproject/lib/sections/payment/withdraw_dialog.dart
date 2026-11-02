import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Wajib import ini
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';

class WithdrawDialog extends StatefulWidget {
  final String role; // 'pelanggan' atau 'mitra'
  final double maxAmount;
  
  const WithdrawDialog({super.key, required this.role, required this.maxAmount});

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  
  // Dropdown Bank
  String? _selectedBank;
  final _customBankController = TextEditingController();

  // Controller PIN
  final _pinController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingProfile = true;
  bool _hasPin = false; 

  static const Color _primaryColor = AppColors.primaryTeal;
  static const Color _borderColor = Color(0xFFE5E7EB);

  // Daftar Bank
  final List<String> _bankList = [
    'BCA', 'Mandiri', 'BNI', 'BRI', 'BSI', 'CIMB Niaga', 
    'Permata', 'Danamon', 'BTN', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserBankData();
  }

  // AMBIL DATA USER (AUTO-FILL & CEK PIN)
  Future<void> _loadUserBankData() async {
    try {
      final res = await ApiService.get('/user');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'] ?? data;
        
        if (mounted) {
          setState(() {
            // CEK STATUS PIN
            _hasPin = user['has_pin'] == true;

            // AUTO-FILL BANK
            final savedBank = user['bank_name']?.toString() ?? '';
            if (_bankList.contains(savedBank)) {
              _selectedBank = savedBank;
            } else if (savedBank.isNotEmpty) {
              _selectedBank = 'Lainnya';
              _customBankController.text = savedBank;
            }

            _accountNumberController.text = user['bank_account_number']?.toString() ?? '';
            _accountNameController.text = user['bank_account_name']?.toString() ?? user['name']?.toString() ?? '';
          });
        }
      }
    } catch (_) {
      // Abaikan jika gagal
    } finally {
      if (mounted) setState(() => _isFetchingProfile = false);
    }
  }

  Future<void> _submit() async {
    // Hapus titik pemisah ribuan sebelum di-parse
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(rawAmount) ?? 0;
    
    final finalBankName = _selectedBank == 'Lainnya' 
        ? _customBankController.text.trim() 
        : _selectedBank;

    // VALIDASI LOKAL
    if (amount <= 0 || amount > widget.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal tidak valid atau melebihi saldo!'), backgroundColor: Colors.red));
      return;
    }
    if (finalBankName == null || finalBankName.isEmpty || _accountNumberController.text.isEmpty || _accountNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data bank dan rekening!'), backgroundColor: Colors.orange));
      return;
    }
    if (_pinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN harus 6 digit!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final endpoint = widget.role.toLowerCase() == 'mitra' ? '/mitra/withdrawals' : '/pelanggan/withdrawals';

      final response = await ApiService.post(endpoint, {
        'amount': amount, // <-- Kirim angka murni (tanpa titik)
        'bank_name': finalBankName,
        'account_number': _accountNumberController.text,
        'account_name': _accountNameController.text,
        'pin': _pinController.text,
      });

      final decoded = jsonDecode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) && decoded['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penarikan saldo berhasil diajukan.'), backgroundColor: AppColors.primaryTeal),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decoded['message'] ?? 'Gagal')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                      child: const Icon(Icons.money_off_csred_outlined, color: _primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tarik Saldo (Withdraw)',
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
              if (_isFetchingProfile)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_hasPin)
                // JIKA BELUM PUNYA PIN
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'PIN Belum Dibuat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Demi keamanan, Anda wajib membuat PIN 6 digit terlebih dahulu di menu pengaturan sebelum dapat menarik saldo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.grey600, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // JIKA SUDAH PUNYA PIN
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha:0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _primaryColor.withValues(alpha:0.2)),
                          ),
                          child: Text(
                            'Saldo Tersedia: Rp ${widget.maxAmount.toStringAsFixed(0)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // INPUT NOMINAL DENGAN FORMATTER TITIK
                        _buildTextField(
                          controller: _amountController,
                          label: 'Nominal Tarik (Rp)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
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
                            labelText: 'Nama Bank',
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
                          controller: _accountNumberController,
                          label: 'Nomor Rekening',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildTextField(
                          controller: _accountNameController,
                          label: 'Nama Pemilik Rekening',
                          icon: Icons.person_outline,
                        ),
                        
                        // INPUT PIN
                        const SizedBox(height: 12),
                        _buildPinField(
                          controller: _pinController,
                          label: 'Masukkan PIN Keamanan',
                          icon: Icons.lock_outline,
                          enabled: !_isLoading,
                        ),
                      ],
                    ),
                  ),
                ),

              // ACTIONS (Hanya muncul jika sudah punya PIN)
              if (!_isFetchingProfile && _hasPin) ...[
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
                              : const Text('Tarik Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    List<TextInputFormatter>? inputFormatters, // <-- Parameter baru
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters, // <-- Pasang di sini
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

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        counterText: '',
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