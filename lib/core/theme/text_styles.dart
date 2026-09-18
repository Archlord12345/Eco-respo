import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTextStyles {
  static TextTheme textTheme() {
    final poppins = GoogleFonts.poppinsTextTheme();
    final inter = GoogleFonts.interTextTheme();
    return inter.copyWith(
      displayLarge: poppins.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textBlack,
      ),
      headlineLarge: poppins.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textBlack,
      ),
      headlineMedium: poppins.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textBlack,
      ),
      titleLarge: poppins.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textBlack,
      ),
      titleMedium: poppins.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textBlack,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(color: AppColors.textDark),
      bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.textDark),
      labelLarge: poppins.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
