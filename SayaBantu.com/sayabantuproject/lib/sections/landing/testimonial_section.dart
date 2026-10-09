import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'testimonial_card.dart';

class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});

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
            ? 24.0
            : isMobile
                ? 28.0
                : isTablet
                    ? 34.0
                    : 42.0;

        // DATA TESTIMONI
        final cards = <Widget>[
          const TestimonialCard(
            category: 'Service AC Bocor',
            categoryIcon: Icons.ac_unit_rounded,
            review:
                '"Baru posting 10 menit, sudah ada 4 mitra yang nawar! '
                'Saya tinggal pilih yang poinnya paling tinggi. '
                'Kerjanya rapi dan profesional."',
            name: 'Anisa Rahmawati',
            job: 'Ibu Rumah Tangga, Cilandak',
            avatar: 'AR',
          ),
          const TestimonialCard(
            category: 'Cat Ulang 8 Kamar Kos',
            categoryIcon: Icons.format_paint_rounded,
            review:
                '"Sebagai pemilik kos saya sering butuh tukang mendadak. '
                'Sekarang tinggal posting di SayaBantu dan tunggu '
                'penawaran masuk."',
            name: 'Rendra Kusuma',
            job: 'Pemilik Kos, Mampang',
            avatar: 'RK',
          ),
          const TestimonialCard(
            category: 'Instalasi Wallpaper & Lampu',
            categoryIcon: Icons.lightbulb_outline_rounded,
            review:
                '"Yang saya suka adalah transparansinya. Semua penawaran '
                'langsung terlihat sehingga saya bebas membandingkan harga."',
            name: 'Sari Dewi Putri',
            job: 'Desainer Interior, Jakarta Selatan',
            avatar: 'SD',
          ),
        ];

        return Container(
          width: double.infinity,
          color: AppColors.sectionAltLight,
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

                    SizedBox(height: isSmallMobile ? 12 : 16),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.displayOnLight.copyWith(
                          fontSize: titleSize,
                          height: 1.12,
                        ),
                        children: const [
                          TextSpan(text: 'Mereka Sudah Merasakan\n'),
                          TextSpan(
                            text: 'Bedanya SayaBantu',
                            style: TextStyle(color: AppColors.primaryTeal),
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

                    SizedBox(
                      height: isSmallMobile ? 28 : (isMobile ? 36 : 56),
                    ),

                    if (isMobile)
                      _buildMobileCards(
                        cards,
                        isSmallMobile: isSmallMobile,
                      )
                    else
                      _buildDesktopCards(cards),

                    SizedBox(
                      height: isSmallMobile ? 28 : (isMobile ? 36 : 56),
                    ),

                    _buildFooterStats(
                      isMobile: isMobile,
                      isSmallMobile: isSmallMobile,
                    )
                        .animate(delay: 700.ms)
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
          'ULASAN PELANGGAN',
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
  // MOBILE CARDS
  // ============================================================
  Widget _buildMobileCards(
    List<Widget> cards, {
    required bool isSmallMobile,
  }) {
    final gap = isSmallMobile ? 12.0 : 16.0;

    return Column(
      children: cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: card
              .animate(delay: Duration(milliseconds: 300 + (index * 150)))
              .fadeIn(duration: 500.ms)
              .slideY(
                begin: 0.10,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // DESKTOP CARDS
  // ============================================================
  Widget _buildDesktopCards(List<Widget> cards) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 10,
                right: index == cards.length - 1 ? 0 : 10,
              ),
              child: card
                  .animate(
                    delay: Duration(milliseconds: 300 + (index * 150)),
                  )
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.10,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // FOOTER STATS
  // ============================================================
  Widget _buildFooterStats({
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final avatarSize = isSmallMobile ? 28.0 : 34.0;
    final overlap = isSmallMobile ? 10.0 : 12.0;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: isSmallMobile ? 10 : (isMobile ? 16 : 24),
      runSpacing: isSmallMobile ? 10 : 14,
      children: [
        SizedBox(
          height: avatarSize,
          width: avatarSize * 5 - (5 - 1) * overlap,
          child: Stack(
            children: List.generate(5, (index) {
              const avatars = ['AR', 'BS', 'RK', 'EP', 'SD'];
              final colors = [
                AppColors.primaryTeal,
                AppColors.darkTeal,
                AppColors.mint,
                AppColors.primaryTeal,
                AppColors.darkTeal,
              ];
              return Positioned(
                left: index * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.sectionAltLight,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatars[index],
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: isSmallMobile ? 8 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        _buildStatText(
          '8.200+ ulasan dari pelanggan nyata',
          isSmallMobile: isSmallMobile,
        ),
        _buildStatText(
          '4.9 / 5 rata-rata kepuasan',
          icon: Icons.star_rounded,
          iconColor: AppColors.starYellow,
          isSmallMobile: isSmallMobile,
        ),
        _buildStatText(
          '98% masalah terselesaikan',
          isSmallMobile: isSmallMobile,
        ),
      ],
    );
  }

  Widget _buildStatText(
    String text, {
    IconData? icon,
    Color? iconColor,
    required bool isSmallMobile,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? AppColors.starYellow,
            size: isSmallMobile ? 16 : 20,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: AppTextStyles.bodySmallOnLight.copyWith(
            fontSize: isSmallMobile ? 11.5 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}