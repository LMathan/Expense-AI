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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: customBorder ??
                  Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(borderOpacity),
                    width: 1.2,
                  ),
              gradient: LinearGradient(
                colors: gradientColors ??
                    (isDark
                        ? [
                            Colors.white.withOpacity(bgOpacity),
                            Colors.white.withOpacity(bgOpacity * 0.3),
                          ]
                        : [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.4),
                          ]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
