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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
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

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF102A31),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        brightness: Brightness.dark,
        primary: const Color(0xFF70D7D0),
        surface: const Color(0xFF19383F),
        error: const Color(0xFFFF8A80),
      ),
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.interTextTheme(base.primaryTextTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF19383F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: _border(const Color(0xFF4E6B70)),
        enabledBorder: _border(const Color(0xFF4E6B70)),
        focusedBorder: _border(const Color(0xFF70D7D0), width: 1.5),
        errorBorder: _border(const Color(0xFFFF8A80)),
        focusedErrorBorder: _border(const Color(0xFFFF8A80)),
      ),
    );
  }
}
