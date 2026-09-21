import 'package:flutter/material.dart';

/// Brand colors — tailored to Pwestora's midnight navy and electric blue theme.
class AppColors {
  // Midnight Navy Palette
  static const primary = Color(0xFF0A1832);
  static const primaryLight = Color(0xFF183868);
  static const primaryLighter = Color(0xFF264C87);
  static const navyDark = Color(0xFF070F1E);
  static const navySurface = Color(0xFF0F1E36);
  static const navyCard = Color(0xFF11223F);
  static const navyBorder = Color(0xFF1E3A5F);

  // Vibrant & Electric Accents
  static const electricBlue = Color(0xFF1E6BFF);
  static const electricBlueDark = Color(0xFF0D47A1);
  static const cyanGlow = Color(0xFF00E5FF);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEAF1FC);
  static const tint = Color(0xFFD6E3F5);
  static const steel = Color(0xFF888F96);

  // Event & Tag Palette
  static const tagRent = Color(0xFF1E6BFF);
  static const tagMaintenance = Color(0xFFFF7A00);
  static const tagBuilding = Color(0xFF8B5CF6);
  static const tagOther = Color(0xFF64748B);

  // Functional Status
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0xFFFEE2E2);

  // Neutrals & Surfaces
  static const ink900 = Color(0xFF0F172A);
  static const ink700 = Color(0xFF334155);
  static const ink500 = Color(0xFF64748B);
  static const ink400 = Color(0xFF94A3B8);
  static const ink300 = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F7FB);
}

/// Custom App Shadows & BoxStyles
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
      border: border ?? Border.all(color: AppColors.border.withValues(alpha: 0.85), width: 1),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: const Color(0xFF0A1832).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF0A1832).withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration navyCard({
    double radius = 22,
    bool glow = true,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0C1B38), Color(0xFF081429)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.7), width: 1.2),
      boxShadow: glow
          ? [
              BoxShadow(
                color: const Color(0xFF1E6BFF).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
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

  static BoxDecoration glowButton({
    double radius = 18,
    List<Color>? colors,
    bool glow = true,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? const [Color(0xFF132B54), Color(0xFF09162C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF2E5F9E).withValues(alpha: 0.5), width: 1),
      boxShadow: glow
          ? [
              BoxShadow(
                color: const Color(0xFF1E6BFF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFF0A1832).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration electricGlowButton({
    double radius = 999,
  }) {
    return BoxDecoration(
      shape: radius >= 999 ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: radius < 999 ? BorderRadius.circular(radius) : null,
      gradient: const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF0B214D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.6), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E6BFF).withValues(alpha: 0.6),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
          blurRadius: 26,
          spreadRadius: 1,
        ),
      ],
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
      secondary: AppColors.electricBlue,
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
      hintStyle: const TextStyle(color: AppColors.ink400, fontSize: 14),
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
        borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.85)),
      ),
    ),
    fontFamily: 'Roboto',
  );
}

/// Official Pwestora Back Button design
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDark;
  final Color? customColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isDark = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : (customColor != null
                  ? customColor!.withValues(alpha: 0.1)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 14,
          color: isDark
              ? Colors.white
              : (customColor ?? const Color(0xFF0F172A)),
        ),
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
