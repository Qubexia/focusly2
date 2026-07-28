import 'package:flutter/material.dart';

import 'app_colors.dart';

class SubjectColorOption {
  const SubjectColorOption({required this.hex, required this.color});

  final String hex;
  final Color color;
}

/// Shared color catalog for subjects. Kept in one place so the subjects list,
/// the subject detail editor and the home cards always agree on a color.
class SubjectPalette {
  static final List<SubjectColorOption> options = [
    ...AppColors.subjectColors.map(
      (color) => SubjectColorOption(hex: toHex(color), color: color),
    ),
  ];

  static SubjectColorOption get defaultOption => options.first;

  /// Resolves any stored hex, including colors from older palettes that are no
  /// longer offered in the picker, so existing subjects keep their color.
  static Color resolveColor(String? hex) {
    for (final option in options) {
      if (option.hex == hex) return option.color;
    }
    return parseHex(hex) ?? AppColors.primary;
  }

  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    var value = hex.trim().replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return null;
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  static String toHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class SubjectIconOption {
  const SubjectIconOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}

class SubjectIconCatalog {
  static const List<SubjectIconOption> options = [
    SubjectIconOption(key: 'book', icon: Icons.menu_book_rounded),
    SubjectIconOption(key: 'literature', icon: Icons.auto_stories_rounded),
    SubjectIconOption(key: 'school', icon: Icons.school_rounded),
    SubjectIconOption(key: 'math', icon: Icons.functions_rounded),
    SubjectIconOption(key: 'calculate', icon: Icons.calculate_rounded),
    SubjectIconOption(key: 'science', icon: Icons.science_rounded),
    SubjectIconOption(key: 'biology', icon: Icons.biotech_rounded),
    SubjectIconOption(key: 'physics', icon: Icons.bolt_rounded),
    SubjectIconOption(key: 'nature', icon: Icons.eco_rounded),
    SubjectIconOption(key: 'space', icon: Icons.rocket_launch_rounded),
    SubjectIconOption(key: 'language', icon: Icons.language_rounded),
    SubjectIconOption(key: 'translate', icon: Icons.translate_rounded),
    SubjectIconOption(key: 'history', icon: Icons.history_edu_rounded),
    SubjectIconOption(key: 'geography', icon: Icons.public_rounded),
    SubjectIconOption(key: 'map', icon: Icons.map_rounded),
    SubjectIconOption(key: 'religion', icon: Icons.mosque_rounded),
    SubjectIconOption(key: 'palette', icon: Icons.palette_rounded),
    SubjectIconOption(key: 'design', icon: Icons.brush_rounded),
    SubjectIconOption(key: 'music', icon: Icons.music_note_rounded),
    SubjectIconOption(key: 'theater', icon: Icons.theater_comedy_rounded),
    SubjectIconOption(key: 'photo', icon: Icons.camera_alt_rounded),
    SubjectIconOption(key: 'code', icon: Icons.code_rounded),
    SubjectIconOption(key: 'computer', icon: Icons.computer_rounded),
    SubjectIconOption(key: 'engineering', icon: Icons.engineering_rounded),
    SubjectIconOption(key: 'architecture', icon: Icons.architecture_rounded),
    SubjectIconOption(key: 'business', icon: Icons.business_center_rounded),
    SubjectIconOption(key: 'economics', icon: Icons.trending_up_rounded),
    SubjectIconOption(key: 'law', icon: Icons.gavel_rounded),
    SubjectIconOption(key: 'medicine', icon: Icons.medical_services_rounded),
    SubjectIconOption(key: 'psychology', icon: Icons.psychology_rounded),
    SubjectIconOption(key: 'sport', icon: Icons.fitness_center_rounded),
    SubjectIconOption(key: 'writing', icon: Icons.edit_note_rounded),
    SubjectIconOption(key: 'idea', icon: Icons.lightbulb_rounded),
  ];

  static SubjectIconOption get defaultOption => options.first;

  static IconData iconForKey(String? key) {
    for (final option in options) {
      if (option.key == key) return option.icon;
    }
    return Icons.menu_book_rounded;
  }
}
