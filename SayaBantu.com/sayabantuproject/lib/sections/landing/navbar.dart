import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../screens/Screens_auth/login_page.dart';
import '../../screens/Screens_auth/register_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/safe_mouse_region.dart';

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

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const RegisterScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmallMobile = width < 400;
        final isMobile = width < 900;
        final isDesktop = !isMobile;

        final horizontalPadding = isSmallMobile
            ? 14.0
            : isMobile
                ? 18.0
                : 64.0;

        final verticalPadding = isSmallMobile ? 10.0 : 14.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.darkTeal.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Row(
                  children: [
                    _buildLogo(isSmallMobile: isSmallMobile)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(
                          begin: -0.10,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    if (isDesktop) ...[
                      const Spacer(),
                      _buildDesktopMenu(),
                      const Spacer(),
                    ] else
                      const Spacer(),

                    if (isDesktop)
                      _buildDesktopActions(context)
                    else
                      _buildMobileMenu(context, isSmallMobile: isSmallMobile),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOGO
  // ============================================================
  Widget _buildLogo({required bool isSmallMobile}) {
    final double boxSize = isSmallMobile ? 32 : 38;
    final double iconSize = isSmallMobile ? 18 : 22;
    final double textSize = isSmallMobile ? 17 : 20;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.handyman_rounded,
            color: AppColors.mint,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(
                text: 'Saya',
                style: TextStyle(color: AppColors.darkTeal),
              ),
              TextSpan(
                text: 'Bantu',
                style: TextStyle(color: AppColors.primaryTeal),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENU (desktop)
  // ============================================================
  Widget _buildDesktopMenu() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _menuItem('Layanan', onLayanan, delay: 100),
        _menuItem('Cara Kerja', onCaraKerja, delay: 150),
        _menuItem('Jadi Mitra', onMitra, delay: 200),
        _menuItem('Tentang Kami', onTentang, delay: 250),
      ],
    );
  }

  Widget _menuItem(
    String title,
    VoidCallback onTap, {
    required int delay,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool hovered = false;
        return SafeMouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: () => setState(() => hovered = true),
          onExit: () => setState(() => hovered = false),
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: hovered
                    ? AppColors.mint.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title,
                style: AppTextStyles.navLink.copyWith(
                  color: hovered
                      ? AppColors.primaryTeal
                      : AppColors.grey800,
                  fontWeight: hovered ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: delay))
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.10,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            );
      },
    );
  }

  // ============================================================
  // ACTIONS (desktop)
  // ============================================================
  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => _navigateToLogin(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryTeal,
            side: const BorderSide(
              color: AppColors.primaryTeal,
              width: 1.3,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Masuk',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 400.ms),
        const SizedBox(width: 10),
        CustomButton(
          text: 'Daftar',
          width: 120,
          height: 46,
          backgroundColor: AppColors.primaryTeal,
          onPressed: () => _navigateToRegister(context),
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  // ============================================================
  // MOBILE MENU
  // ============================================================
  Widget _buildMobileMenu(
    BuildContext context, {
    required bool isSmallMobile,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.menu_rounded,
        size: isSmallMobile ? 26 : 28,
        color: AppColors.darkTeal,
      ),
      offset: const Offset(0, 50),
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) {
        switch (value) {
          case 'layanan':
            onLayanan();
            break;
          case 'cara':
            onCaraKerja();
            break;
          case 'mitra':
            onMitra();
            break;
          case 'tentang':
            onTentang();
            break;
          case 'login':
            _navigateToLogin(context);
            break;
          case 'register':
            _navigateToRegister(context);
            break;
        }
      },
      itemBuilder: (_) => [
        _popupItem('layanan', 'Layanan'),
        _popupItem('cara', 'Cara Kerja'),
        _popupItem('mitra', 'Jadi Mitra'),
        _popupItem('tentang', 'Tentang Kami'),
        const PopupMenuDivider(),
        _popupItem('login', 'Masuk'),
        _popupItem('register', 'Daftar'),
      ],
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.85, 0.85));
  }

  PopupMenuItem<String> _popupItem(String value, String title) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        title,
        style: AppTextStyles.navLink.copyWith(
          color: AppColors.darkTeal,
          fontSize: 14,
        ),
      ),
    );
  }
}