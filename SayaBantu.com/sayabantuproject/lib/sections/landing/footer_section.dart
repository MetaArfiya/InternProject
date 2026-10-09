import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmallMobile = width < 400;
        final isMobile = width < 768;
        final isTablet = width >= 768 && width < 1100;

        final horizontalPadding = isSmallMobile
            ? 16.0
            : isMobile
                ? 20.0
                : isTablet
                    ? 36.0
                    : 64.0;

        final verticalPadding = isSmallMobile
            ? 40.0
            : isMobile
                ? 48.0
                : isTablet
                    ? 64.0
                    : 80.0;

        return Container(
          width: double.infinity,
          color: AppColors.darkTeal,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -100,
                top: -100,
                child: IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mint.withOpacity(0.05),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile)
                          _buildMobileLayout(isSmallMobile: isSmallMobile)
                        else
                          _buildDesktopLayout(isTablet: isTablet),
                        SizedBox(height: isMobile ? 32 : 48),
                        Container(
                          height: 1,
                          color: AppColors.white.withOpacity(0.10),
                        ),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildBottomBar(isMobile: isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout({required bool isTablet}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: isTablet ? 5 : 4, child: _buildBrandColumn()),
        SizedBox(width: isTablet ? 32 : 48),
        Expanded(
          flex: 3,
          child: _buildLinkColumn(
            title: 'Navigasi',
            links: const [
              _FooterLink(label: 'Layanan', route: '#layanan'),
              _FooterLink(label: 'Cara Kerja', route: '#cara-kerja'),
              _FooterLink(label: 'Jadi Mitra', route: '#mitra'),
              _FooterLink(label: 'Tentang Kami', route: '#tentang'),
            ],
          ),
        ),
        SizedBox(width: isTablet ? 24 : 40),
        Expanded(
          flex: 3,
          child: _buildLinkColumn(
            title: 'Layanan',
            links: const [
              _FooterLink(label: 'Kebersihan', route: '#kebersihan'),
              _FooterLink(label: 'Perbaikan Rumah', route: '#perbaikan'),
              _FooterLink(label: 'Pindahan', route: '#pindahan'),
              _FooterLink(label: 'Servis AC', route: '#ac'),
            ],
          ),
        ),
        SizedBox(width: isTablet ? 24 : 40),
        Expanded(flex: 4, child: _buildContactColumn()),
      ],
    );
  }

  Widget _buildMobileLayout({required bool isSmallMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandColumn(isSmallMobile: isSmallMobile),
        SizedBox(height: isSmallMobile ? 28 : 36),
        _buildLinkColumn(
          title: 'Navigasi',
          links: const [
            _FooterLink(label: 'Layanan', route: '#layanan'),
            _FooterLink(label: 'Cara Kerja', route: '#cara-kerja'),
            _FooterLink(label: 'Jadi Mitra', route: '#mitra'),
            _FooterLink(label: 'Tentang Kami', route: '#tentang'),
          ],
        ),
        SizedBox(height: isSmallMobile ? 24 : 32),
        _buildLinkColumn(
          title: 'Layanan',
          links: const [
            _FooterLink(label: 'Kebersihan', route: '#kebersihan'),
            _FooterLink(label: 'Perbaikan Rumah', route: '#perbaikan'),
            _FooterLink(label: 'Pindahan', route: '#pindahan'),
            _FooterLink(label: 'Servis AC', route: '#ac'),
          ],
        ),
        SizedBox(height: isSmallMobile ? 24 : 32),
        _buildContactColumn(),
      ],
    );
  }

  Widget _buildBrandColumn({bool isSmallMobile = false}) {
    final double boxSize = isSmallMobile ? 34 : 40;
    final double iconSize = isSmallMobile ? 18 : 22;
    final double textSize = isSmallMobile ? 17 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.handyman_rounded,
                color: AppColors.darkTeal,
                size: iconSize,
              ),
            ),
            const SizedBox(width: 10),
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
                    style: TextStyle(color: AppColors.white),
                  ),
                  TextSpan(
                    text: 'Bantu',
                    style: TextStyle(color: AppColors.mint),
                  ),
                  TextSpan(
                    text: '.com',
                    style: TextStyle(
                      color: AppColors.lightMint,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallMobile ? 14 : 18),
        Text(
          'Platform yang menghubungkan kamu dengan mitra '
          'terverifikasi untuk semua kebutuhan rumah. '
          'Transparan, aman, dan tanpa biaya posting.',
          style: AppTextStyles.bodySmallOnDark.copyWith(
            fontSize: isSmallMobile ? 12 : 13,
            height: 1.7,
          ),
        ),
        SizedBox(height: isSmallMobile ? 18 : 22),
        Row(
          children: [
            _socialIcon(Icons.camera_alt_outlined, isSmallMobile: isSmallMobile),
            SizedBox(width: isSmallMobile ? 8 : 10),
            _socialIcon(Icons.facebook_rounded, isSmallMobile: isSmallMobile),
            SizedBox(width: isSmallMobile ? 8 : 10),
            _socialIcon(Icons.play_circle_outline_rounded, isSmallMobile: isSmallMobile),
            SizedBox(width: isSmallMobile ? 8 : 10),
            _socialIcon(Icons.chat_bubble_outline_rounded, isSmallMobile: isSmallMobile),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, {bool isSmallMobile = false}) {
    final double size = isSmallMobile ? 36 : 40;
    final double iconSize = isSmallMobile ? 16 : 18;

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: AppColors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.lightMint, size: iconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkColumn({
    required String title,
    required List<_FooterLink> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.mint,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        for (final link in links) ...[
          _buildLinkItem(link),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildLinkItem(_FooterLink link) {
    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            link.label,
            style: AppTextStyles.bodySmallOnDark.copyWith(
              fontSize: 13,
              color: AppColors.white.withOpacity(0.72),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hubungi Kami',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.mint,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        _buildContactItem(
          icon: Icons.email_outlined,
          text: 'hello@sayabantu.com',
        ),
        const SizedBox(height: 10),
        _buildContactItem(
          icon: Icons.phone_outlined,
          text: '+62 812-3456-0000',
        ),
        const SizedBox(height: 10),
        _buildContactItem(
          icon: Icons.location_on_outlined,
          text: 'Yogyakarta, Indonesia',
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.mint.withOpacity(0.75),
          size: 15,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmallOnDark.copyWith(
              fontSize: 12.5,
              color: AppColors.white.withOpacity(0.72),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar({required bool isMobile}) {
    final copyrightText = Text(
      '© ${DateTime.now().year} SayaBantu.com — Semua hak dilindungi.',
      style: AppTextStyles.bodySmallOnDark.copyWith(
        fontSize: 11.5,
        color: AppColors.white.withOpacity(0.55),
      ),
    );

    final legalLinks = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _bottomLink('Kebijakan Privasi'),
        const SizedBox(width: 14),
        _bottomLink('Syarat & Ketentuan'),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          legalLinks,
          const SizedBox(height: 10),
          copyrightText,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [copyrightText, legalLinks],
    );
  }

  Widget _bottomLink(String text) {
    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: AppTextStyles.bodySmallOnDark.copyWith(
            fontSize: 11.5,
            color: AppColors.white.withOpacity(0.70),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final String route;

  const _FooterLink({
    required this.label,
    required this.route,
  });
}