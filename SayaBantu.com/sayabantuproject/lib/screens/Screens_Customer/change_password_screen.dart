import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hideNew = true;
  bool hideConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim().toLowerCase();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua kolom wajib diisi.")),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password baru minimal 6 karakter.")),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi password tidak sama.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Menembak endpoint publik /forgot-password yang baru dibuat
      final response = await ApiService.post('/forgot-password', {
        'email': email,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });

      final responseData = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? "Password berhasil diubah."),
          ),
        );
        Navigator.pop(context); // Kembali ke halaman login
      } else {
        final errorMessage = responseData['message'] ?? "Gagal mereset password.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan koneksi: $e")),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 450,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Masukkan email akun Anda untuk memperbarui password.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),

                  // Input Email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email Akun",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Baru
                  TextField(
                    controller: newPasswordController,
                    obscureText: hideNew,
                    decoration: InputDecoration(
                      labelText: "Password Baru",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hideNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            hideNew = !hideNew;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Konfirmasi Password Baru
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: hideConfirm,
                    decoration: InputDecoration(
                      labelText: "Konfirmasi Password Baru",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(hideConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            hideConfirm = !hideConfirm;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : resetPassword,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Simpan Password Baru",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}