import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../screens/Screens_auth/login_page.dart';
import '../../screens/Screens_auth/register_page.dart';

class CustomNavbar extends StatelessWidget {
  final VoidCallback onLayanan;
  final VoidCallback onCaraKerja;
  final VoidCallback onMitra;
  final VoidCallback onTentang;

  const CustomNavbar({
    super.key,
    required this.onLayanan,
    required this.onCaraKerja,
    required this.onMitra,
    required this.onTentang,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 768;
        final isTablet = width >= 768 && width < 1024;
        final isLaptop = width >= 1024 && width < 1400;
        final isDesktop = width >= 1400;

        return Container(
          height: 80,
          color: const Color(0xFFF7F3F0),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? 60
                : isLaptop
                    ? 30
                    : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Row(
                children: [
                  Image.asset(
                    "assets/images/logo_sayabantu.png",
                    height: isMobile ? 45 : 60,
                  ).animate().fadeIn().slideX(begin: -.2),

                  const SizedBox(width: 30),

                  if (isDesktop || isLaptop)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _menu(
                            "Layanan",
                            onTap: onLayanan,
                            isLaptop: isLaptop,
                          ),
                          _menu(
                            "Cara Kerja",
                            onTap: onCaraKerja,
                            isLaptop: isLaptop,
                          ),
                          _menu(
                            "Jadi Mitra",
                            onTap: onMitra,
                            isLaptop: isLaptop,
                          ),
                          _menu(
                            "Tentang Kami",
                            onTap: onTentang,
                            isLaptop: isLaptop,
                          ),
                        ],
                      ),
                    ),

                  if (isDesktop || isLaptop) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: const Text("Masuk"),
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(width: 12),

                    CustomButton(
                      text: "Daftar",
                      width: isDesktop ? 160 : 145,
                      height: 48,
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const RegisterScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(.9, .9)),
                  ],

                  if (isTablet || isMobile) const Spacer(),

                  if (isTablet || isMobile)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, size: 30),
                      offset: const Offset(0, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case "layanan":
                            onLayanan();
                            break;
                          case "cara":
                            onCaraKerja();
                            break;
                          case "mitra":
                            onMitra();
                            break;
                          case "tentang":
                            onTentang();
                            break;
                          case "login":
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                            break;
                          case "register":
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "layanan",
                          child: Text("Layanan"),
                        ),
                        PopupMenuItem(
                          value: "cara",
                          child: Text("Cara Kerja"),
                        ),
                        PopupMenuItem(
                          value: "mitra",
                          child: Text("Jadi Mitra"),
                        ),
                        PopupMenuItem(
                          value: "tentang",
                          child: Text("Tentang Kami"),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: "login",
                          child: Text("Masuk"),
                        ),
                        PopupMenuItem(
                          value: "register",
                          child: Text("Daftar"),
                        ),
                      ],
                    ).animate().fadeIn().scale(begin: const Offset(.8, .8)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menu(
    String title, {
    required VoidCallback onTap,
    required bool isLaptop,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLaptop ? 10 : 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        hoverColor: Colors.orange.withOpacity(.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isLaptop ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -.2);
  }
}