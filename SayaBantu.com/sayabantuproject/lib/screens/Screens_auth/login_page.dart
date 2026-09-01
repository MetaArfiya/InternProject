import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import 'register_page.dart';
import '../../sections/customer/customer_main_dashboard.dart';
import '../Screens_Partner/partner_main_dashboard.dart';
import '../../screens/Screens_Customer/change_password_screen.dart';
import '../Screens_admin/admin_layout.dart';
import '../Screens_super_admin/super_admin_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post('/login', {
        'email': email,
        'password': password,
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        final token = responseData['access_token'] ?? '';
        final userRole = responseData['user_role'] ?? '';

        String userName = 'Pengguna';
        final rawUserData = responseData['user'];

        if (rawUserData != null && rawUserData['name'] != null) {
          userName = rawUserData['name'];
        } else if (responseData['message'] != null &&
            responseData['message'].toString().contains('Selamat datang,')) {
          userName = responseData['message']
              .toString()
              .split('Selamat datang,')
              .last
              .trim();
        }

        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', userRole);
        await prefs.setString('name', userName);

        if (!mounted) return;

        if (userRole.toLowerCase() == "pelanggan") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerMainDashboard(),
            ),
          );
        } else if (userRole.toLowerCase() == "mitra") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PartnerMainDashboard(),
            ),
          );
        } else if (userRole.toLowerCase() == "admin" ||
            userRole.toLowerCase() == "administrator") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminLayout(),
            ),
          );
        } else if (userRole.toLowerCase() == "super admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SuperAdminLayout(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Role '$userRole' tidak dikenali sistem"),
            ),
          );
        }
      } else {
        final message = responseData['message'] ?? "Email atau Password salah";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal terhubung ke server: $e")),
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
                child: Container(
                  width: isMobile ? constraints.maxWidth * 0.9 : 450,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: isMobile ? 130 : 1360,
                              height: isMobile ? 130 : 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/Logo_SayaBantu.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Masuk",
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Selamat datang kembali di SayaBantu",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isMobile ? 13 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 28 : 35),
                      const Text(
                        "Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "Masukkan email",
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
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
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Lupa Password?",
                            style: TextStyle(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isLoading ? "Memuat..." : "Masuk",
                          width: double.infinity,
                          height: 56,
                          backgroundColor: AppColors.primary,
                          onPressed: _isLoading ? () {} : _handleLogin,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text("Belum punya akun?"),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        const RegisterScreen(),
                                    transitionDuration: Duration.zero,
                                    reverseTransitionDuration: Duration.zero,
                                  ),
                                );
                              },
                              child: Text(
                                "Daftar",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
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
            ),
          ),
        );
      },
    );
  }
}