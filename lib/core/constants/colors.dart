import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color electricBlue = Color(0xFF4A90E2);
  static const Color emeraldGreen = Color(0xFF00C896);

  // Accent colors
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentPink = Color(0xFFFF6B9D);

  // Backgrounds
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);

  // Card Backgrounds (Glassmorphic basis)
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [emeraldGreen, Color(0xFF05B386)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFFF851B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [accentPink, Color(0xFFE040FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x0AFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
}
