import 'package:flutter/material.dart';

class AppTheme {
  // === 能道再生 Brand Colors (from PDF brochure) ===
  static const brandDarkRed = Color(0xFF8B0000);      // 深红标题栏
  static const brandGold = Color(0xFFB8860B);          // 金色分隔/强调
  static const brandGoldLight = Color(0xFFD4A843);     // 浅金色
  static const brandSwissRed = Color(0xFFD32F2F);      // 瑞士红
  static const brandWhite = Color(0xFFFAFAFA);         // 白底

  // === Primary Colors (blended brand) ===
  static const primaryPurple = Color(0xFF6C5CE7);
  static const primaryBlue = Color(0xFF0984E3);
  static const gradientStart = Color(0xFF8B0000);      // brand dark red
  static const gradientEnd = Color(0xFFB8860B);        // brand gold

  // === Background (dark mode - brand aligned) ===
  static const darkBg = Color(0xFF1A1118);             // 略带暖红的深色
  static const cardBg = Color(0xFF221820);             // 暖色调卡片
  static const cardBgLight = Color(0xFF2D2228);        // 浅卡片
  static const surfaceDark = Color(0xFF3A1A2E);        // 表面色

  // === Accent ===
  static const accentGold = Color(0xFFD4A843);         // 品牌金
  static const textPrimary = Color(0xFFF5F0F0);        // 温暖白文本
  static const textSecondary = Color(0xFFB0A8B0);      // 柔和次要文本

  // === Status Colors ===
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDAA5B);
  static const danger = Color(0xFFE17055);

  // === Brand Gradient (能道再生) ===
  static final gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Premium Gold Gradient ===
  static final goldGradient = LinearGradient(
    colors: [brandGold, brandGoldLight, brandGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Swiss Red Gradient ===
  static final redGradient = LinearGradient(
    colors: [brandDarkRed, brandSwissRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: brandDarkRed,
        colorScheme: const ColorScheme.dark(
          primary: brandDarkRed,
          secondary: brandGold,
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
          selectedColor: brandDarkRed,
          labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
          secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandDarkRed,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkBg,
          selectedItemColor: brandGold,
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
            borderSide: const BorderSide(color: brandGold, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: brandGold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandDarkRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        dividerColor: cardBgLight,
        tabBarTheme: TabBarThemeData(
          indicatorColor: brandGold,
          labelColor: Colors.white,
          unselectedLabelColor: textSecondary,
          dividerColor: Colors.transparent,
        ),
      );
}
