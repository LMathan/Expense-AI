import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/features/auth/presentation/providers/auth_provider.dart';
import 'package:espenseai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:espenseai/core/widgets/vector_illustrations.dart';

class DataSyncScreen extends ConsumerStatefulWidget {
  const DataSyncScreen({super.key});

  @override
  ConsumerState<DataSyncScreen> createState() => _DataSyncScreenState();
}

class _DataSyncScreenState extends ConsumerState<DataSyncScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;
  late final List<AnimationController> _barControllers;
  late final List<Animation<double>> _barAnims;

  Timer? _statusTimer;
  int _statusIndex = 0;
  bool _navigated = false;

  static const List<String> _statusMessages = [
    'Verifying your account...',
    'Fetching your expenses...',
    'Loading your budgets...',
    'Syncing group data...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1350))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    const durations = [310, 430, 365, 500];
    _barControllers = durations
        .map((ms) =>
            AnimationController(vsync: this, duration: Duration(milliseconds: ms)))
        .toList();
    _barAnims = _barControllers
        .map((c) => Tween<double>(begin: 8.0, end: 48.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    for (int i = 0; i < _barControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 90), () {
        if (mounted) _barControllers[i].repeat(reverse: true);
      });
    }

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1650), (_) {
      if (mounted) {
        setState(() =>
            _statusIndex = (_statusIndex + 1) % _statusMessages.length);
      }
    });

    // Race-condition guard: already authenticated before this screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        _goToDashboard();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    for (final c in _barControllers) {
      c.dispose();
    }
    _statusTimer?.cancel();
    super.dispose();
  }

  void _goToDashboard() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionDuration: const Duration(milliseconds: 650),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) _goToDashboard();
    });

    final barColors = [
      AppColors.primaryPurple,
      AppColors.electricBlue,
      AppColors.emeraldGreen,
      AppColors.accentOrange,
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: AppBackground(
        type: PageBg.auth,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ─── Logo with pulsing glow ───────────────────────────
                Center(
                  child: SizedBox(
                    width: 148,
                    height: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryPurple
                                        .withValues(alpha: 0.20),
                                    AppColors.electricBlue
                                        .withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.25, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Inner card / glow base
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.cardDark : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple
                                    .withValues(alpha: 0.32),
                                blurRadius: 28,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        // App logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 70,
                            width: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ─── App name ─────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.electricBlue,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'ExpenseMate',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // ─── Equalizer bars ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedBuilder(
                        animation: _barAnims[i],
                        builder: (_, __) => Container(
                          width: 11,
                          height: _barAnims[i].value,
                          decoration: BoxDecoration(
                            color: barColors[i],
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: barColors[i].withValues(alpha: 0.50),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 38),

                // ─── Animated status text ─────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _statusMessages[_statusIndex],
                    key: ValueKey(_statusIndex),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: subColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ─── Bottom shimmer line + label ──────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      // Animated shimmer progress bar
                      SizedBox(
                        width: 140,
                        height: 4,
                        child: AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (_, __) => DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [
                                  (_shimmerAnim.value - 0.4).clamp(0.0, 1.0),
                                  _shimmerAnim.value.clamp(0.0, 1.0),
                                  (_shimmerAnim.value + 0.4).clamp(0.0, 1.0),
                                ],
                                colors: const [
                                  AppColors.primaryPurple,
                                  AppColors.electricBlue,
                                  AppColors.emeraldGreen,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Syncing your financial data',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: subColor.withValues(alpha: 0.50),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
