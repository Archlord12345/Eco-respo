import 'package:flutter/material.dart';

import 'colors.dart';
import 'text_styles.dart';

/// Thème global Éco-Responsable : coins arrondis, boutons pill, cartes blanches
/// sur fond #F8F7F1, vert #2E7D32 comme couleur d'action.
class AppTheme {
  static const radiusCard = 20.0;
  static const radiusField = 16.0;
  static const radiusChip = 12.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: AppColors.paleGreen,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.earthOchre,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.paleOchre,
      onSecondaryContainer: const Color(0xFF6B4E0E),
      tertiary: AppColors.institutionalBlue,
      surface: AppColors.neutralBackground,
      onSurface: AppColors.textBlack,
      onSurfaceVariant: AppColors.textDark,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.cream,
      surfaceContainer: const Color(0xFFF1F0EA),
      surfaceContainerHigh: const Color(0xFFECEBE4),
      outline: AppColors.outline,
      outlineVariant: AppColors.outline,
      error: AppColors.danger,
    );

    final textTheme = AppTextStyles.textTheme();
    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
    final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard));
    OutlineInputBorder field(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusField),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.neutralBackground,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.textDark, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lightGreen,
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          shape: pill,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: textTheme.labelLarge,
          shape: pill,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: field(AppColors.outline),
        enabledBorder: field(AppColors.outline),
        focusedBorder: field(AppColors.primaryGreen, 2),
        errorBorder: field(AppColors.danger),
        focusedErrorBorder: field(AppColors.danger, 2),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryGreen,
        secondarySelectedColor: AppColors.paleGreen,
        disabledColor: AppColors.outline,
        side: const BorderSide(color: AppColors.outline),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textDark),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        checkmarkColor: Colors.white,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusChip)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: AppColors.primaryGreen,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusChip)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.paleGreen,
        elevation: 0,
        height: 68,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryGreen
                : AppColors.textMuted,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.paleGreen,
        selectedIconTheme: IconThemeData(color: AppColors.primaryGreen),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryGreen,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        iconColor: AppColors.primaryGreen,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 15),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusField)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primaryGreen : AppColors.outline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryGreen,
        linearTrackColor: AppColors.paleGreen,
        circularTrackColor: AppColors.paleGreen,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textBlack,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusField)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: cardShape,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusField)),
          ),
        ),
      ),
    );
  }
}
