import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

class ThemeTransitionState {
  final ui.Image? screenshot;
  final Offset centerOffset;

  ThemeTransitionState({
    this.screenshot,
    this.centerOffset = Offset.zero,
  });
}

class ThemeTransitionNotifier extends StateNotifier<ThemeTransitionState> {
  ThemeTransitionNotifier() : super(ThemeTransitionState());

  void startTransition(ui.Image image, Offset offset) {
    state = ThemeTransitionState(screenshot: image, centerOffset: offset);
  }

  void clearTransition() {
    state = ThemeTransitionState();
  }
}

final themeTransitionProvider =
    StateNotifierProvider<ThemeTransitionNotifier, ThemeTransitionState>((ref) {
  return ThemeTransitionNotifier();
});

class ThemeTransition {
  static final GlobalKey repaintKey = GlobalKey();

  static Future<void> toggle(BuildContext context, WidgetRef ref) async {
    Offset tapOffset = const Offset(0, 0);
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final size = box.size;
        tapOffset = box.localToGlobal(Offset(size.width / 2, size.height / 2));
      }
    } catch (e) {
      debugPrint('Error getting button position: $e');
    }

    try {
      final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        // Capture screenshot at 1.0 pixel ratio for maximum performance and low memory consumption.
        // On modern devices with high devicePixelRatio (e.g. 3.0), capturing at default pixel ratio
        // creates massive images (e.g. 20M+ pixels) which blocks the UI thread and stutters the animation.
        final image = await boundary.toImage(pixelRatio: 1.0);
        ref.read(themeTransitionProvider.notifier).startTransition(image, tapOffset);
      }
    } catch (e) {
      debugPrint('Error capturing theme transition: $e');
    }

    ref.read(themeProvider.notifier).toggleTheme();
  }
}

class ThemeTransitionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ThemeTransitionOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ThemeTransitionOverlay> createState() => _ThemeTransitionOverlayState();
}

class _ThemeTransitionOverlayState extends ConsumerState<ThemeTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450), // Snappy and smooth transition duration
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(themeTransitionProvider.notifier).clearTransition();
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transitionState = ref.watch(themeTransitionProvider);
    final screenshot = transitionState.screenshot;

    if (screenshot != null && _controller.status == AnimationStatus.dismissed) {
      _controller.forward(from: 0.0);
    }

    final mainContent = RepaintBoundary(
      key: ThemeTransition.repaintKey,
      child: widget.child,
    );

    if (screenshot == null) {
      return mainContent;
    }

    return Stack(
      children: [
        // Old theme screenshot rendered static at the bottom
        Positioned.fill(
          child: RawImage(
            image: screenshot,
            fit: BoxFit.cover,
          ),
        ),
        // New theme screen rendered on top, clipped by an expanding circle.
        // By putting the new theme on top and using a simple expanding circle,
        // we completely avoid expensive CPU/GPU boolean path combinations (Path.combine/difference),
        // delivering a buttery smooth, 60/120 FPS hardware-accelerated transition.
        Positioned.fill(
          child: AbsorbPointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipPath(
                  clipper: SimpleCircularRevealClipper(
                    progress: _controller.value,
                    center: transitionState.centerOffset,
                  ),
                  child: mainContent,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class SimpleCircularRevealClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;

  SimpleCircularRevealClipper({
    required this.progress,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final maxRadius = _calcMaxRadius(size, center);
    final currentRadius = maxRadius * progress;
    path.addOval(Rect.fromCircle(center: center, radius: currentRadius));
    return path;
  }

  double _calcMaxRadius(Size size, Offset center) {
    final d1 = center.distance;
    final d2 = (Offset(size.width, 0) - center).distance;
    final d3 = (Offset(0, size.height) - center).distance;
    final d4 = (Offset(size.width, size.height) - center).distance;
    return [d1, d2, d3, d4].reduce((a, b) => a > b ? a : b);
  }

  @override
  bool shouldReclip(covariant SimpleCircularRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}
