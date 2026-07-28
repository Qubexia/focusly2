import 'package:flutter/material.dart';

/// Zakerly palette aligned with Zakerly-style blue identity (#0088FF).
class AppColors {
  AppColors._();

  // Primary brand blue
  static const Color primary = Color(0xFF0088FF);
  static const Color primaryLight = Color(0xFF4DA6FF);
  static const Color primaryDark = Color(0xFF0066CC);

  // Tint backgrounds (chips, prompts, badges)
  static const Color secondary = Color(0xFF0088FF);
  static const Color secondaryLight = Color(0xFFE6F4FF);

  // Premium / highlighted states (deeper blue)
  static const Color premium = Color(0xFF006EDC);
  static const Color premiumDark = Color(0xFF004C99);

  // Semantic
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFF8A80);

  // Light surfaces
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF707070);
  static const Color textTertiaryLight = Color(0xFFB3B3B3);
  static const Color dividerLight = Color(0xFFEEEEEE);
  static const Color borderLight = Color(0xFFE8E8E8);

  // Dark surfaces (blue-tinted)
  static const Color backgroundDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF12203A);
  static const Color cardDark = Color(0xFF1A2D4D);
  static const Color textPrimaryDark = Color(0xFFF5F7FA);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);
  static const Color dividerDark = Color(0xFF243B5C);
  static const Color borderDark = Color(0xFF2D4A6F);

  // Subject picker colors: a few brand blues plus a wide, distinguishable range
  // so subjects can be told apart at a glance.
  static const List<Color> subjectColors = [
    Color(0xFF0088FF), // blue (brand)
    Color(0xFF0055AA), // deep blue
    Color(0xFF4DA6FF), // sky
    Color(0xFF00B8D9), // cyan
    Color(0xFF0FB5A4), // teal
    Color(0xFF12B76A), // green
    Color(0xFF2E7D32), // forest
    Color(0xFF7CB342), // lime
    Color(0xFFF5B301), // yellow
    Color(0xFFFF9500), // orange
    Color(0xFFFF6B35), // coral
    Color(0xFFE5484D), // red
    Color(0xFFC2185B), // crimson
    Color(0xFFFF4D8D), // pink
    Color(0xFFA855F7), // purple
    Color(0xFF6C4CF1), // violet
    Color(0xFF8D6E63), // brown
    Color(0xFF64748B), // slate
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DA6FF), Color(0xFF0088FF)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF12203A)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066CC), Color(0xFF0088FF)],
  );
}
