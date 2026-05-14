import 'package:flutter/material.dart';

/// Focusly brand color palette
class AppColors {
  AppColors._();

  // ─── Primary ───
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4A3DB8);

  // ─── Secondary / Success ───
  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF55EFC4);

  // ─── Accent / Premium ───
  static const Color premium = Color(0xFFFDCB6E);
  static const Color premiumDark = Color(0xFFF39C12);

  // ─── Error ───
  static const Color error = Color(0xFFE17055);
  static const Color errorLight = Color(0xFFFF7675);

  // ─── Neutrals — Light ───
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1E1E2E);
  static const Color textSecondaryLight = Color(0xFF636E72);
  static const Color textTertiaryLight = Color(0xFFB2BEC3);
  static const Color dividerLight = Color(0xFFE9ECEF);
  static const Color borderLight = Color(0xFFDFE6E9);

  // ─── Neutrals — Dark ───
  static const Color backgroundDark = Color(0xFF121218);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color cardDark = Color(0xFF252536);
  static const Color textPrimaryDark = Color(0xFFF8F9FA);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);
  static const Color textTertiaryDark = Color(0xFF636E72);
  static const Color dividerDark = Color(0xFF2D3436);
  static const Color borderDark = Color(0xFF3D3D56);

  // ─── Subject colors (user-selectable) ───
  static const List<Color> subjectColors = [
    Color(0xFFFFB020),
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFD63031),
    Color(0xFF00CEC9),
    Color(0xFFE84393),
    Color(0xFF636E72),
    Color(0xFF2D3436),
  ];

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E2E), Color(0xFF2D3436)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDCB6E), Color(0xFFF39C12)],
  );
}
