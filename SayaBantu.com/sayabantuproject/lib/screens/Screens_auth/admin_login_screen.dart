import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens_admin/admin_layout.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
  });

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // =========================================================
  // STATE
  // =========================================================

  bool obscurePassword = true;
  bool isLoading = false;

  String? emailError;
  String? passwordError;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          final isMobile = screenWidth < 700;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 30,
                vertical: 30,
              ),
              child: _buildLoginCard(
                context,
                isMobile,
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // LOGIN CARD
  // =========================================================

  Widget _buildLoginCard(
    BuildContext context,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 420,
      padding: EdgeInsets.all(
        isMobile ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =================================================
          // LOGO
          // =================================================

          Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 31,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // TITLE
          // =================================================

          const Center(
            child: Text(
              'Login Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          const SizedBox(height: 6),

          const Center(
            child: Text(
              'Masuk ke panel administrator SayaBantu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // =================================================
          // EMAIL
          // =================================================

          const Text(
            'Email Admin',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: emailController,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            onChanged: (value) {
              if (emailError != null) {
                setState(() {
                  emailError = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Masukkan email admin',
              errorText: emailError,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 19,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 1.5,
                ),
              ),
              errorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                ),
              ),
              focusedErrorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =================================================
          // PASSWORD
          // =================================================

          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction:
                TextInputAction.done,
            onSubmitted: (_) {
              _login();
            },
            onChanged: (value) {
              if (passwordError != null) {
                setState(() {
                  passwordError = null;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Masukkan kata sandi',
              errorText: passwordError,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 19,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword =
                        !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                  size: 19,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF8B5CF6),
                  width: 1.5,
                ),
              ),
              errorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                ),
              ),
              focusedErrorBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // =================================================
          // LOGIN BUTTON
          // =================================================

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed:
                  isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFC4B5FD),
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Masuk sebagai Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // INFO
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: Color(0xFF64748B),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Halaman ini khusus untuk administrator. '
                    'Gunakan akun admin yang telah terdaftar.',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email =
        emailController.text.trim();
    final password =
        passwordController.text;

    bool hasError = false;

    // =======================================================
    // VALIDASI EMAIL
    // =======================================================

    if (email.isEmpty) {
      setState(() {
        emailError =
            'Email wajib diisi';
      });

      hasError = true;
    } else if (!email.contains('@')) {
      setState(() {
        emailError =
            'Format email tidak valid';
      });

      hasError = true;
    }

    // =======================================================
    // VALIDASI PASSWORD
    // =======================================================

    if (password.isEmpty) {
      setState(() {
        passwordError =
            'Kata sandi wajib diisi';
      });

      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Memberikan sedikit delay agar proses
    // login terasa lebih natural.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    // =======================================================
    // AKUN ADMIN
    // =======================================================

    const adminEmail =
        'admin@sayabantu.com';

    const adminPassword =
        'admin123';

    // =======================================================
    // CEK LOGIN
    // =======================================================

    if (email.toLowerCase() ==
            adminEmail &&
        password == adminPassword) {
      final prefs =
          await SharedPreferences
              .getInstance();

      // Simpan sesi admin
      await prefs.setString(
        'role',
        'admin',
      );

      await prefs.setString(
        'email',
        adminEmail,
      );

      await prefs.setString(
        'name',
        'Admin Operator',
      );

      await prefs.setString(
        'password',
        adminPassword,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Masuk ke dashboard admin tanpa animasi

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const AdminLayout(
              activeMenu: 'verification',
            );
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      return;
    }

    // =======================================================
    // LOGIN GAGAL
    // =======================================================

    if (!mounted) return;

    setState(() {
      isLoading = false;
      passwordError =
          'Email atau kata sandi admin salah';
    });
  }
}