import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import 'hero_left.dart';
import 'hero_right.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onCariJasa;
  final VoidCallback onJadiMitra;
  final Function(String) onSearch;

  const HeroSection({
    super.key,
    required this.onCariJasa,
    required this.onJadiMitra,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    final isSmallMobile = width < 400;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1100;
    final isSmallHeight = size.height < 720;

    final horizontalPadding = isSmallMobile
        ? 16.0
        : isMobile
            ? 20.0
            : isTablet
                ? 36.0
                : 64.0;

    final verticalPadding = isSmallMobile
        ? 32.0
        : isMobile
            ? 44.0
            : isSmallHeight
                ? 72.0
                : 96.0;

    final blobLarge = width * 0.45;
    final blobMedium = width * 0.38;

    // Mobile → tidak paksa full-height
    final double heroMinHeight = isMobile
        ? 0
        : size.height.clamp(600.0, 900.0);

    return ClipRect(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: heroMinHeight),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkTeal, AppColors.primaryTeal],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -blobLarge * 0.3,
              top: -blobLarge * 0.3,
              child: IgnorePointer(
                child: _blob(blobLarge, AppColors.mint.withOpacity(0.07)),
              ),
            ),
            Positioned(
              right: width * 0.06,
              bottom: -blobMedium * 0.5,
              child: IgnorePointer(
                child: _blob(
                  blobMedium,
                  AppColors.white.withOpacity(0.035),
                ),
              ),
            ),
            Positioned(
              left: -blobMedium * 0.4,
              bottom: -blobMedium * 0.5,
              child: IgnorePointer(
                child: _blob(blobMedium, AppColors.mint.withOpacity(0.045)),
              ),
            ),

            SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: heroMinHeight),
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: isMobile
                            ? _buildMobileLayout(isSmallMobile: isSmallMobile)
                            : _buildDesktopLayout(isTablet: isTablet),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout({required bool isSmallMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HeroLeft(
          onCariJasa: onCariJasa,
          onJadiMitra: onJadiMitra,
          onSearch: onSearch,
          isCompact: isSmallMobile, // ← pass flag
        )
            .animate()
            .fade(duration: 700.ms)
            .slideY(
              begin: 0.10,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 700.ms,
            ),
        SizedBox(height: isSmallMobile ? 28 : 36),
        const HeroRight()
            .animate()
            .fade(delay: 200.ms, duration: 700.ms)
            .slideY(
              begin: 0.10,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 700.ms,
            ),
      ],
    );
  }

  Widget _buildDesktopLayout({required bool isTablet}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 11,
          child: HeroLeft(
            onCariJasa: onCariJasa,
            onJadiMitra: onJadiMitra,
            onSearch: onSearch,
          )
              .animate()
              .fade(duration: 800.ms)
              .slideX(
                begin: -0.10,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 800.ms,
              ),
        ),
        SizedBox(width: isTablet ? 32.0 : 56.0),
        Expanded(
          flex: 10,
          child: const HeroRight()
              .animate()
              .fade(delay: 200.ms, duration: 800.ms)
              .slideX(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic,
                duration: 800.ms,
              )
              .scale(
                begin: const Offset(0.97, 0.97),
                end: const Offset(1.0, 1.0),
                duration: 800.ms,
              ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}