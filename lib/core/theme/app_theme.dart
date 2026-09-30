import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        primary: AppPalette.primary,
        surface: AppPalette.cardBackground,
        error: AppPalette.error,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w400,
        ),
        border: _border(AppPalette.inputBorder),
        enabledBorder: _border(AppPalette.inputBorder),
        focusedBorder: _border(AppPalette.primary, width: 1.5),
        errorBorder: _border(AppPalette.error),
        focusedErrorBorder: _border(AppPalette.error),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static ThemeData get light => lightTheme;
  static ThemeData get dark => lightTheme;
}
