import 'package:flutter/material.dart';

class AppTheme {
  static const primaryPurple = Color(0xFF6C5CE7);
  static const primaryBlue = Color(0xFF0984E3);
  static const gradientStart = Color(0xFF6C5CE7);
  static const gradientEnd = Color(0xFF0984E3);
  static const darkBg = Color(0xFF1A1A2E);
  static const cardBg = Color(0xFF16213E);
  static const cardBgLight = Color(0xFF1E2A47);
  static const surfaceDark = Color(0xFF0F3460);
  static const accentGold = Color(0xFFFFD93D);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0C0);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDAA5B);
  static const danger = Color(0xFFE17055);

  static final gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: primaryPurple,
        colorScheme: const ColorScheme.dark(
          primary: primaryPurple,
          secondary: primaryBlue,
          surface: cardBg,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardBgLight,
          selectedColor: primaryPurple,
          labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkBg,
          selectedItemColor: primaryPurple,
          unselectedItemColor: textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBgLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryPurple),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        dividerColor: cardBgLight,
      );
}
