import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espenseai/core/constants/colors.dart';
import 'package:espenseai/core/constants/text_styles.dart';
import 'package:espenseai/features/auth/presentation/providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'package:espenseai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _controller.forward();
    _checkRedirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkRedirect() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated || authState.status == AuthStatus.guest) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          gradient: LinearGradient(
            colors: [AppColors.bgDark, Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'ExpenseAI',
                style: AppTextStyles.heading1(isDark: true).copyWith(
                  letterSpacing: 1.5,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI-Powered Smart Wealth Management',
                style: AppTextStyles.bodyMedium(isDark: true).copyWith(
                  color: AppColors.textSecondaryDark.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
