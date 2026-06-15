import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/analytics_subject_model.dart';

class SubjectDistributionChart extends StatelessWidget {
  const SubjectDistributionChart({super.key, required this.subjects});

  final List<AnalyticsSubjectModel> subjects;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subjects.isEmpty) {
      return _card(
        isDark: isDark,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Text('No subject data for this range.'),
          ),
        ),
      );
    }

    final maxMinutes = subjects
        .map((s) => s.focusMinutes)
        .reduce((a, b) => a > b ? a : b);

    return _card(
      isDark: isDark,
      child: Column(
        children: List.generate(subjects.length, (i) {
          final s = subjects[i];
          final color = _parseColor(s.color);
          final ratio =
              maxMinutes == 0 ? 0.0 : s.focusMinutes / maxMinutes;
          final h = s.focusMinutes ~/ 60;
          final m = s.focusMinutes % 60;
          final timeLabel = h > 0 ? '${h}h ${m}m' : '${m}m';

          return Padding(
            padding: EdgeInsets.only(
                bottom: i < subjects.length - 1 ? 18 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.subjectName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _card({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
