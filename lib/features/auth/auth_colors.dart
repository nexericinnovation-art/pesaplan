import 'package:flutter/material.dart';

/// Blue palette for the auth screens (sign in, sign up, verification,
/// password reset, and the Clerk loading overlay). Scoped deliberately —
/// this does NOT change AppColors.primary or anything else in the rest of
/// the app, since that's a bigger, separate decision.
///
/// These hex values are a visual estimate from a design mockup image, not
/// pixel-extracted — treat them as a strong first pass, not a guaranteed
/// exact match.
class AuthColors {
  static const headerTop = Color(0xFFDCE8FB);
  static const headerBottom = Color(0xFFB9D3F7);
  static const primary = Color(0xFF4F7DF3);
  static const primaryDark = Color(0xFF3D63D6);
  static const textDark = Color(0xFF16233F);
  static const textMuted = Color(0xFF5B6B8C);
}
