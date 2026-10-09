import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sayabantu_project/screens/Screens_auth/register_page.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'benefit_card.dart';

class PartnerCTASection extends StatelessWidget {
  final VoidCallback onDaftarMitra;
  final VoidCallback onPelajari;

  const PartnerCTASection({
    super.key,
    required this.onDaftarMitra,
    required this.onPelajari,
  });

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
                    : 88.0;

        final isHorizontal = !isMobile && !isTablet;

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.sectionGradientStart,
                AppColors.sectionGradientEnd,
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // BACKGROUND DECORATION
              Positioned(
                right: -120,
                top: -120,
                child: IgnorePointer(
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mint.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -100,
                bottom: -100,
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withOpacity(0.04),
                    ),
                  ),
                ),
              ),

              // CONTENT
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Flex(
                      direction:
                          isHorizontal ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT
                        Expanded(
                          flex: isHorizontal ? 5 : 0,
                          child: _buildLeftContent(
                            context: context,
                            isMobile: isMobile,
                            isSmallMobile: isSmallMobile,
                            isHorizontal: isHorizontal,
                          ),
                        ),

                        SizedBox(
                          width: isHorizontal ? 56 : 0,
                          height: isHorizontal ? 0 : (isSmallMobile ? 28 : 40),
                        ),

                        // RIGHT
                        Expanded(
                          flex: isHorizontal ? 4 : 0,
                          child: _benefitGrid(
                            isMobile: isMobile,
                            isSmallMobile: isSmallMobile,
                            isTablet: isTablet,
                          )
                              .animate(delay: 350.ms)
                              .fadeIn(duration: 600.ms)
                              .slideX(
                                begin: 0.15,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
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

  // ============================================================
  // LEFT CONTENT
  // ============================================================
  Widget _buildLeftContent({
    required BuildContext context,
    required bool isMobile,
    required bool isSmallMobile,
    required bool isHorizontal,
  }) {
    final badgePaddingH = isSmallMobile ? 11.0 : 14.0;
    final badgePaddingV = isSmallMobile ? 6.0 : 8.0;
    final badgeFont = isSmallMobile ? 10.0 : 11.5;
    final badgeIconSize = isSmallMobile ? 13.0 : 15.0;

    final titleSize = isSmallMobile
        ? 24.0
        : (isMobile ? 28.0 : (isHorizontal ? 48.0 : 40.0));

    final descSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);

    final gapAfterBadge = isSmallMobile ? 16.0 : 24.0;
    final gapAfterTitle = isSmallMobile ? 14.0 : 20.0;
    final gapBeforeCTA = isSmallMobile ? 22.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BADGE
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: badgePaddingH,
            vertical: badgePaddingV,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkTeal.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.mint.withOpacity(0.55),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.handyman_outlined,
                color: AppColors.mint,
                size: badgeIconSize,
              ),
              const SizedBox(width: 6),
              Text(
                'Untuk Para Mitra & Teknisi',
                style: TextStyle(
                  color: AppColors.lightMint,
                  fontSize: badgeFont,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideX(
              begin: -0.10,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapAfterBadge),

        // TITLE
        RichText(
          text: TextSpan(
            style: AppTextStyles.displayOnDark.copyWith(
              fontSize: titleSize,
              height: 1.12,
            ),
            children: const [
              TextSpan(text: 'Jadikan Keahlianmu\n'),
              TextSpan(
                text: 'Penghasilan Rutin',
                style: TextStyle(color: AppColors.mint),
              ),
            ],
          ),
        )
            .animate(delay: 150.ms)
            .fadeIn(duration: 600.ms)
            .slideY(
              begin: 0.10,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapAfterTitle),

        // DESCRIPTION
        Text(
          'Daftar sebagai mitra dan dapatkan pekerjaan dari ribuan '
          'pelanggan di sekitarmu. Semakin banyak pekerjaan yang selesai, '
          'semakin tinggi reputasi dan peluang dipilih pelanggan.',
          style: AppTextStyles.bodyOnDark.copyWith(
            fontSize: descSize,
            height: 1.55,
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 600.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapBeforeCTA),

        // CTA BUTTONS
        Wrap(
          spacing: isSmallMobile ? 8 : 12,
          runSpacing: isSmallMobile ? 8 : 12,
          children: [
            CustomButton(
              text: 'Daftar Jadi Mitra →',
              width: isSmallMobile ? 170 : (isMobile ? 200 : 210),
              height: isSmallMobile ? 44 : 48,
              backgroundColor: AppColors.mint,
              textColor: AppColors.darkTeal,
              fontSize: isSmallMobile ? 12.5 : 14,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(
                      defaultRole: 'Mitra',
                    ),
                  ),
                );
              },
            ),
            CustomButton(
              text: 'Pelajari Lebih Lanjut',
              width: isSmallMobile ? 170 : (isMobile ? 200 : 210),
              height: isSmallMobile ? 44 : 48,
              outlined: true,
              textColor: AppColors.white,
              fontSize: isSmallMobile ? 12.5 : 14,
              onPressed: onPelajari,
            ),
          ],
        )
            .animate(delay: 450.ms)
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1, 1),
            ),
      ],
    );
  }

  // ============================================================
  // BENEFIT GRID
  // ============================================================
  Widget _benefitGrid({
    required bool isMobile,
    required bool isSmallMobile,
    required bool isTablet,
  }) {
    // Tinggi card per item (pakai mainAxisExtent, biar tidak overflow)
    final double cardHeight;
    if (isSmallMobile) {
      cardHeight = 130.0;
    } else if (isMobile) {
      cardHeight = 140.0;
    } else if (isTablet) {
      cardHeight = 155.0;
    } else {
      cardHeight = 150.0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 2,
      crossAxisSpacing: isSmallMobile ? 12 : 16,
      mainAxisSpacing: isSmallMobile ? 12 : 16,
      childAspectRatio: isMobile ? 2.6 : 1.5,
      children: [
        BenefitCard(
          icon: Icons.payments_outlined,
          title: 'Penghasilan Fleksibel',
          description: 'Tentukan sendiri harga jasa sesuai kemampuanmu.',
          isCompact: isSmallMobile,
        ),
        BenefitCard(
          icon: Icons.emoji_events_outlined,
          title: 'Sistem Poin Adil',
          description:
              'Semakin bagus pelayanan, semakin tinggi peringkatmu.',
          isCompact: isSmallMobile,
        ),
        BenefitCard(
          icon: Icons.notifications_active_outlined,
          title: 'Notifikasi Real-time',
          description: 'Pekerjaan baru langsung masuk ke perangkatmu.',
          isCompact: isSmallMobile,
        ),
        BenefitCard(
          icon: Icons.verified_user_outlined,
          title: 'Perlindungan Mitra',
          description: 'Pembayaran aman setelah pekerjaan selesai.',
          isCompact: isSmallMobile,
        ),
      ],
    );
  }
}