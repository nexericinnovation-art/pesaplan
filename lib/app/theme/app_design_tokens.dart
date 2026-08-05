// lib/app/theme/app_design_tokens.dart

import 'package:flutter/material.dart';

/// Design tokens for the PesaPlan app
class AppRadius {
  static const double xs = 12.0;
  static const double sm = 18.0;
  static const double md = 22.0;
  static const double lg = 28.0;
}

class AppElevation {
  static const double low = 2.0;
  static const double medium = 6.0;
  static const double high = 12.0;
}

class AppShadow {
  static const List<BoxShadow> outer = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 12),
      blurRadius: 30,
    ),
  ];
  static const List<BoxShadow> inner = [
    BoxShadow(
      color: Color.fromRGBO(255, 255, 255, 0.85),
      offset: Offset(0, 3),
      blurRadius: 10,
    ),
  ];
  // Inset shadows are not supported by Flutter's BoxShadow. Use a custom painter if needed.
}

class AppDuration {
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration cardHover = Duration(milliseconds: 150);
  static const Duration fab = Duration(milliseconds: 250);
  static const Duration chart = Duration(milliseconds: 700);
  static const Duration progressRing = Duration(milliseconds: 900);
  static const Duration button = Duration(milliseconds: 120);
}

class AppAnimation {
  static const Curve defaultCurve = Curves.easeOutCubic;
}

class AppBlur {
  static const double light = 4.0;
  static const double medium = 8.0;
}

class AppOpacity {
  static const double disabled = 0.38;
  static const double hint = 0.6;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
}

class AppGradient {
  static const Gradient purpleClay = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient softHighlight = LinearGradient(
    colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Gradient skeleton = LinearGradient(
    colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
