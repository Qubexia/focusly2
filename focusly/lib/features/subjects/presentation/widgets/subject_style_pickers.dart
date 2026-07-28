import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/subject_style.dart';

/// Color swatches for the subject editor. Shared by the subjects list editor
/// and the subject detail editor.
class SubjectColorPicker extends StatelessWidget {
  const SubjectColorPicker({
    super.key,
    required this.selectedHex,
    required this.onSelected,
  });

  final String selectedHex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: SubjectPalette.options.map((option) {
        final isSelected = option.hex == selectedHex;
        return GestureDetector(
          onTap: () => onSelected(option.hex),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    color: option.color.computeLuminance() > 0.55
                        ? AppColors.textPrimaryLight
                        : Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Icon grid for the subject editor. The catalog is long, so it scrolls inside
/// a fixed height instead of stretching the editor sheet.
class SubjectIconPicker extends StatelessWidget {
  const SubjectIconPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
    this.height = 184,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 72,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemCount: SubjectIconCatalog.options.length,
        itemBuilder: (context, index) {
          final option = SubjectIconCatalog.options[index];
          final isSelected = option.key == selectedKey;
          return GestureDetector(
            onTap: () => onSelected(option.key),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: Icon(
                option.icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          );
        },
      ),
    );
  }
}
