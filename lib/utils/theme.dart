import 'package:flutter/material.dart';

/// Investment-bank professional theme
/// No gradients. Flat colors. Clean typography. Maximum readability.
class AppTheme {
  // === Core Palette (Investment Bank) ===
  static const navy      = Color(0xFF0A1628);    // Primary dark
  static const navyLight = Color(0xFF12203A);    // Card background
  static const navyMid   = Color(0xFF1A2D4A);    // Surface / elevated
  static const steel     = Color(0xFF2A3F5F);    // Borders, dividers
  static const slate     = Color(0xFF8899AA);    // Secondary text
  static const silver    = Color(0xFFBBC5D0);    // Tertiary / muted
  static const offWhite  = Color(0xFFF0F2F5);    // Primary text on dark
  static const pureWhite = Color(0xFFFFFFFF);

  // === Accent (restrained gold) ===
  static const gold      = Color(0xFFC5A572);    // Highlight, selected
  static const goldMuted = Color(0xFF8B7355);    // Subtle gold

  // === Status (muted, professional) ===
  static const success = Color(0xFF3D9970);
  static const warning = Color(0xFFD4A017);
  static const danger  = Color(0xFFCC4444);
  static const info    = Color(0xFF4A90D9);

  // === Legacy aliases (so existing code compiles) ===
  static const primaryPurple  = info;
  static const primaryBlue    = info;
  static const brandDarkRed   = Color(0xFF8B2252);
  static const brandGold      = gold;
  static const brandGoldLight = gold;
  static const brandSwissRed  = danger;
  static const brandWhite     = offWhite;
  static const darkBg         = navy;
  static const cardBg         = navyLight;
  static const cardBgLight    = navyMid;
  static const surfaceDark    = steel;
  static const accentGold     = gold;
  static const textPrimary    = offWhite;
  static const textSecondary  = slate;

  // Gradient kept as a flat solid for API compat
  static final gradient = LinearGradient(colors: [navy, navy]);
  static final goldGradient = LinearGradient(colors: [gold, gold]);
  static final redGradient = LinearGradient(colors: [navy, navy]);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    primaryColor: gold,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: info,
      surface: navyLight,
      onSurface: offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: offWhite, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: offWhite),
    ),
    cardTheme: CardThemeData(
      color: navyLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: steel.withValues(alpha: 0.3)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: navyMid,
      selectedColor: gold,
      labelStyle: const TextStyle(color: offWhite, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: navy,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: navy,
      selectedItemColor: gold,
      unselectedItemColor: slate,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: navyMid,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: steel.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: steel.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: gold, width: 1.5)),
      labelStyle: const TextStyle(color: slate),
      hintStyle: const TextStyle(color: slate),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: gold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
      ),
    ),
    dividerColor: steel.withValues(alpha: 0.3),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: gold,
      labelColor: offWhite,
      unselectedLabelColor: slate,
      dividerColor: Colors.transparent,
    ),
  );
}
