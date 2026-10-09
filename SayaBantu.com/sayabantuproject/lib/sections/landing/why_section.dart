import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'feature_item.dart';

class WhySection extends StatelessWidget {
  const WhySection({super.key});

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

        return Container(
          color: AppColors.sectionLight,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: isMobile
                    ? Column(
                        children: [
                          _content(
                            isMobile: isMobile,
                            isSmallMobile: isSmallMobile,
                          ),
                          SizedBox(height: isSmallMobile ? 28 : 40),
                          _imageSection(
                            isMobile: isMobile,
                            isSmallMobile: isSmallMobile,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _content(
                              isMobile: isMobile,
                              isSmallMobile: isSmallMobile,
                            ),
                          ),
                          const SizedBox(width: 64),
                          Expanded(
                            child: _imageSection(
                              isMobile: isMobile,
                              isSmallMobile: isSmallMobile,
                            ),
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
  // CONTENT
  // ============================================================
  Widget _content({
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final titleSize = isSmallMobile ? 24.0 : (isMobile ? 28.0 : 42.0);
    final descSize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 16.0);
    final gapAfterLabel = isSmallMobile ? 10.0 : 14.0;
    final gapAfterTitle = isSmallMobile ? 14.0 : 18.0;
    final gapBeforeFeatures = isSmallMobile ? 20.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION LABEL
        Row(
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
              'KENAPA SAYABANTU?',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideX(
              begin: -0.10,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapAfterLabel),

        // TITLE
        RichText(
          text: TextSpan(
            style: AppTextStyles.displayOnLight.copyWith(
              fontSize: titleSize,
              height: 1.12,
            ),
            children: const [
              TextSpan(text: 'Bukan Sekadar\n'),
              TextSpan(
                text: 'Direktori Tukang',
                style: TextStyle(color: AppColors.primaryTeal),
              ),
            ],
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 600.ms).slideY(
              begin: 0.10,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapAfterTitle),

        // DESCRIPTION
        Text(
          'SayaBantu dirancang dengan mekanisme kompetitif yang '
          'memastikan kamu selalu mendapatkan mitra terpercaya '
          'dengan harga terbaik tanpa patokan harga sepihak.',
          style: AppTextStyles.bodyOnLight.copyWith(fontSize: descSize),
        ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideY(
              begin: 0.10,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: gapBeforeFeatures),

        // FEATURES
        ..._buildFeatures(isSmallMobile: isSmallMobile),
      ],
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================
  List<Widget> _buildFeatures({required bool isSmallMobile}) {
    final features = [
      const _FeatureData(
        icon: Icons.workspace_premium_outlined,
        title: 'Sistem Poin & Reputasi',
        description:
            'Mitra dengan poin tertinggi tampil lebih dulu sehingga '
            'kamu lebih mudah menemukan penyedia jasa terbaik.',
      ),
      const _FeatureData(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Negosiasi Harga Transparan',
        description:
            'Lihat semua penawaran, bandingkan harga dan pilih yang sesuai.',
      ),
      const _FeatureData(
        icon: Icons.verified_user_outlined,
        title: 'Semua Mitra Diverifikasi Admin',
        description:
            'Seluruh mitra melewati proses verifikasi identitas.',
      ),
      const _FeatureData(
        icon: Icons.flash_on_rounded,
        title: 'Real-time, Seperti Ojek Online',
        description:
            'Penawaran masuk dalam hitungan menit.',
      ),
    ];

    final widgets = <Widget>[];
    final gap = isSmallMobile ? 12.0 : 18.0;

    for (int i = 0; i < features.length; i++) {
      final f = features[i];
      widgets.add(
        FeatureItem(
          icon: f.icon,
          bgColor: AppColors.mint.withOpacity(0.15),
          iconColor: AppColors.primaryTeal,
          title: f.title,
          description: f.description,
        )
            .animate(delay: Duration(milliseconds: 500 + (i * 150)))
            .fadeIn(duration: 500.ms)
            .slideX(
              begin: -0.10,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
      );
      if (i < features.length - 1) {
        widgets.add(SizedBox(height: gap));
      }
    }
    return widgets;
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================
  Widget _imageSection({
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    final imageHeight = isSmallMobile ? 280.0 : (isMobile ? 340.0 : 520.0);
    final imageRadius = isSmallMobile ? 20.0 : 28.0;
    final badgePadding = isSmallMobile ? 12.0 : 18.0;
    final badgeFontBig = isSmallMobile ? 20.0 : 26.0;
    final mitraPadding = isSmallMobile ? 12.0 : 18.0;
    final avatarRadius = isSmallMobile ? 18.0 : 24.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ======================================================
        // MAIN IMAGE
        // ======================================================
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(imageRadius),
            image: const DecorationImage(
              image: AssetImage('assets/images/worker.jpg'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkTeal.withOpacity(0.20),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 700.ms).slideX(
              begin: 0.15,
              end: 0,
              duration: 700.ms,
              curve: Curves.easeOutCubic,
            ),

        // ======================================================
        // FLOATING BADGE — Penawaran
        // ======================================================
        Positioned(
          right: 10,
          top: isSmallMobile ? 16 : 30,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: badgePadding,
              vertical: badgePadding - 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.darkTeal,
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 14 : 18,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENAWARAN DITERIMA',
                  style: AppTextStyles.statLabel.copyWith(
                    fontSize: isSmallMobile ? 9 : 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp 170.000 ✓',
                  style: AppTextStyles.statValue.copyWith(
                    color: AppColors.mint,
                    fontSize: badgeFontBig,
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 500.ms)
              .fadeIn(duration: 600.ms)
              .slideX(begin: 0.15)
              .then()
              .moveY(begin: 0, end: -8, duration: 1500.ms)
              .moveY(begin: -8, end: 0, duration: 1500.ms),
        ),

        // ======================================================
        // FLOATING BADGE — Mitra
        // ======================================================
        Positioned(
          left: isSmallMobile ? 14 : 25,
          right: isSmallMobile ? 14 : 25,
          bottom: isSmallMobile ? 14 : 25,
          child: Container(
            padding: EdgeInsets.all(mitraPadding),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 16 : 22,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: AppColors.primaryTeal,
                  child: Text(
                    'BS',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallMobile ? 12 : 14,
                    ),
                  ),
                ),
                SizedBox(width: isSmallMobile ? 10 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pak Budi Santoso',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: isSmallMobile ? 13 : 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AC & Elektronik • 248 Poin • ⭐ 4.9',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmallOnLight.copyWith(
                          fontSize: isSmallMobile ? 10.5 : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 800.ms)
              .fadeIn(duration: 700.ms)
              .slideY(begin: 0.15)
              .scale(begin: const Offset(0.95, 0.95))
              .then()
              .moveY(begin: 0, end: -6, duration: 1800.ms)
              .moveY(begin: -6, end: 0, duration: 1800.ms),
        ),
      ],
    );
  }
}

// ============================================================
// FEATURE DATA
// ============================================================
class _FeatureData {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}