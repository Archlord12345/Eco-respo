import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Titres en Poppins, corps de texte en Inter (planches design).
class AppTextStyles {
  static TextTheme textTheme() {
    final poppins = GoogleFonts.poppinsTextTheme();
    final inter = GoogleFonts.interTextTheme();
    TextStyle? title(TextStyle? base, FontWeight weight) =>
        base?.copyWith(fontWeight: weight, color: AppColors.textBlack, letterSpacing: -0.2);
    return inter.copyWith(
      displayLarge: title(poppins.displayLarge, FontWeight.w700),
      displayMedium: title(poppins.displayMedium, FontWeight.w700),
      displaySmall: title(poppins.displaySmall, FontWeight.w700),
      headlineLarge: title(poppins.headlineLarge, FontWeight.w700),
      headlineMedium: title(poppins.headlineMedium, FontWeight.w600),
      headlineSmall: title(poppins.headlineSmall, FontWeight.w600),
      titleLarge: title(poppins.titleLarge, FontWeight.w600),
      titleMedium: title(poppins.titleMedium, FontWeight.w600),
      titleSmall: title(poppins.titleSmall, FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(color: AppColors.textDark, height: 1.45),
      bodyMedium: inter.bodyMedium?.copyWith(color: AppColors.textDark, height: 1.45),
      bodySmall: inter.bodySmall?.copyWith(color: AppColors.textMuted, height: 1.4),
      labelLarge: poppins.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: inter.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: inter.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
