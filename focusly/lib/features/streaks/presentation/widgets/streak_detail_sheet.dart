import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/streak_model.dart';

Future<void> showStreakDetailSheet(
  BuildContext context, {
  required StreakModel streak,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final milestones = _milestones(streak.current);

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streak.current} day streak',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Best: ${streak.longest} days',
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StreakStatRow(
              label: 'Total points',
              value: '${streak.points}',
              icon: Icons.stars_rounded,
              color: AppColors.premium,
            ),
            if (streak.lastActiveDate != null) ...[
              const SizedBox(height: 10),
              _StreakStatRow(
                label: 'Last active',
                value: streak.lastActiveDate!,
                icon: Icons.calendar_today_rounded,
                color: AppColors.secondary,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Milestones',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: milestones
                  .map(
                    (m) => _MilestoneChip(
                      days: m.days,
                      unlocked: m.unlocked,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    },
  );
}

class _StreakStatRow extends StatelessWidget {
  const _StreakStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.days, required this.unlocked});

  final int days;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.secondary.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? AppColors.secondary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 16,
            color: unlocked ? AppColors.secondary : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            '${days}d',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.secondary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone {
  const _Milestone({required this.days, required this.unlocked});

  final int days;
  final bool unlocked;
}

List<_Milestone> _milestones(int current) {
  const targets = [3, 7, 30, 100];
  return targets
      .map((d) => _Milestone(days: d, unlocked: current >= d))
      .toList();
}
