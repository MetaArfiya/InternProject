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

  int _selectedRoleId = 4; // 4 = Pelanggan, 3 = Mitra

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

      // Email wajib menggunakan domain .com
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&\*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.com$',
      );

      if (!emailRegex.hasMatch(email)) {
        return 'Format email tidak valid';
      }

      return null;
    }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> _register() async {
    // Jalankan semua validasi Form terlebih dahulu
    if (!_formKey.currentState!.validate()) {
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
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? "Registrasi berhasil! Silakan masuk.",
            ),
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
      } else {
        String errorMessage = data['message'] ?? "Registrasi gagal.";

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
                          // =================================================
                          // HEADER
                          // =================================================

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

                          // =================================================
                          // NAMA
                          // =================================================

                          const Text(
                            "Nama Lengkap",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: "Masukkan nama lengkap",
                              prefixIcon: const Icon(
                                Icons.person_outline,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // EMAIL
                          // =================================================

                          const Text(
                            "Email",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: _validateEmail,
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // PASSWORD
                          // =================================================

                          const Text(
                            "Password",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ),
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

                              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]').hasMatch(value)) {
                                return 'Password harus memiliki simbol';
                              }

                              if (value.contains(' ')) {
                                return 'Password tidak boleh mengandung spasi';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // ROLE
                          // =================================================

                          const Text(
                            "Daftar Sebagai",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<int>(
                                  value: _selectedRoleId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
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

                          const SizedBox(height: 30),

                          // =================================================
                          // BUTTON
                          // =================================================

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
                                    backgroundColor:
                                        AppColors.primary,
                                    onPressed: _register,
                                  ),
                          ),

                          const SizedBox(height: 25),

                          // =================================================
                          // LOGIN
                          // =================================================

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Sudah punya akun?",
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          const LoginScreen(),
                                      transitionDuration:
                                          Duration.zero,
                                      reverseTransitionDuration:
                                          Duration.zero,
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