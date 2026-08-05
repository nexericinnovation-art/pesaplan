// lib/app/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_design_tokens.dart';

class AppTheme {
  static final ThemeData lightClayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.background,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    cardColor: AppColors.card,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'SF Pro Display',
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: AppElevation.medium,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        animationDuration: AppDuration.button,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide.none,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTokensExtension()
    ],
  );

  static final ThemeData darkClayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.accentDark,
      surface: AppColors.cardDark,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    canvasColor: AppColors.backgroundDark,
    cardColor: AppColors.cardDark,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'SF Pro Display',
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: Colors.white70,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: AppElevation.medium,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF222222),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide.none,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppTokensExtension()
    ],
  );
}

// Optional ThemeExtension to expose design tokens via Theme.of(context).extension<AppTokensExtension>()
class AppTokensExtension extends ThemeExtension<AppTokensExtension> {
  @override
  AppTokensExtension copyWith() => this;

  @override
  AppTokensExtension lerp(ThemeExtension<AppTokensExtension>? other, double t) => this;
}
