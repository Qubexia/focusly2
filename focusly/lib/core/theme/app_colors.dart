import 'package:flutter/material.dart';

/// Focusly palette aligned with Zakerly-style blue identity (#0088FF).
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

  // Charts / heatmap empty cells
  static const Color heatmapEmptyLight = Color(0xFFE6F4FF);
  static const Color heatmapEmptyDark = Color(0xFF1A2D4D);

  // Subject picker colors (blue family)
  static const List<Color> subjectColors = [
    Color(0xFF0088FF),
    Color(0xFF0066CC),
    Color(0xFF4DA6FF),
    Color(0xFF0055AA),
    Color(0xFF66B8FF),
    Color(0xFF0077DD),
    Color(0xFF99CCFF),
    Color(0xFF003D7A),
    Color(0xFF33A3FF),
    Color(0xFFE6F4FF),
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
