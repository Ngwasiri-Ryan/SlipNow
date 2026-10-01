import 'package:flutter/material.dart';

/// Brand palettes selectable from the hidden theme panel (triple-tap the
/// splash logo).
enum BrandTheme {
  forest(
    primary: Color(0xFF1B4D3E),
    primaryDark: Color(0xFF123529),
    primarySoft: Color(0xFFE6F0EC),
    darkPrimary: Color(0xFF2E9E6B),
    darkPrimarySoft: Color(0xFF1B2F28),
  ),
  navy(
    primary: Color(0xFF1E3A5F),
    primaryDark: Color(0xFF152A47),
    primarySoft: Color(0xFFE4EBF3),
    darkPrimary: Color(0xFF4A7FC1),
    darkPrimarySoft: Color(0xFF1A2533),
  ),
  teal(
    primary: Color(0xFF0F5F5C),
    primaryDark: Color(0xFF083F3E),
    primarySoft: Color(0xFFE0F0EF),
    darkPrimary: Color(0xFF1FA39E),
    darkPrimarySoft: Color(0xFF132E2D),
  ),
  plum(
    primary: Color(0xFF6B2E5F),
    primaryDark: Color(0xFF4A1F42),
    primarySoft: Color(0xFFF0E4EE),
    darkPrimary: Color(0xFFB0579F),
    darkPrimarySoft: Color(0xFF2E1B2B),
  );

  const BrandTheme({
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.darkPrimary,
    required this.darkPrimarySoft,
  });

  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color darkPrimary;
  final Color darkPrimarySoft;
}

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySoft,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text,
    required this.text2,
    required this.text3,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warn,
    required this.warnSoft,
  });

  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySoft;
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color onAccentSoft;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text;
  final Color text2;
  final Color text3;
  final Color border;
  final Color borderStrong;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color warn;
  final Color warnSoft;

  static const onAccent = Color(0xFF2A1D00);
  static const whatsapp = Color(0xFF25D366);
  static const heroEnd = Color(0xFF14382C);

  factory AppColors.light(BrandTheme t) => AppColors(
    isDark: false,
    primary: t.primary,
    primaryDark: t.primaryDark,
    primaryLight: const Color(0xFF2E9E6B),
    primarySoft: t.primarySoft,
    accent: const Color(0xFFF2A93B),
    accentDark: const Color(0xFFD68F1F),
    accentSoft: const Color(0xFFFDF3E1),
    onAccentSoft: const Color(0xFF8A6A20),
    bg: const Color(0xFFF7F9F8),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFFAFCFB),
    text: const Color(0xFF0F1F1A),
    text2: const Color(0xFF4A5C55),
    text3: const Color(0xFF6F807A),
    border: const Color(0xFFDAE3DF),
    borderStrong: const Color(0xFFC4D0CB),
    success: const Color(0xFF2E9E6B),
    successSoft: const Color(0xFFE3F5EC),
    danger: const Color(0xFFC94A46),
    dangerSoft: const Color(0xFFFDECEC),
    warn: const Color(0xFFC78A1F),
    warnSoft: const Color(0xFFFBF3E1),
  );

  factory AppColors.dark(BrandTheme t) => AppColors(
    isDark: true,
    primary: t.darkPrimary,
    primaryDark: t.primary,
    primaryLight: const Color(0xFF4CB885),
    primarySoft: t.darkPrimarySoft,
    accent: const Color(0xFFF2A93B),
    accentDark: const Color(0xFFD68F1F),
    accentSoft: const Color(0xFF2A2418),
    onAccentSoft: const Color(0xFFF0D9A8),
    bg: const Color(0xFF0B1412),
    surface: const Color(0xFF15231E),
    surface2: const Color(0xFF1B2C26),
    text: const Color(0xFFF0F6F3),
    text2: const Color(0xFFB8C6C0),
    text3: const Color(0xFF8A9A94),
    border: const Color(0xFF2A3D36),
    borderStrong: const Color(0xFF3D5249),
    success: const Color(0xFF4CB885),
    successSoft: const Color(0xFF1A3A2C),
    danger: const Color(0xFFE57570),
    dangerSoft: const Color(0xFF3A1F1E),
    warn: const Color(0xFFE5B44C),
    warnSoft: const Color(0xFF3A2E1A),
  );

  List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.14),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: l(primary, other.primary),
      primaryDark: l(primaryDark, other.primaryDark),
      primaryLight: l(primaryLight, other.primaryLight),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      accentDark: l(accentDark, other.accentDark),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccentSoft: l(onAccentSoft, other.onAccentSoft),
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surface2: l(surface2, other.surface2),
      text: l(text, other.text),
      text2: l(text2, other.text2),
      text3: l(text3, other.text3),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      warn: l(warn, other.warn),
      warnSoft: l(warnSoft, other.warnSoft),
    );
  }
}

/// Fixed colours used for grade chips, bars and the printed slip.
class GradeColors {
  static Color of(String grade) => switch (grade.toUpperCase()) {
    'A' => const Color(0xFF2E9E6B),
    'B' => const Color(0xFF1B4D3E),
    'C' => const Color(0xFFC78A1F),
    'D' => const Color(0xFFD68F1F),
    'E' => const Color(0xFFB5651D),
    'F' => const Color(0xFFC94A46),
    _ => const Color(0xFF1B4D3E),
  };
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
