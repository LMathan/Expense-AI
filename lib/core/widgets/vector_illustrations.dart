import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:espenseai/core/constants/colors.dart';

// ─── Animated Finance Hero Illustration ─────────────────────────────────────

class AnimatedFinanceIllustration extends StatefulWidget {
  final double size;
  const AnimatedFinanceIllustration({super.key, this.size = 180});

  @override
  State<AnimatedFinanceIllustration> createState() =>
      _AnimatedFinanceIllustrationState();
}

class _AnimatedFinanceIllustrationState
    extends State<AnimatedFinanceIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -_float.value),
        child: Transform.rotate(
          angle: _rotate.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _FinancePainter(),
          ),
        ),
      ),
    );
  }
}

class _FinancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Background circle glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryPurple.withValues(alpha: 0.18),
          AppColors.electricBlue.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.48));
    canvas.drawCircle(Offset(cx, cy), w * 0.48, glowPaint);

    // Coin stack base
    _drawCoin(canvas, Offset(cx - 14, cy + 24), 36, AppColors.accentOrange, 0.9);
    _drawCoin(canvas, Offset(cx, cy + 16), 36, AppColors.electricBlue, 0.95);
    _drawCoin(canvas, Offset(cx + 14, cy + 8), 36, AppColors.primaryPurple, 1.0);

    // Rising bars (bar chart)
    _drawBar(canvas, Offset(cx - 36, cy - 8), 18, 28, AppColors.electricBlue);
    _drawBar(canvas, Offset(cx - 16, cy - 8), 18, 44, AppColors.primaryPurple);
    _drawBar(canvas, Offset(cx + 4, cy - 8), 18, 36, AppColors.emeraldGreen);
    _drawBar(canvas, Offset(cx + 24, cy - 8), 18, 56, AppColors.accentOrange);

    // Trend arrow
    final arrowPaint = Paint()
      ..color = AppColors.emeraldGreen
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arrowPath = Path()
      ..moveTo(cx - 38, cy - 38)
      ..quadraticBezierTo(cx, cy - 60, cx + 38, cy - 42);
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrow head
    final ahPaint = Paint()
      ..color = AppColors.emeraldGreen
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx + 38, cy - 42), Offset(cx + 28, cy - 40), ahPaint);
    canvas.drawLine(
        Offset(cx + 38, cy - 42), Offset(cx + 34, cy - 52), ahPaint);

    // Small sparkle stars
    _drawSparkle(canvas, Offset(cx - 40, cy - 52), 5, AppColors.accentOrange);
    _drawSparkle(canvas, Offset(cx + 44, cy - 18), 4, AppColors.electricBlue);
    _drawSparkle(canvas, Offset(cx + 28, cy - 56), 3.5, AppColors.accentPink);
  }

  void _drawCoin(Canvas canvas, Offset center, double r, Color color,
      double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.9 * opacity),
          color.withValues(alpha: 0.55 * opacity),
        ],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: r / 2));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r.toDouble(), height: r * 0.45),
      paint,
    );
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r.toDouble(), height: r * 0.45),
      strokePaint,
    );
    // ₹ symbol
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8 * opacity),
            fontSize: r * 0.22,
            fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, center - Offset(tp.width / 2, tp.height / 2 - r * 0.01));
  }

  void _drawBar(Canvas canvas, Offset bottomLeft, double width, double height,
      Color color) {
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(bottomLeft.dx, bottomLeft.dy - height, width, height),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.55)],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * r,
            center.dy + math.sin(angle) * r),
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(center, r * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Abstract Wave Background Decoration ────────────────────────────────────

class WaveBackground extends StatelessWidget {
  final Color color;
  final double height;
  const WaveBackground({
    super.key,
    this.color = AppColors.primaryPurple,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              AppColors.electricBlue.withValues(alpha: 0.06),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.82,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.65,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Animated Dots Row ───────────────────────────────────────────────────────

class PulsingDotsRow extends StatefulWidget {
  final int count;
  final Color color;
  final double size;
  const PulsingDotsRow({
    super.key,
    this.count = 3,
    this.color = AppColors.primaryPurple,
    this.size = 8,
  });

  @override
  State<PulsingDotsRow> createState() => _PulsingDotsRowState();
}

class _PulsingDotsRowState extends State<PulsingDotsRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.count, (i) {
            final phase = ((_ctrl.value + i / widget.count) % 1.0);
            final scale = 0.6 + 0.4 * math.sin(phase * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.4 + 0.6 * scale),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Empty State Illustration ────────────────────────────────────────────────

class EmptyStateIllustration extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  const EmptyStateIllustration({
    super.key,
    required this.message,
    this.icon = Icons.receipt_long_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.primaryPurple;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.12),
              ),
            ),
            Icon(icon, size: 40, color: c.withValues(alpha: 0.6)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ─── Staggered Fade-In List ──────────────────────────────────────────────────

class StaggeredListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 60),
  });

  @override
  State<StaggeredListItem> createState() => _StaggeredListItemState();
}

class _StaggeredListItemState extends State<StaggeredListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.baseDelay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Animated Gradient Border ────────────────────────────────────────────────

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderWidth = 1.5,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _ctrl.value,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderWidth;
  final double borderRadius;

  _GradientBorderPainter({
    required this.progress,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          borderWidth / 2, borderWidth / 2,
          size.width - borderWidth,
          size.height - borderWidth),
      Radius.circular(borderRadius),
    );
    final angle = progress * 2 * math.pi;
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: angle,
        endAngle: angle + math.pi * 2,
        colors: const [
          AppColors.primaryPurple,
          AppColors.electricBlue,
          AppColors.accentPink,
          AppColors.primaryPurple,
        ],
        stops: const [0.0, 0.33, 0.66, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.progress != progress;
}

// ─── Page Background Decorator ───────────────────────────────────────────────

enum PageBg { home, analytics, planner, profile, auth, expense, group }

class AppBackground extends StatelessWidget {
  final Widget child;
  final PageBg type;
  const AppBackground({super.key, required this.child, required this.type});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _PageBgPainter(type: type, isDark: isDark),
          ),
        ),
        child,
      ],
    );
  }
}

class _PageBgPainter extends CustomPainter {
  final PageBg type;
  final bool isDark;
  _PageBgPainter({required this.type, required this.isDark});

  double get _alpha => isDark ? 0.07 : 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case PageBg.home:
        _paintHome(canvas, size);
      case PageBg.analytics:
        _paintAnalytics(canvas, size);
      case PageBg.planner:
        _paintPlanner(canvas, size);
      case PageBg.profile:
        _paintProfile(canvas, size);
      case PageBg.auth:
        _paintAuth(canvas, size);
      case PageBg.expense:
        _paintExpense(canvas, size);
      case PageBg.group:
        _paintGroup(canvas, size);
    }
  }

  // Home: scattered dots + flowing curve
  void _paintHome(Canvas canvas, Size size) {
    final curvePaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, size.height * 0.32)
      ..cubicTo(size.width * 0.3, size.height * 0.15, size.width * 0.7,
          size.height * 0.45, size.width, size.height * 0.28);
    canvas.drawPath(path, curvePaint);

    final path2 = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(size.width * 0.25, size.height * 0.52, size.width * 0.6,
          size.height * 0.72, size.width, size.height * 0.58);
    canvas.drawPath(path2,
        curvePaint..color = AppColors.electricBlue.withValues(alpha: _alpha));

    _drawDots(canvas, size, AppColors.accentOrange, seed: 3);
  }

  // Analytics: grid + data circles
  void _paintAnalytics(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.electricBlue.withValues(alpha: _alpha * 0.8)
      ..strokeWidth = 0.8;
    const cols = 8;
    const rows = 12;
    for (int c = 0; c <= cols; c++) {
      final x = c * size.width / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (int r = 0; r <= rows; r++) {
      final y = r * size.height / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final nodePaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: _alpha * 1.4)
      ..style = PaintingStyle.fill;
    const nodes = [
      Offset(0.15, 0.35), Offset(0.35, 0.22), Offset(0.55, 0.41),
      Offset(0.75, 0.18), Offset(0.88, 0.30),
    ];
    for (final n in nodes) {
      canvas.drawCircle(
          Offset(n.dx * size.width, n.dy * size.height), 5, nodePaint);
    }
    final linePath = Path()
      ..moveTo(nodes[0].dx * size.width, nodes[0].dy * size.height);
    for (int i = 1; i < nodes.length; i++) {
      linePath.lineTo(
          nodes[i].dx * size.width, nodes[i].dy * size.height);
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = AppColors.primaryPurple.withValues(alpha: _alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  // Planner: dot grid like calendar
  void _paintPlanner(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: _alpha * 1.2);
    const cols = 7;
    const rows = 9;
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        final x = (c + 0.5) * size.width / cols;
        final y = (r + 0.5) * size.height / rows;
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }
    // highlight a few cells
    final hlPaint = Paint()
      ..color = AppColors.accentOrange.withValues(alpha: _alpha * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    _drawRoundRect(canvas, size, 1, 2, cols, rows, hlPaint);
    _drawRoundRect(canvas, size, 3, 4, cols, rows, hlPaint);
    _drawRoundRect(canvas, size, 5, 1, cols, rows, hlPaint);
  }

  void _drawRoundRect(Canvas canvas, Size size, int c, int r, int cols,
      int rows, Paint p) {
    final x = c * size.width / cols;
    final y = r * size.height / rows;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 4, y + 4, cellW - 8, cellH - 8),
            const Radius.circular(6)),
        p);
  }

  // Profile: concentric rings
  void _paintProfile(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.85, size.height * 0.12);
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        center,
        i * 40.0,
        Paint()
          ..color = AppColors.primaryPurple.withValues(alpha: _alpha * (1.2 - i * 0.18))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    final center2 = Offset(size.width * 0.1, size.height * 0.85);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center2,
        i * 32.0,
        Paint()
          ..color = AppColors.accentPink.withValues(alpha: _alpha * (1.0 - i * 0.25))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  // Auth: sweeping arcs + sparkles
  void _paintAuth(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.9, -size.height * 0.05),
            width: size.width * 1.1,
            height: size.width * 1.1),
        math.pi * 0.5,
        math.pi * 0.6,
        false,
        arcPaint);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.85, -size.height * 0.02),
            width: size.width * 0.7,
            height: size.width * 0.7),
        math.pi * 0.5,
        math.pi * 0.5,
        false,
        arcPaint..color = AppColors.electricBlue.withValues(alpha: _alpha));
    _drawDots(canvas, size, AppColors.accentPink, seed: 7);
  }

  // Expense: coin circles + receipt lines
  void _paintExpense(Canvas canvas, Size size) {
    final coinPaint = Paint()
      ..color = AppColors.accentOrange.withValues(alpha: _alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final pos in [
      const Offset(0.08, 0.1),
      const Offset(0.9, 0.08),
      const Offset(0.92, 0.88),
      const Offset(0.05, 0.9),
    ]) {
      canvas.drawCircle(
          Offset(pos.dx * size.width, pos.dy * size.height), 22, coinPaint);
      canvas.drawCircle(
          Offset(pos.dx * size.width, pos.dy * size.height), 14, coinPaint);
    }
    final linePaint = Paint()
      ..color = AppColors.primaryPurple.withValues(alpha: _alpha * 0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final rx = size.width * 0.75, ry = size.height * 0.35;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
          Offset(rx, ry + i * 14), Offset(rx + 50, ry + i * 14), linePaint);
    }
  }

  // Group: network nodes
  void _paintGroup(Canvas canvas, Size size) {
    final positions = [
      Offset(0.2 * size.width, 0.15 * size.height),
      Offset(0.7 * size.width, 0.1 * size.height),
      Offset(0.85 * size.width, 0.45 * size.height),
      Offset(0.6 * size.width, 0.82 * size.height),
      Offset(0.15 * size.width, 0.75 * size.height),
    ];
    final linePaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: _alpha * 0.7)
      ..strokeWidth = 1.0;
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        canvas.drawLine(positions[i], positions[j], linePaint);
      }
    }
    final nodePaint = Paint()
      ..color = AppColors.emeraldGreen.withValues(alpha: _alpha * 1.6);
    for (final p in positions) {
      canvas.drawCircle(p, 5.5, nodePaint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Color color,
      {int seed = 0, int count = 18}) {
    final rng = math.Random(seed);
    final paint = Paint()
      ..color = color.withValues(alpha: _alpha * 1.2);
    for (int i = 0; i < count; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * size.width,
              rng.nextDouble() * size.height),
          rng.nextDouble() * 3 + 1.5,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PageBgPainter old) =>
      old.type != type || old.isDark != isDark;
}
