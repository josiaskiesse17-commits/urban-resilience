import 'package:flutter/material.dart';

import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppPalette.primary,
        secondary: AppPalette.accent,
        surface: AppPalette.lightSurface,
      ),

      scaffoldBackgroundColor: AppPalette.lightBackground,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppPalette.lightSurface,
        foregroundColor: AppPalette.lightText,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppPalette.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppPalette.lightBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.primary,
            width: 2,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppPalette.lightSurface,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primaryLight,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppPalette.primaryLight,
        secondary: AppPalette.accent,
        surface: AppPalette.darkSurface,
      ),

      scaffoldBackgroundColor: AppPalette.darkBackground,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppPalette.darkSurface,
        foregroundColor: AppPalette.darkText,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppPalette.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppPalette.darkBorder,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.darkBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.darkBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.primaryLight,
            width: 2,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppPalette.darkSurface,
      ),
    );
  }
}
