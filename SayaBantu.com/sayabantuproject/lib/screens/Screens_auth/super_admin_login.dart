import 'package:flutter/material.dart';
import '../Screens_super_admin/super_admin_layout.dart';

class SuperAdminLogin extends StatefulWidget {
  const SuperAdminLogin({super.key});

  @override
  State<SuperAdminLogin> createState() => _SuperAdminLoginState();
}

class _SuperAdminLoginState extends State<SuperAdminLogin> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 800),
    );

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ==========================================================
    // LOGIN SUPER ADMIN SEMENTARA
    // ==========================================================

    if (email == 'superadmin@sayabantu.com' &&
        password == '123456') {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const SuperAdminLayout(),
        ),
        (route) => false,
      );

      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Email atau password Super Admin salah.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth > 450
                      ? 420
                      : double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // ICON
                        // ==================================================

                        Center(
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF476F),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '⚡',
                                style: TextStyle(
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // TITLE
                        // ==================================================

                        const Center(
                          child: Text(
                            'Super Admin',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Center(
                          child: Text(
                            'Full Control Access',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFEF476F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ==================================================
                        // EMAIL
                        // ==================================================

                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText:
                                'Masukkan email Super Admin',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFEF476F),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText:
                                'Masukkan password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword =
                                      !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xFFEF476F),
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        // ==================================================
                        // LOGIN BUTTON
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _login,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFEF476F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Masuk sebagai Super Admin',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // INFO
                        // ==================================================

                        const Center(
                          child: Text(
                            'Akses khusus Super Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}