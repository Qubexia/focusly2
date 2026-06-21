import 'package:flutter/material.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';

/// "OR" divider used between form submit and social login buttons.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.authOrDivider,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ],
    );
  }
}
