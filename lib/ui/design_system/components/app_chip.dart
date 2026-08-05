// lib/ui/design_system/components/app_chip.dart

import 'package:flutter/material.dart';
import '../../../app/theme/app_design_tokens.dart';
import '../../../app/theme/app_colors.dart';

/// A pill‑shaped chip used for tags, budget categories, etc.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppChip({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.primary : AppColors.card;
    final textColor = selected ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadow.outer,
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
