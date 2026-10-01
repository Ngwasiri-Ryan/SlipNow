import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 100.0;
}

class AppTheme {
  static ThemeData build({required bool dark, required BrandTheme brand}) {
    final c = dark ? AppColors.dark(brand) : AppColors.light(brand);
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: c.primary,
        secondary: c.accent,
        surface: c.surface,
        error: c.danger,
      ),
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: c.text, displayColor: c.text);

    return base.copyWith(
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.surface),
    );
  }

  static TextStyle brand({double size = 18, Color? color}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: color);

  static TextStyle mono({double size = 28, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: 2, color: color);
}
