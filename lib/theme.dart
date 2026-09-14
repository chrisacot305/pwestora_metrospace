import 'package:flutter/material.dart';

/// Brand colors — original blue palette.
class AppColors {
  static const primary = Color(0xFF102340);
  static const primaryLight = Color(0xFF264875);
  static const primaryLighter = Color(0xFF3B6396);
  static const accent = Color(0xFF678EBC);
  static const accentSoft = Color(0xFFE7EEF6);
  static const tint = Color(0xFFCCD8E4);
  static const steel = Color(0xFF888F96);

  static const success = Color(0xFF1E8E5A);
  static const successSoft = Color(0xFFE5F5EC);
  static const warning = Color(0xFFE8A33D);
  static const warningSoft = Color(0xFFFCF1E0);
  static const error = Color(0xFFD64545);
  static const errorSoft = Color(0xFFFBE9E9);

  static const ink900 = Color(0xFF16181D);
  static const ink700 = Color(0xFF374151);
  static const ink500 = Color(0xFF6B7280);
  static const ink300 = Color(0xFF9AA6B5);
  static const border = Color(0xFFE4E7EC);
  static const borderLight = Color(0xFFF0F2F5);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF6F8FB);
}

/// Custom App Shadows & BoxStyles for the modern Dribbble look
class AppDecorations {
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = 18,
    Border? border,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: const Color(0xFF102340).withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF102340).withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration squircle({
    Color color = AppColors.accentSoft,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration badge({
    required Color bg,
    double radius = 999,
  }) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink900,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink900,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.ink300, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 3,
      indicatorColor: AppColors.accentSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary);
        }
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink500);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 23);
        }
        return const IconThemeData(color: AppColors.ink500, size: 23);
      }),
    ),
    fontFamily: 'Roboto',
  );
}
