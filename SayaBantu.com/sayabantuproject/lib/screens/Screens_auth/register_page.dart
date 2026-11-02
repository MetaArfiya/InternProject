
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import 'login_page.dart';

class RegisterScreen extends StatefulWidget {
  final String? defaultRole;

  const RegisterScreen({
    super.key,
    this.defaultRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ROLE
  int _selectedRoleId = 4;

  // KOTA
  List<Map<String, dynamic>> _cities = [];
  int? _selectedCityId;

  bool _isLoadingCities = true;
  String? _cityErrorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.defaultRole != null) {
      if (widget.defaultRole == "Mitra") {
        _selectedRoleId = 3;
      } else {
        _selectedRoleId = 4;
      }
    }

    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA KOTA DARI DATABASE
  // ============================================================

  Future<void> _loadCities() async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
        _cityErrorMessage = null;
      });
    }

    try {
      final response = await ApiService.get('/cities');

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil daftar kota.');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true || data['data'] is! List) {
        throw Exception(
          data['message'] ?? 'Format data kota tidak valid.',
        );
      }

      final List<dynamic> cityData = data['data'];

      final loadedCities = cityData
          .whereType<Map<String, dynamic>>()
          .where((city) =>
              city['id'] != null && city['name'] != null)
          .toList();

      if (!mounted) return;

      setState(() {
        _cities = loadedCities;
        _isLoadingCities = false;
        _selectedCityId = null;

        if (_cities.isEmpty) {
          _cityErrorMessage =
              'Belum ada kota yang tersedia. Hubungi Super Admin.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCities = false;
        _cityErrorMessage =
            'Gagal memuat daftar kota. Periksa koneksi Anda.';
      });

      debugPrint('❌ LOAD CITIES ERROR: $e');
    }
  }

  // ============================================================
  // VALIDASI EMAIL
  // ============================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi';
    }

    if (email.contains(' ')) {
      return 'Email tidak boleh mengandung spasi';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&\*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.com$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kota domisili terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRoleId,
        _selectedCityId!,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        if (_selectedRoleId == 3) {
          _showMitraVerificationRequiredDialog();
        } else {
          _showSuccessAndGoToLogin(
            data['message'] ??
                "Registrasi berhasil! Silakan masuk.",
          );
        }
      } else {
        String errorMessage =
            data['message'] ?? "Registrasi gagal.";

        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;

            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError[0].toString();
            }
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan koneksi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SUKSES REGISTRASI PELANGGAN
  // ============================================================

  void _showSuccessAndGoToLogin(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // DIALOG VERIFIKASI MITRA
  // ============================================================

  Future<void> _showMitraVerificationRequiredDialog() async {
    final bool? goToLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Theme.of(context).cardColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 42,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Verifikasi Diperlukan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Akun Mitra kamu berhasil dibuat! 🎉\n\n'
                    'Untuk bisa mulai menerima pekerjaan, kamu wajib '
                    'melengkapi verifikasi terlebih dahulu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Dokumen yang perlu diupload:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 10),
                        _VerificationItem(
                          icon: Icons.credit_card_outlined,
                          text: 'Foto KTP',
                        ),
                        SizedBox(height: 8),
                        _VerificationItem(
                          icon: Icons.photo_library_outlined,
                          text: 'Foto keahlian / portfolio',
                        ),
                        SizedBox(height: 8),
                        _VerificationItem(
                          icon: Icons.workspace_premium_outlined,
                          text: 'Sertifikat (opsional)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verifikasi akan diperiksa admin dalam 1×24 jam.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.blue.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Login & Upload Verifikasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

    if (goToLogin == true) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  // ============================================================
  // DROPDOWN KOTA
  // ============================================================

  Widget _buildCityDropdown() {
    if (_isLoadingCities) {
      return InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat daftar kota...'),
          ],
        ),
      );
    }

    if (_cityErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _cityErrorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadCities,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Muat Ulang'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCityId,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Pilih kota domisili',
        prefixIcon: const Icon(Icons.location_city_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) {
        if (value == null) {
          return 'Kota domisili wajib dipilih';
        }
        return null;
      },
      items: _cities.map((city) {
        return DropdownMenuItem<int>(
          value: int.parse(city['id'].toString()),
          child: Text(
            city['name'].toString(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCityId = value;
        });
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xffF8FAFC),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMobile ? double.infinity : 460,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                      isMobile ? 24 : 35,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: isMobile ? 65 : 75,
                                  height: isMobile ? 65 : 75,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.person_add_alt_1,
                                    color: Theme.of(context).cardColor,
                                    size: isMobile ? 30 : 36,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Daftar Akun",
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Buat akun SayaBantu sekarang",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isMobile ? 14 : 15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // NAMA
                          const Text(
                            "Nama Lengkap",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: "Masukkan nama lengkap",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // EMAIL
                          const Text(
                            "Email",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              hintText: "Masukkan email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: _validateEmail,
                          ),

                          const SizedBox(height: 20),

                          // PASSWORD
                          const Text(
                            "Password",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _register();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: "Masukkan password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Password harus memiliki huruf besar';
                              }
                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return 'Password harus memiliki huruf kecil';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return 'Password harus memiliki angka';
                              }
                              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]')
                                  .hasMatch(value)) {
                                return 'Password harus memiliki simbol';
                              }
                              if (value.contains(' ')) {
                                return 'Password tidak boleh mengandung spasi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ROLE
                          const Text(
                            "Daftar Sebagai",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          widget.defaultRole != null
                              ? TextFormField(
                                  initialValue:
                                      widget.defaultRole == "Mitra"
                                          ? "Penyedia Jasa (Mitra)"
                                          : "Pencari Jasa (Pelanggan)",
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  value: _selectedRoleId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 4,
                                      child: Text(
                                        "Pencari Jasa (Pelanggan)",
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text(
                                        "Penyedia Jasa (Mitra)",
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedRoleId = value;
                                    });
                                  },
                                ),

                          const SizedBox(height: 20),

                          // KOTA DOMISILI
                          const Text(
                            "Kota Domisili",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          _buildCityDropdown(),

                          const SizedBox(height: 30),

                          // BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : CustomButton(
                                    text: "Daftar Sekarang",
                                    width: double.infinity,
                                    height: 56,
                                    backgroundColor: AppColors.primary,
                                    onPressed: _register,
                                  ),
                          ),

                          const SizedBox(height: 25),

                          // LOGIN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Sudah punya akun?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          const LoginScreen(),
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                    ),
                                  );
                                },
                                child: Text(
                                  "Masuk",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// WIDGET BANTU — ITEM CHECKLIST VERIFIKASI
// ============================================================

class _VerificationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VerificationItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }
}