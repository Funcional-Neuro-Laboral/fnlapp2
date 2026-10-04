import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema único de la app: tipografía, botones, campos y avisos.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDeep,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.error,
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w800, letterSpacing: -0.6),
      headlineMedium: TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: TextStyle(fontSize: 26, height: 32 / 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w800),
      titleSmall: TextStyle(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700),
    );

    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(64, 52),
          elevation: 0,
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: pill,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 16, fontWeight: FontWeight.w400),
        prefixIconColor: AppColors.inkTertiary,
        suffixIconColor: AppColors.inkSecondary,
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppColors.inkTertiary, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFC9C4D6),
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        actionTextColor: const Color(0xFFCBBEFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, height: 22 / 15, color: AppColors.inkSecondary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    );
  }
}
