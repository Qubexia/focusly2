import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/analytics_heatmap_model.dart';

class FocusHeatmap extends StatelessWidget {
  const FocusHeatmap({required this.heatmap, super.key});

  final AnalyticsHeatmapModel heatmap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final max = heatmap.maxMinutes;
    final byDate = {for (final d in heatmap.days) d.date: d.focusMinutes};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus heatmap · ${heatmap.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(heatmap.days.length.clamp(0, 120), (index) {
              final day = heatmap.days[index];
              final intensity = max == 0 ? 0.0 : day.focusMinutes / max;
              return Tooltip(
                message: '${day.date}: ${day.focusMinutes} min',
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      isDark ? AppColors.heatmapEmptyDark : AppColors.heatmapEmptyLight,
                      AppColors.primary,
                      intensity,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          if (heatmap.days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No focus data for ${heatmap.year} yet.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${byDate.length} active days tracked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
