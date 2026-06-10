import 'package:flutter/material.dart';

enum RouteTransitionType { slideUp, slideRight, fade, scale }

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    RouteTransitionType type = RouteTransitionType.slideUp,
    Duration duration = const Duration(milliseconds: 320),
  }) : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: duration,
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondary, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            switch (type) {
              case RouteTransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(curve),
                  child: FadeTransition(opacity: animation, child: child),
                );
              case RouteTransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(curve),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.6, end: 1.0).animate(curve),
                    child: child,
                  ),
                );
              case RouteTransitionType.fade:
                return FadeTransition(opacity: animation, child: child);
              case RouteTransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
                  child: FadeTransition(opacity: animation, child: child),
                );
            }
          },
        );
}
