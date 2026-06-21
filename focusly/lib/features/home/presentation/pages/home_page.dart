import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/premium/premium_status.dart';
import '../../../../core/services/premium_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../notifications/presentation/pages/notifications_inbox_page.dart';
import '../../../planner/data/models/planned_item_model.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../streaks/presentation/cubit/streak_cubit.dart';
import '../../../streaks/presentation/cubit/streak_state.dart';
import '../../../streaks/presentation/widgets/streak_detail_sheet.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subscription/presentation/cubit/subscription_cubit.dart';
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
    final subscription = context.watch<SubscriptionCubit>().state.subscription;
    final isPremium = hasPremiumAccess(
      authState: authState,
      subscription: subscription,
    );

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: premiumStatusChanged,
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
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final user = authState is AuthAuthenticated
                            ? authState.user
                            : null;
                        final l10n = AppLocalizations.of(context);
                        final name = user?.name.isNotEmpty == true
                            ? user!.name
                            : l10n.homeDefaultName;
                        return _HomeHeader(
                          greeting: _getGreeting(context),
                          dateLabel: _formatToday(context),
                          name: name,
                          avatarUrl: user?.avatarUrl,
                          isDark: isDark,
                        );
                      },
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15),
                    const SizedBox(height: 24),
                    _OverviewHero(
                          averageProgress: averageProgress,
                          subjectsCount: subjects.length,
                          completedSubjects: completedSubjects,
                          focusMinutes: homeState.todayFocusMinutes,
                          sessionCount: homeState.todaySessionCount,
                          isLoading: homeState.isLoading,
                          onStartFocus: () => context.go('/home?tab=2'),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .scale(begin: const Offset(0.97, 0.97)),
                    const SizedBox(height: 16),
                    BlocBuilder<StreakCubit, StreakState>(
                      builder: (context, streakState) {
                        final streak = streakState.streak;
                        return _StatStrip(
                          streakDays: streak?.current ?? 0,
                          onStreakTap: streak == null
                              ? null
                              : () => showStreakDetailSheet(
                                    context,
                                    streak: streak,
                                  ),
                          dailyTargetMinutes: totalDailyTarget,
                          subjectsCount: subjects.length,
                        );
                      },
                    ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
                    const SizedBox(height: 28),
                    _QuickActions(isPremium: isPremium)
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 500.ms),
                    if (homeState.todaySchedules.isNotEmpty ||
                        homeState.todayTasks.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _UpcomingTodaySection(
                        schedules: homeState.todaySchedules,
                        tasks: homeState.todayTasks,
                        onOpenPlanner: () => context.push('/planner'),
                        onOpenSchedule: () => context.go('/home?tab=1'),
                      ).animate().fadeIn(delay: 380.ms, duration: 500.ms),
                    ],
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: AppLocalizations.of(context).homeSubjectsTitle,
                      actionLabel: AppLocalizations.of(context).homeSeeAll,
                      onAction: () => context.push('/subjects'),
                    ).animate().fadeIn(delay: 440.ms, duration: 500.ms),
                    const SizedBox(height: 14),
                    if (homeState.errorMessage != null && subjects.isEmpty)
                      _HomeMessageCard(
                        title: AppLocalizations.of(context)
                            .homeDashboardLoadErrorTitle,
                        subtitle: homeState.errorMessage!,
                        icon: Icons.cloud_off_rounded,
                      )
                    else if (subjects.isEmpty && !homeState.isLoading)
                      _HomeMessageCard(
                        title: AppLocalizations.of(context).homeNoSubjectsTitle,
                        subtitle: AppLocalizations.of(context)
                            .homeNoSubjectsSubtitle,
                        icon: Icons.auto_stories_outlined,
                        actionLabel:
                            AppLocalizations.of(context).homeCreateSubject,
                        onTap: () => context.push('/subjects'),
                      )
                    else
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: subjects.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return _SubjectPreviewCard(subject: subject);
                          },
                        ),
                      ).animate().fadeIn(delay: 520.ms, duration: 500.ms),
                    if (!isPremium) ...[
                      const SizedBox(height: 28),
                      const _HomePremiumPromoCard()
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 500.ms),
                    ],
                  ],
                ),
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

  static String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  static String _formatToday(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final weekday = DateFormat.EEEE(locale).format(now);
    final dayMonth = DateFormat.MMMd(locale).format(now);
    return '$weekday · $dayMonth';
  }
}

/// Shared section title with an optional trailing action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.dateLabel,
    required this.name,
    this.avatarUrl,
    required this.isDark,
  });

  final String greeting;
  final String dateLabel;
  final String name;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subduedText = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting · $dateLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: subduedText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeGreetingName(_firstName(name, l10n.homeDefaultName)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (avatarUrl != null && avatarUrl!.isNotEmpty) ...[
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondaryLight,
            backgroundImage: NetworkImage(avatarUrl!),
          ),
          const SizedBox(width: 10),
        ],
        _IconBubble(
          icon: Icons.notifications_outlined,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsInboxPage(),
            ),
          ),
        ),
      ],
    );
  }

  static String _firstName(String name, String fallback) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

/// Single brand-coloured hero that merges overall progress with today's focus.
class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.averageProgress,
    required this.subjectsCount,
    required this.completedSubjects,
    required this.focusMinutes,
    required this.sessionCount,
    required this.isLoading,
    required this.onStartFocus,
  });

  final int averageProgress;
  final int subjectsCount;
  final int completedSubjects;
  final int focusMinutes;
  final int sessionCount;
  final bool isLoading;
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.homeStudyOverview,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ProgressRing(
                value: isLoading ? null : (averageProgress.clamp(0, 100)) / 100,
                label: isLoading ? '—' : '$averageProgress%',
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeOverallProgress,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLoading
                          ? l10n.homeOverviewLoading
                          : subjectsCount == 0
                              ? l10n.homeOverviewEmpty
                              : l10n.homeSubjectsCompleted(
                                  completedSubjects,
                                  subjectsCount,
                                ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(
                icon: Icons.schedule_rounded,
                value: isLoading ? '—' : '${focusMinutes}m',
                label: l10n.homeFocusedToday,
              ),
              const SizedBox(width: 12),
              _HeroStat(
                icon: Icons.check_circle_rounded,
                value: isLoading ? '—' : '$sessionCount',
                label: l10n.homeSessionsLabel(sessionCount),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartFocus,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                l10n.homeStartFocus,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value, required this.label});

  /// Null renders an indeterminate spinner (loading).
  final double? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 7,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
            ),
          ),
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, glanceable stat tiles (streak / daily target / subjects).
class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.streakDays,
    required this.onStreakTap,
    required this.dailyTargetMinutes,
    required this.subjectsCount,
  });

  final int streakDays;
  final VoidCallback? onStreakTap;
  final int dailyTargetMinutes;
  final int subjectsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _StatTile(
          icon: Icons.local_fire_department_rounded,
          value: '$streakDays',
          label: l10n.homeDayStreak,
          color: AppColors.primary,
          onTap: onStreakTap,
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.flag_rounded,
          value: '${dailyTargetMinutes}m',
          label: l10n.homeDailyTarget,
          color: AppColors.primaryLight,
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.menu_book_rounded,
          value: '$subjectsCount',
          label: l10n.homeSubjectsStat,
          color: AppColors.primaryDark,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
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
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.homeUpcomingToday,
          actionLabel: tasks.isNotEmpty
              ? l10n.homeNavPlanner
              : l10n.homeNavSchedule,
          onAction: tasks.isNotEmpty ? onOpenPlanner : onOpenSchedule,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
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
                subtitle: task.time ?? l10n.homeToday,
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
          width: 196,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
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
  const _QuickActions({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.homeQuickActions),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                label: l10n.homeQuickFocusLabel,
                subtitle: l10n.homeQuickFocusSubtitle,
                icon: Icons.play_circle_rounded,
                route: '/home?tab=2',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: l10n.homeQuickAddTaskLabel,
                subtitle: l10n.homeQuickAddTaskSubtitle,
                icon: Icons.add_task_rounded,
                route: '/planner',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                label: l10n.homeQuickScheduleLabel,
                subtitle: l10n.homeQuickScheduleSubtitle,
                icon: Icons.calendar_month_rounded,
                route: '/home?tab=1',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: l10n.homeQuickAiNotesLabel,
                subtitle: l10n.homeQuickAiNotesSubtitle,
                icon: Icons.auto_awesome_rounded,
                route: '/ai-notes',
                requiresPremium: !isPremium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.requiresPremium = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool requiresPremium;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (requiresPremium) {
            context.push('/premium');
            return;
          }
          if (route.startsWith('/home')) {
            context.go(route);
          } else {
            context.push(route);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 22),
                  ),
                  const Spacer(),
                  if (requiresPremium)
                    Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    )
                  else
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        width: 150,
        padding: const EdgeInsets.all(18),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _HomeSubjectStyle.resolveIcon(subject.icon),
                color: color,
                size: 22,
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
            Row(
              children: [
                Text(
                  '${subject.progressPercent}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)
                        .homeSubjectTargetMinutes(subject.dailyTargetMinutes),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (subject.progressPercent.clamp(0, 100)) / 100,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.12),
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
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.18),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        l10n.homePremiumRecommended,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homePremiumUpgradeTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.homePremiumBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    l10n.homeViewSubscriptions,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
