import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heroTitle = GoogleFonts.poppins(
    fontSize: 68,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    height: 1.05,
  );

  static TextStyle heroOrange = GoogleFonts.poppins(
    fontSize: 68,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.05,
  );

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 18,
    color: AppColors.grey,
    height: 1.8,
  );

  static TextStyle nav = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}