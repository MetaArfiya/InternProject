import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

class AboutSection extends StatelessWidget {
  final VoidCallback? onContact;

  const AboutSection({super.key, this.onContact});

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

        final titleSize = isSmallMobile
            ? 22.0
            : isMobile
                ? 26.0
                : isTablet
                    ? 34.0
                    : 42.0;

        final descSize = isSmallMobile
            ? 12.5
            : isMobile
                ? 13.5
                : 16.0;

        return Container(
          width: double.infinity,
          color: AppColors.sectionLight,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    _buildSectionLabel()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                          begin: 0.10,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    SizedBox(height: isSmallMobile ? 10 : 14),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Text(
                        'Tentang SayaBantu',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayOnLight.copyWith(
                          fontSize: titleSize,
                        ),
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(
                          begin: 0.10,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    SizedBox(height: isSmallMobile ? 12 : 16),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        'SayaBantu lahir dari satu keyakinan sederhana: '
                        'setiap orang berhak mendapatkan bantuan '
                        'berkualitas untuk kebutuhan rumahnya, dengan '
                        'harga yang transparan dan mitra yang terpercaya.\n\n'
                        'Kami menghubungkan kamu dengan ribuan mitra '
                        'terverifikasi di seluruh Indonesia — tanpa '
                        'perantara, tanpa biaya tersembunyi, dan tanpa '
                        'patokan harga sepihak.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyOnLight.copyWith(
                          fontSize: descSize,
                          height: 1.65,
                        ),
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 600.ms),

                    SizedBox(
                      height: isSmallMobile ? 24 : (isMobile ? 32 : 56),
                    ),

                    _buildValueCards(
                      isMobile: isMobile,
                      isSmallMobile: isSmallMobile,
                    ),

                    SizedBox(
                      height: isSmallMobile ? 24 : (isMobile ? 32 : 56),
                    ),

                    _buildCTA(isMobile: isMobile)
                        .animate(delay: 800.ms)
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1, 1),
                        ),
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
  // SECTION LABEL
  // ============================================================
  Widget _buildSectionLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'TENTANG KAMI',
          style: TextStyle(
            color: AppColors.primaryTeal,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VALUE CARDS
  // ============================================================
  Widget _buildValueCards({
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final values = const [
      (
        icon: Icons.verified_user_outlined,
        title: 'Terverifikasi',
        desc: 'Semua mitra melewati verifikasi admin.',
      ),
      (
        icon: Icons.visibility_outlined,
        title: 'Transparan',
        desc: 'Harga & penawaran terlihat jelas.',
      ),
      (
        icon: Icons.shield_outlined,
        title: 'Aman',
        desc: 'Pembayaran diteruskan setelah pekerjaan selesai.',
      ),
      (
        icon: Icons.flash_on_outlined,
        title: 'Cepat',
        desc: 'Penawaran masuk dalam hitungan menit.',
      ),
    ];

    // ==========================================
    // SKALA UKURAN
    // ==========================================
    final cardPadding = isSmallMobile ? 14.0 : 18.0;
    final cardRadius = isSmallMobile ? 14.0 : 16.0;
    final iconBox = isSmallMobile ? 36.0 : 42.0;
    final iconSize = isSmallMobile ? 18.0 : 22.0;
    final iconRadius = isSmallMobile ? 10.0 : 11.0;
    final titleFont = isSmallMobile ? 13.0 : 15.0;
    final descFont = isSmallMobile ? 11.5 : 12.5;
    final gapIconTitle = isSmallMobile ? 10.0 : 12.0;
    final gapTitleDesc = isSmallMobile ? 4.0 : 6.0;

    final cards = values.map((v) {
      return Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: AppColors.primaryTeal.withOpacity(0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkTeal.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.15),
                borderRadius: BorderRadius.circular(iconRadius),
              ),
              child: Icon(
                v.icon,
                color: AppColors.primaryTeal,
                size: iconSize,
              ),
            ),
            SizedBox(height: gapIconTitle),
            Text(
              v.title,
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: titleFont,
                color: AppColors.grey900,
              ),
            ),
            SizedBox(height: gapTitleDesc),
            Text(
              v.desc,
              style: AppTextStyles.bodySmallOnLight.copyWith(
                fontSize: descFont,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }).toList();

    // ==========================================
    // LAYOUT
    // ==========================================
    if (isMobile) {
      // Mobile → horizontal scroll, tinggi fixed biar aman
      final cardWidth = isSmallMobile ? 220.0 : 260.0;
      final cardHeight = isSmallMobile ? 175.0 : 195.0;

      return SizedBox(
        height: cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: cards.length,
          separatorBuilder: (_, __) =>
              SizedBox(width: isSmallMobile ? 10 : 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: cardWidth,
              child: cards[index]
                  .animate(
                    delay: Duration(milliseconds: 300 + (index * 100)),
                  )
                  .fadeIn(duration: 500.ms)
                  .slideX(
                    begin: 0.10,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
            );
          },
        ),
      );
    }

    // Desktop / tablet → grid 4 kolom
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: e.key == 0 ? 0 : 8,
                    right: e.key == cards.length - 1 ? 0 : 8,
                  ),
                  child: e.value
                      .animate(
                        delay: Duration(milliseconds: 300 + (e.key * 100)),
                      )
                      .fadeIn(duration: 500.ms)
                      .slideY(
                        begin: 0.10,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ))
          .toList(),
    );
  }

  // ============================================================
  // CTA
  // ============================================================
  Widget _buildCTA({required bool isMobile}) {
    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton.icon(
        onPressed: onContact,
        icon: Icon(
          Icons.chat_bubble_outline_rounded,
          size: isMobile ? 15 : 17,
        ),
        label: Text(
          'Hubungi Kami',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 22,
            vertical: isMobile ? 14 : 16,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}