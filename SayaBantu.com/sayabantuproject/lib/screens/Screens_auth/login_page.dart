import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../sections/customer/customer_main_dashboard.dart';
import '../Screens_Partner/partner_main_dashboard.dart';
import '../../screens/Screens_Customer/change_password_screen.dart';
import '../Screens_admin/admin_layout.dart';
import '../Screens_super_admin/super_admin_layout.dart';
import 'register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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

  // ============================================================
  // VALIDASI PASSWORD
  // ============================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    return null;
  }

  // ============================================================
  // BORDER INPUT
  // ============================================================

  OutlineInputBorder _inputBorder({
    Color color = const Color(0xffD1D5DB),
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email =
        _emailController.text.trim().toLowerCase();

    final password =
        _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post(
        '/login',
        {
          'email': email,
          'password': password,
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final prefs =
            await SharedPreferences.getInstance();

        final token =
            responseData['access_token'] ?? '';

        final userRole =
            responseData['user_role'] ?? '';

        String userName = 'Pengguna';

        final rawUserData =
            responseData['user'];

        if (rawUserData != null &&
            rawUserData['name'] != null) {
          userName =
              rawUserData['name'].toString();
        } else if (responseData['message'] != null &&
            responseData['message']
                .toString()
                .contains('Selamat datang,')) {
          userName = responseData['message']
              .toString()
              .split('Selamat datang,')
              .last
              .trim();
        }

        // Simpan data SESSION saja.
        // Email/password tidak disimpan oleh aplikasi.
        await prefs.setString(
          'token',
          token.toString(),
        );

        await prefs.setBool(
          'isLoggedIn',
          true,
        );

        await prefs.setString(
          'role',
          userRole.toString(),
        );

        await prefs.setString(
          'name',
          userName,
        );

        if (!mounted) {
          return;
        }

        final normalizedRole =
            userRole
                .toString()
                .toLowerCase()
                .trim();

        // ======================================================
        // REDIRECT BERDASARKAN ROLE
        // ======================================================

        if (normalizedRole == 'pelanggan') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CustomerMainDashboard(),
            ),
          );
        } else if (normalizedRole == 'mitra') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const PartnerMainDashboard(),
            ),
          );
        } else if (normalizedRole == 'admin' ||
            normalizedRole == 'administrator') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AdminLayout(),
            ),
          );
        } else if (normalizedRole == 'super admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const SuperAdminLayout(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Role '$userRole' tidak dikenali sistem",
              ),
            ),
          );
        }
      } else {
        final message =
            responseData['message'] ??
                'Email atau Password salah';

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.toString(),
            ),
            backgroundColor:
                const Color(0xffEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal terhubung ke server: $e',
          ),
          backgroundColor:
              const Color(0xffEF4444),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor:
              const Color(0xffF8FAFC),
          body: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Container(
                  width: isMobile
                      ? constraints.maxWidth * 0.9
                      : 450,
                  padding: EdgeInsets.all(
                    isMobile ? 24 : 35,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.08,
                        ),
                        blurRadius: 25,
                        offset:
                            const Offset(0, 12),
                      ),
                    ],
                  ),

                  // ==================================================
                  // AUTOFILL GROUP
                  // ==================================================

                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          // ==========================================
                          // LOGO + TITLE
                          // ==========================================

                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width:
                                      isMobile
                                          ? 130
                                          : 160,
                                  height:
                                      isMobile
                                          ? 130
                                          : 160,
                                  decoration:
                                      BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                    child: Image.asset(
                                      'assets/images/Logo_SayaBantu.png',
                                      fit:
                                          BoxFit.contain,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 20,
                                ),

                                Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize:
                                        isMobile
                                            ? 24
                                            : 30,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  'Selamat datang kembali di SayaBantu',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize:
                                        isMobile
                                            ? 13
                                            : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height:
                                isMobile
                                    ? 28
                                    : 35,
                          ),

                          // ==========================================
                          // EMAIL
                          // ==========================================

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          TextFormField(
                            controller:
                                _emailController,
                            focusNode:
                                _emailFocusNode,

                            // Chrome/browser autofill
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],

                            keyboardType:
                                TextInputType.emailAddress,

                            textInputAction:
                                TextInputAction.next,

                            autovalidateMode:
                                AutovalidateMode
                                    .onUserInteraction,

                            onFieldSubmitted: (_) {
                              _passwordFocusNode
                                  .requestFocus();
                            },

                            decoration:
                                InputDecoration(
                              hintText:
                                  'Masukkan email',

                              hintStyle:
                                  TextStyle(
                                color:
                                    Colors.grey.shade500,
                              ),

                              prefixIcon:
                                  Icon(
                                Icons.email_outlined,
                                color:
                                    Colors.grey.shade600,
                              ),

                              enabledBorder:
                                  _inputBorder(),

                              focusedBorder:
                                  _inputBorder(
                                color:
                                    AppColors.primary,
                                width: 1.5,
                              ),

                              errorBorder:
                                  _inputBorder(
                                color:
                                    const Color(
                                  0xffEF4444,
                                ),
                              ),

                              focusedErrorBorder:
                                  _inputBorder(
                                color:
                                    const Color(
                                  0xffEF4444,
                                ),
                                width: 1.5,
                              ),

                              errorStyle:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xffEF4444,
                                ),
                                fontSize: 12,
                              ),
                            ),

                            validator:
                                _validateEmail,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ==========================================
                          // PASSWORD
                          // ==========================================

                          const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          TextFormField(
                            controller:
                                _passwordController,
                            focusNode:
                                _passwordFocusNode,

                            // Chrome/browser autofill
                            autofillHints: const [
                              AutofillHints.password,
                            ],

                            obscureText:
                                _obscurePassword,

                            textInputAction:
                                TextInputAction.done,

                            autovalidateMode:
                                AutovalidateMode
                                    .onUserInteraction,

                            onFieldSubmitted: (_) {
                              if (!_isLoading) {
                                _handleLogin();
                              }
                            },

                            decoration:
                                InputDecoration(
                              hintText:
                                  'Masukkan password',

                              hintStyle:
                                  TextStyle(
                                color:
                                    Colors.grey.shade500,
                              ),

                              prefixIcon:
                                  Icon(
                                Icons.lock_outline,
                                color:
                                    Colors.grey.shade600,
                              ),

                              suffixIcon:
                                  IconButton(
                                tooltip:
                                    _obscurePassword
                                        ? 'Tampilkan password'
                                        : 'Sembunyikan password',

                                onPressed: () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },

                                icon: Icon(
                                  _obscurePassword
                                      ? Icons
                                          .visibility_off_outlined
                                      : Icons
                                          .visibility_outlined,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),

                              enabledBorder:
                                  _inputBorder(),

                              focusedBorder:
                                  _inputBorder(
                                color:
                                    AppColors.primary,
                                width: 1.5,
                              ),

                              errorBorder:
                                  _inputBorder(
                                color:
                                    const Color(
                                  0xffEF4444,
                                ),
                              ),

                              focusedErrorBorder:
                                  _inputBorder(
                                color:
                                    const Color(
                                  0xffEF4444,
                                ),
                                width: 1.5,
                              ),

                              errorStyle:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xffEF4444,
                                ),
                                fontSize: 12,
                              ),
                            ),

                            validator:
                                _validatePassword,
                          ),

                          // ==========================================
                          // LUPA PASSWORD
                          // ==========================================

                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ChangePasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  color:
                                      AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          // ==========================================
                          // TOMBOL MASUK
                          // ==========================================

                          SizedBox(
                            width:
                                double.infinity,
                            child: CustomButton(
                              text: _isLoading
                                  ? 'Memuat...'
                                  : 'Masuk',
                              width:
                                  double.infinity,
                              height: 56,
                              backgroundColor:
                                  AppColors.primary,
                              onPressed:
                                  _isLoading
                                      ? () {}
                                      : _handleLogin,
                            ),
                          ),

                          const SizedBox(
                            height: 25,
                          ),

                          // ==========================================
                          // REGISTER
                          // ==========================================

                          Center(
                            child: Wrap(
                              alignment:
                                  WrapAlignment.center,
                              crossAxisAlignment:
                                  WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Belum punya akun?',
                                ),

                                TextButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushReplacement(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                          _,
                                          __,
                                          ___,
                                        ) =>
                                            const RegisterScreen(),
                                        transitionDuration:
                                            Duration.zero,
                                        reverseTransitionDuration:
                                            Duration.zero,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Daftar',
                                    style: TextStyle(
                                      color:
                                          AppColors.primary,
                                      fontWeight:
                                          FontWeight.bold,
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
            ),
          ),
        );
      },
    );
  }
}