// lib/ui/design_system/components/app_card.dart

import 'package:flutter/material.dart';
import '../../../app/theme/app_design_tokens.dart';


/// A reusable card widget that applies the claymorphism style.
///
/// This widget uses the [AppRadius.lg] for corner radius and combines an
/// outer shadow with an inner inset shadow to give the "soft lifted" effect.
class AppCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    Key? key,
    required this.child,
    this.elevation,
    this.color,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Theme.of(context).cardColor;
    // final double elevationValue = elevation ?? AppElevation.medium; // Unused variable removed
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      padding: padding ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          // Outer soft shadow
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            offset: const Offset(0, 12),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0.85),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
