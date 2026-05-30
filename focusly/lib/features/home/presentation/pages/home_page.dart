import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../notifications/presentation/pages/notifications_inbox_page.dart';
import '../../../planner/data/models/planned_item_model.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../streaks/data/models/streak_model.dart';
import '../../../streaks/presentation/cubit/streak_cubit.dart';
import '../../../streaks/presentation/cubit/streak_state.dart';
import '../../../streaks/presentation/widgets/streak_detail_sheet.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../cubit/home_cubit.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadHome(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isPremium = user?.isPremium ?? false;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated &&
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        context.read<HomeCubit>().loadHome();
      },
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, homeState) {
          final subjects = homeState.subjects;
          final averageProgress = _averageProgress(subjects);
          final totalDailyTarget = subjects.fold<int>(
            0,
            (sum, subject) => sum + subject.dailyTargetMinutes,
          );
          final completedSubjects = subjects
              .where((subject) => subject.progressPercent >= 100)
              .length;

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().loadHome(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final user = authState is AuthAuthenticated
                          ? authState.user
                          : null;
                      final name = user?.name.isNotEmpty == true
                          ? user!.name
                          : 'Student';
                      return _HomeHeader(
                        greeting: _getGreeting(),
                        name: name,
                        avatarUrl: user?.avatarUrl,
                        isDark: isDark,
                        subjectsCount: subjects.length,
                      );
                    },
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                  const SizedBox(height: 28),
                  _DynamicProgressCard(
                        averageProgress: averageProgress,
                        subjectsCount: subjects.length,
                        completedSubjects: completedSubjects,
                        isLoading: homeState.isLoading,
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 20),
                  _TodayFocusCard(
                    focusMinutes: homeState.todayFocusMinutes,
                    sessionCount: homeState.todaySessionCount,
                    isLoading: homeState.isLoading,
                    onStartFocus: () => context.go('/home?tab=2'),
                  ).animate().fadeIn(delay: 220.ms),
                  const SizedBox(height: 24),
                  BlocBuilder<StreakCubit, StreakState>(
                    builder: (context, streakState) {
                      return _StreaksWidget(
                        streak: streakState.streak,
                        onTap: streakState.streak == null
                            ? null
                            : () => showStreakDetailSheet(
                                  context,
                                  streak: streakState.streak!,
                                ),
                      );
                    },
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
                  const SizedBox(height: 32),
                  const _QuickActions()
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .scale(begin: const Offset(0.98, 0.98)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _StatItem(
                        label: 'Daily Target',
                        value: '${totalDailyTarget}m',
                        icon: Icons.timer_rounded,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        label: 'Subjects',
                        value: '${subjects.length}',
                        icon: Icons.menu_book_rounded,
                        color: Colors.green.shade400,
                      ),
                    ],
                  ).animate().fadeIn(delay: 350.ms, duration: 600.ms),
                  if (homeState.todaySchedules.isNotEmpty ||
                      homeState.todayTasks.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _UpcomingTodaySection(
                      schedules: homeState.todaySchedules,
                      tasks: homeState.todayTasks,
                      onOpenPlanner: () => context.push('/planner'),
                      onOpenSchedule: () => context.go('/home?tab=1'),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Subjects',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/subjects'),
                        child: const Text('See All'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                  const SizedBox(height: 16),
                  if (homeState.errorMessage != null && subjects.isEmpty)
                    _HomeMessageCard(
                      title: 'Could not load your dashboard',
                      subtitle: homeState.errorMessage!,
                      icon: Icons.cloud_off_rounded,
                    )
                  else if (subjects.isEmpty && !homeState.isLoading)
                    _HomeMessageCard(
                      title: 'No subjects yet',
                      subtitle:
                          'Create your first subject to make the home screen useful and alive.',
                      icon: Icons.auto_stories_outlined,
                      actionLabel: 'Create Subject',
                      onTap: () => context.push('/subjects'),
                    )
                  else
                    SizedBox(
                      height: 172,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: subjects.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return _SubjectPreviewCard(subject: subject);
                        },
                      ),
                    ).animate().fadeIn(delay: 650.ms, duration: 600.ms),
                  if (!isPremium) ...[
                    const SizedBox(height: 32),
                    const _HomePremiumPromoCard()
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static int _averageProgress(List<SubjectModel> subjects) {
    if (subjects.isEmpty) return 0;
    final total = subjects.fold<int>(
      0,
      (sum, subject) => sum + subject.progressPercent,
    );
    return (total / subjects.length).round();
  }


  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.name,
    this.avatarUrl,
    required this.isDark,
    required this.subjectsCount,
  });

  final String greeting;
  final String name;
  final String? avatarUrl;
  final bool isDark;
  final int subjectsCount;

  @override
  Widget build(BuildContext context) {
    final subduedText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: subduedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hey ${_firstName(name)}!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            if (avatarUrl != null && avatarUrl!.isNotEmpty) ...[
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(avatarUrl!),
              ),
            ],
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubjectsBadge(compact: compact, subjectsCount: subjectsCount),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsInboxPage(),
                    ),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, size: 22),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Student';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _SubjectsBadge extends StatelessWidget {
  const _SubjectsBadge({required this.compact, required this.subjectsCount});

  final bool compact;
  final int subjectsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCEE5D3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            compact ? '$subjectsCount' : '$subjectsCount Subjects',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicProgressCard extends StatelessWidget {
  const _DynamicProgressCard({
    required this.averageProgress,
    required this.subjectsCount,
    required this.completedSubjects,
    required this.isLoading,
  });

  final int averageProgress;
  final int subjectsCount;
  final int completedSubjects;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Study overview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isLoading
                ? 'Loading your progress...'
                : '$averageProgress% Progress',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoading
                ? 'Pulling your subjects and daily targets.'
                : '$completedSubjects of $subjectsCount subjects are fully completed.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (averageProgress.clamp(0, 100)) / 100,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreaksWidget extends StatelessWidget {
  const _StreaksWidget({required this.streak, this.onTap});

  final StreakModel? streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = streak?.current ?? 0;
    final longest = streak?.longest ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$current day streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current > 0
                          ? 'Best: $longest days · Tap for milestones'
                          : 'Start today to build your first study streak.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.focusMinutes,
    required this.sessionCount,
    required this.isLoading,
    required this.onStartFocus,
  });

  final int focusMinutes;
  final int sessionCount;
  final bool isLoading;
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: isLoading ? null : (focusMinutes % 120) / 120,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLoading ? '—' : '$focusMinutes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'min',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's focus",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? 'Loading your sessions...'
                      : '$sessionCount session${sessionCount == 1 ? '' : 's'} completed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onStartFocus,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Start Focus'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTodaySection extends StatelessWidget {
  const _UpcomingTodaySection({
    required this.schedules,
    required this.tasks,
    required this.onOpenPlanner,
    required this.onOpenSchedule,
  });

  final List<StudyScheduleModel> schedules;
  final List<PlannedItemModel> tasks;
  final VoidCallback onOpenPlanner;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming today',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            TextButton(
              onPressed: tasks.isNotEmpty ? onOpenPlanner : onOpenSchedule,
              child: Text(tasks.isNotEmpty ? 'Planner' : 'Schedule'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: schedules.length + tasks.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < schedules.length) {
                final schedule = schedules[index];
                return _UpcomingChip(
                  title: schedule.title,
                  subtitle: _formatTime(schedule.startAt),
                  icon: Icons.event_rounded,
                  color: AppColors.secondary,
                  onTap: onOpenSchedule,
                );
              }
              final task = tasks[index - schedules.length];
              return _UpcomingChip(
                title: task.title,
                subtitle: task.time ?? 'Today',
                icon: Icons.task_alt_rounded,
                color: AppColors.primary,
                onTap: onOpenPlanner,
              );
            },
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _UpcomingChip extends StatelessWidget {
  const _UpcomingChip({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 200,
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
              Icon(icon, color: color, size: 22),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _QuickActionCard(
                label: 'Start Focus',
                icon: Icons.play_circle_rounded,
                route: '/home?tab=2',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Add Task',
                icon: Icons.add_task_rounded,
                route: '/planner',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _QuickActionCard(
                label: 'Schedule',
                icon: Icons.calendar_month_rounded,
                route: '/home?tab=1',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Subjects',
                icon: Icons.menu_book_rounded,
                route: '/subjects',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                label: 'AI Notes',
                icon: Icons.auto_awesome_rounded,
                route: '/ai-notes',
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectPreviewCard extends StatelessWidget {
  const _SubjectPreviewCard({required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _HomeSubjectStyle.resolveColor(subject.color);

    return GestureDetector(
      onTap: () => context.push('/subjects/${subject.id}'),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _HomeSubjectStyle.resolveIcon(subject.icon),
                color: color,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${subject.dailyTargetMinutes} min target',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (subject.progressPercent.clamp(0, 100)) / 100,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePremiumPromoCard extends StatelessWidget {
  const _HomePremiumPromoCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E2413), const Color(0xFF1E170B)]
              : [const Color(0xFFFFF7E6), const Color(0xFFFFF0D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF4A3B1F) : const Color(0xFFFFE0A3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.premium.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.premium,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.premium.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'RECOMMENDED',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.premium,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to Focusly Premium',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock unlimited subjects, deep weekly & monthly analytics insights, and personalized study targets to build an unbreakable streak.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/premium'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.premium,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text(
                    'View Subscriptions',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  const _HomeMessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeSubjectStyle {
  static Color resolveColor(String? hex) {
    for (final color in AppColors.subjectColors) {
      if (_toHex(color) == hex) return color;
    }
    return AppColors.primary;
  }

  static IconData resolveIcon(String? key) {
    switch (key) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'palette':
        return Icons.palette_outlined;
      case 'code':
        return Icons.code_rounded;
      case 'book':
      default:
        return Icons.menu_book_rounded;
    }
  }

  static String _toHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
