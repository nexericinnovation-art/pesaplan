// lib/app/theme/app_text_styles.dart

import 'package:flutter/material.dart';

/// Centralised text style definitions for the app.
class AppTextStyles {
  // Headline Large – used for main titles (e.g., dashboard title).
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'SF Pro Display',
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: Colors.black,
  );

  // Body Large – regular paragraph text.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: Colors.black87,
  );

  // Button – used for button labels.
  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Colors.white,
  );

  // Caption – for secondary information.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: Colors.black54,
  );
}
