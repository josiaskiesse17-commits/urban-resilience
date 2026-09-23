import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  // Brand
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);

  // Accent
  static const accent = Color(0xFF00A896);

  // Semantic risk colors
  static const riskLow = Color(0xFF2E7D32);
  static const riskMedium = Color(0xFFF9A825);
  static const riskHigh = Color(0xFFEF6C00);
  static const riskCritical = Color(0xFFC62828);

  // Light theme
  static const lightBackground = Color(0xFFF7F9FC);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF172033);
  static const lightSecondaryText = Color(0xFF667085);
  static const lightBorder = Color(0xFFE4E7EC);

  // Dark theme
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkText = Color(0xFFF2F4F7);
  static const darkSecondaryText = Color(0xFF98A2B3);
  static const darkBorder = Color(0xFF273244);
}
