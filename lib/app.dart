import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/theme_transition.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

class ExpenseMateApp extends ConsumerWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'ExpenseMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return ThemeTransitionOverlay(child: child!);
      },
      home: const SplashScreen(),
    );
  }
}

