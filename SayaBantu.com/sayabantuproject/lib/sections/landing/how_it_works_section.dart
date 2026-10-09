import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/safe_mouse_region.dart';

// ============================================================
// HOW IT WORKS SECTION
// ============================================================
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sectionAltLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final isMobile = width < 768;
          final isTablet = width >= 768 && width < 1100;
          final isDesktop = width >= 1100;

          final horizontalPadding = isMobile
              ? 20.0
              : isTablet
                  ? 36.0
                  : 64.0;

          final verticalPadding = isMobile
              ? 56.0
              : isTablet
                  ? 72.0
                  : 88.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionHeader(isMobile: isMobile),
                    SizedBox(
                      height: isMobile ? 36 : (isTablet ? 44 : 52),
                    ),
                    if (isMobile)
                      _buildMobileSteps()
                    else
                      _buildDesktopSteps(isDesktop: isDesktop),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================
  Widget _buildSectionHeader({required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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

        SizedBox(height: isMobile ? 16 : 18),

        Text(
          'Semudah Ini Menggunakan\nSayaBantu',
          textAlign: TextAlign.center,
          style: AppTextStyles.displayOnLight.copyWith(
            fontSize: isMobile ? 28 : 40,
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

        SizedBox(height: isMobile ? 14 : 16),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Temukan jasa yang kamu butuhkan dengan proses yang '
            'sederhana, transparan, dan mudah.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyOnLight.copyWith(
              fontSize: isMobile ? 14 : 15,
            ),
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 600.ms),
      ],
    );
  }

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
          'CARA KERJA',
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
  // MOBILE
  // ============================================================
  Widget _buildMobileSteps() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _HowItWorksCard(
            number: _steps[i].number,
            icon: _steps[i].icon,
            title: _steps[i].title,
            description: _steps[i].description,
          )
              .animate(delay: Duration(milliseconds: 300 + (i * 150)))
              .fadeIn(duration: 500.ms)
              .slideY(
                begin: 0.10,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
          if (i < _steps.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ============================================================
  // DESKTOP / TABLET
  // ============================================================
  Widget _buildDesktopSteps({required bool isDesktop}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: _HowItWorksCard(
              number: _steps[i].number,
              icon: _steps[i].icon,
              title: _steps[i].title,
              description: _steps[i].description,
              fixedHeight: isDesktop ? 260 : 240,
            )
                .animate(delay: Duration(milliseconds: 300 + (i * 150)))
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.10,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: 20),
        ],
      ],
    );
  }

  // ============================================================
  // STEPS DATA
  // ============================================================
  static const List<_StepData> _steps = [
    _StepData(
      number: '01',
      icon: Icons.search_rounded,
      title: 'Cari Jasa',
      description:
          'Temukan layanan dan tenaga profesional sesuai kebutuhanmu dengan mudah.',
    ),
    _StepData(
      number: '02',
      icon: Icons.people_alt_rounded,
      title: 'Pilih Mitra',
      description:
          'Pilih mitra yang sesuai berdasarkan layanan dan kebutuhan pekerjaanmu.',
    ),
    _StepData(
      number: '03',
      icon: Icons.check_circle_rounded,
      title: 'Selesaikan Pekerjaan',
      description:
          'Komunikasikan kebutuhanmu, selesaikan pekerjaan, dan nikmati hasilnya.',
    ),
  ];
}

// ============================================================
// STEP DATA — class terpisah
// ============================================================
class _StepData {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _StepData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ============================================================
// HOW IT WORKS CARD — StatefulWidget terpisah
// ============================================================
class _HowItWorksCard extends StatefulWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final double? fixedHeight;

  const _HowItWorksCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    this.fixedHeight,
  });

  @override
  State<_HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<_HowItWorksCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale =
        _isPressed ? 0.985 : (_isHovered ? 1.015 : 1.0);

    return SafeMouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: () => setState(() => _isHovered = true),
      onExit: () => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            // FIX: pakai minHeight, bukan fixed height
            constraints: widget.fixedHeight != null
                ? BoxConstraints(minHeight: widget.fixedHeight!)
                : null,
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? AppColors.mint.withOpacity(0.55)
                    : AppColors.primaryTeal.withOpacity(0.10),
                width: _isHovered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkTeal.withOpacity(
                    _isHovered ? 0.10 : 0.055,
                  ),
                  blurRadius: _isHovered ? 24 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==========================================
                // TOP ROW
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? AppColors.primaryTeal
                            : AppColors.primaryTeal.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        widget.icon,
                        color: _isHovered
                            ? AppColors.white
                            : AppColors.primaryTeal,
                        size: 25,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.number,
                        style: AppTextStyles.labelOnDark.copyWith(
                          color: AppColors.primaryTeal,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==========================================
                // TITLE
                // ==========================================
                Text(
                  widget.title,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontSize: 18,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                // ==========================================
                // DESCRIPTION — tanpa Expanded
                // ==========================================
                Text(
                  widget.description,
                  style: AppTextStyles.bodyOnLight.copyWith(
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // ==========================================
                // BOTTOM INDICATOR
                // ==========================================
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _isHovered ? 34 : 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.primaryTeal.withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}