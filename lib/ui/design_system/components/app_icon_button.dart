// lib/ui/design_system/components/app_icon_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_design_tokens.dart';
import '../../../app/theme/app_colors.dart';

/// A circular icon button that follows the claymorphism style.
/// Uses Material Symbols Rounded icons (e.g., Icons.home_rounded).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final double size;

  const AppIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.size = 56.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? AppColors.primary : AppColors.card;
    final iconColor = isActive ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: AppShadow.outer,
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
