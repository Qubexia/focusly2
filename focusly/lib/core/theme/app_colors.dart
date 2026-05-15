import 'package:flutter/material.dart';

/// Focusly brand color palette
class AppColors {
  AppColors._();

  // ─── Primary (Soft Sage) ───
  static const Color primary = Color(0xFF639F82);
  static const Color primaryLight = Color(0xFFB8D8BA);
  static const Color primaryDark = Color(0xFF4A7A63);

  // ─── Secondary / Success (Soft Teal/Mint) ───
  static const Color secondary = Color(0xFF81B29A);
  static const Color secondaryLight = Color(0xFFA8D5BA);

  // ─── Accent / Premium (Warm Sand) ───
  static const Color premium = Color(0xFFE07A5F);
  static const Color premiumDark = Color(0xFFC96950);

  // ─── Error (Soft Terracotta) ───
  static const Color error = Color(0xFFE07A5F);
  static const Color errorLight = Color(0xFFF2A089);

  // ─── Neutrals — Light (Warm Minimal) ───
  static const Color backgroundLight = Color(0xFFFDFCF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF3D405B);
  static const Color textSecondaryLight = Color(0xFF818398);
  static const Color textTertiaryLight = Color(0xFFB4B5C1);
  static const Color dividerLight = Color(0xFFF2F2F2);
  static const Color borderLight = Color(0xFFE8E8E8);

  // ─── Neutrals — Dark (Deep Slate) ───
  static const Color backgroundDark = Color(0xFF1B1B1F);
  static const Color surfaceDark = Color(0xFF252529);
  static const Color cardDark = Color(0xFF2C2C31);
  static const Color textPrimaryDark = Color(0xFFFDFCF9);
  static const Color textSecondaryDark = Color(0xFFB4B5C1);
  static const Color textTertiaryDark = Color(0xFF818398);
  static const Color dividerDark = Color(0xFF323236);
  static const Color borderDark = Color(0xFF3D3D42);

  // ─── Subject colors (Pastel Palette) ───
  static const List<Color> subjectColors = [
    Color(0xFFE07A5F), // Terracotta
    Color(0xFF3D405B), // Navy
    Color(0xFF81B29A), // Green
    Color(0xFFF2CC8F), // Sand
    Color(0xFF90BE6D), // Pistachio
    Color(0xFFF9C74F), // Maize
    Color(0xFF4D908E), // Muted Teal
    Color(0xFF577590), // Slate
    Color(0xFF277DA1), // Blue
    Color(0xFFF94144), // Coral
  ];

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF639F82), Color(0xFF81B29A)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B1B1F), Color(0xFF252529)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
  );
}
