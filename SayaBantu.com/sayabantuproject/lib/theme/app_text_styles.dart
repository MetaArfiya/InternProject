import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ============================================================
  // DISPLAY — Hero Headline (On Dark)
  // ============================================================
  static final TextStyle displayOnDark = GoogleFonts.poppins(
    fontSize: 68,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    height: 1.08,
    letterSpacing: -1.5,
  );

  static final TextStyle displayAccentOnDark = GoogleFonts.poppins(
    fontSize: 68,
    fontWeight: FontWeight.w800,
    color: AppColors.mint,
    height: 1.08,
    letterSpacing: -1.5,
  );

  // ============================================================
  // DISPLAY — Section Headline (On Light)
  // ============================================================
  static final TextStyle displayOnLight = GoogleFonts.poppins(
    fontSize: 42,
    fontWeight: FontWeight.w800,
    color: AppColors.grey900,
    height: 1.12,
    letterSpacing: -0.8,
  );

  // ============================================================
  // HEADING
  // ============================================================
  static final TextStyle headingLargeOnLight = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.grey900,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static final TextStyle headingMediumOnLight = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.grey900,
    height: 1.3,
  );

  static final TextStyle headingSmall = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.grey900,
    height: 1.35,
  );

  // ============================================================
  // BODY
  // ============================================================
  static final TextStyle bodyOnDark = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Colors.white.withOpacity(0.82),
    height: 1.6,
    letterSpacing: 0.05,
  );

  static final TextStyle bodyOnLight = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.grey600,
    height: 1.65,
    letterSpacing: 0.05,
  );

  static final TextStyle bodySmallOnLight = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.grey600,
    height: 1.55,
  );

  static final TextStyle bodySmallOnDark = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white.withOpacity(0.70),
    height: 1.5,
  );

  // ============================================================
  // LABEL / BADGE
  // ============================================================
  static final TextStyle labelOnDark = GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.lightMint,
    letterSpacing: 0.2,
  );

  static final TextStyle labelOnLight = GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.grey700,
    letterSpacing: 0.2,
  );

  // ============================================================
  // BUTTON
  // ============================================================
  static final TextStyle buttonSearch = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 0.1,
  );

  static final TextStyle buttonPrimary = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTeal,
    letterSpacing: 0.1,
  );

  static final TextStyle buttonSecondaryOnDark = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.1,
  );

  // ============================================================
  // STATISTIK
  // ============================================================
  static final TextStyle statValue = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: -0.3,
  );

  static final TextStyle statLabel = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.68),
  );

  // ============================================================
  // MOCKUP (HeroRight)
  // ============================================================
  static final TextStyle mockupTitle = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.lightMint,
    letterSpacing: 0.7,
    height: 1.3,
  );

  static final TextStyle mockupName = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static final TextStyle mockupMeta = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static final TextStyle mockupMetaSoft = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Colors.white.withOpacity(0.60),
  );

  static final TextStyle mockupPrice = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static final TextStyle mockupPriceActive = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.mint,
  );

  static final TextStyle mockupBadge = GoogleFonts.poppins(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: AppColors.lightMint,
  );

  static final TextStyle mockupEmptyTitle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static final TextStyle mockupEmptySubtitle = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Colors.white.withOpacity(0.65),
  );

  static final TextStyle badgeVerifiedTitle = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTeal,
  );

  static final TextStyle badgeVerifiedSubtitle = GoogleFonts.poppins(
    fontSize: 9,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryTeal,
  );

  static final TextStyle badgeOnline = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static final TextStyle navLink = GoogleFonts.poppins(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    color: AppColors.grey800,
    letterSpacing: 0.1,
  );

  static final TextStyle navLinkActive = GoogleFonts.poppins(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTeal,
    letterSpacing: 0.1,
  );
}