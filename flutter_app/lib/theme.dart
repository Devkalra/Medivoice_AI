import 'package:flutter/material.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
// Medical-grade calm: deep teal primary, soft mint accents, warm whites
// Inspired by Indian pharmacy aesthetics with a modern digital health feel

class AppColors {
  // Primary — deep medical teal (trustworthy, clinical, calming)
  static const Color primary = Color(0xFF0F5E6B);
  static const Color primaryLight = Color(0xFF1A8A9E);
  static const Color primaryDark = Color(0xFF083D48);

  // Accent — warm saffron (Indian identity, warmth, energy)
  static const Color accent = Color(0xFFE8870A);
  static const Color accentLight = Color(0xFFFFA940);

  // Success / Positive
  static const Color success = Color(0xFF2E7D5E);
  static const Color successLight = Color(0xFFE8F5EE);

  // Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Backgrounds
  static const Color bgPrimary = Color(0xFFF8FAFB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgMuted = Color(0xFFEFF6F8);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF4A6572);
  static const Color textMuted = Color(0xFF8FA3AD);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Medication card accent colors (one per card slot, cycling)
  static const List<Color> cardAccents = [
    Color(0xFF0F5E6B), // teal
    Color(0xFF6B3FA0), // purple
    Color(0xFF1B6B3A), // forest green
    Color(0xFFB84D00), // burnt orange
    Color(0xFF1A4E8A), // cobalt blue
    Color(0xFF7B2D6B), // plum
  ];

  static const List<Color> cardAccentLights = [
    Color(0xFFE0F4F7),
    Color(0xFFF0E8FF),
    Color(0xFFE5F5EC),
    Color(0xFFFFF0E5),
    Color(0xFFE5EEFF),
    Color(0xFFFBE8F8),
  ];
}

// ─── Gradient Definitions ─────────────────────────────────────────────────────
class AppGradients {
  static const LinearGradient primaryHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F5E6B), Color(0xFF1A8A9E)],
  );

  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF083D48), Color(0xFF0F5E6B), Color(0xFF1A8A9E)],
  );

  static const LinearGradient accentButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE8870A), Color(0xFFFFA940)],
  );
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      background: AppColors.bgPrimary,
      surface: AppColors.bgCard,
    ),
    scaffoldBackgroundColor: AppColors.bgPrimary,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.headlineLarge,
      foregroundColor: AppColors.textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}
