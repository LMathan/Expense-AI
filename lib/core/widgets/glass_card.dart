import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderOpacity;
  final double bgOpacity;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;
  final BoxBorder? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.borderOpacity = 0.15,
    this.bgOpacity = 0.1,
    this.padding = const EdgeInsets.all(20.0),
    this.gradientColors,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      // Light mode: clean white card with subtle shadow
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: customBorder ??
              Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: gradientColors != null
              ? LinearGradient(
                  colors: gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: child,
      );
    }

    // Dark mode: sleek dark card style (buttery smooth scrolling without BackdropFilter blur)
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: customBorder ??
            Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                AppColors.cardDark.withValues(alpha: bgOpacity + 0.65),
                AppColors.bgDark.withValues(alpha: bgOpacity + 0.75),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
