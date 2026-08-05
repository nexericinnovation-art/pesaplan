// lib/ui/design_system/components/app_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_design_tokens.dart';
import '../../../app/theme/app_colors.dart';

/// A reusable rounded button that follows the claymorphism design.
class AppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.isPrimary = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final background = isPrimary ? AppColors.primary : AppColors.accent;
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: AppElevation.low,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        animationDuration: AppDuration.button,
      ),
      child: child,
    );
  }
}
