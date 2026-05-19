import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../notifications/presentation/pages/notifications_inbox_page.dart';
import '../../../streaks/presentation/cubit/streak_cubit.dart';
import '../../../streaks/presentation/cubit/streak_state.dart';
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
                  const SizedBox(height: 24),
                  BlocBuilder<StreakCubit, StreakState>(
                    builder: (context, streakState) {
                      return _StreaksWidget(
                        streak: streakState.current,
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
    required this.isDark,
    required this.subjectsCount,
  });

  final String greeting;
  final String name;
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
  const _StreaksWidget({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                  '$streak day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak > 0
                      ? 'You are building consistent study momentum.'
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
        ],
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
                label: 'Subjects',
                icon: Icons.menu_book_rounded,
                route: '/subjects',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                label: 'Focus',
                icon: Icons.timer_rounded,
                route: '/main',
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

  void _showSubscriptionPlans(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                        Text(
                          'Choose Your Plan',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlock unlimited access to all features',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 28),
              _PlanOptionCard(
                title: 'Monthly Plan',
                price: '\$4.99',
                period: '/ month',
                description: 'Perfect for short-term intense preparation.',
                isPopular: false,
                onTap: () => _onSubscribeMock(context, 'Monthly Plan'),
              ),
              const SizedBox(height: 14),
              _PlanOptionCard(
                title: 'Yearly Premium',
                price: '\$29.99',
                period: '/ year',
                description: 'Best for consistent progress and tracking.',
                isPopular: true,
                onTap: () => _onSubscribeMock(context, 'Yearly Premium'),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Restore Purchases  •  Terms of Service  •  Privacy Policy',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                            : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSubscribeMock(BuildContext context, String planName) {
    Navigator.of(context).pop(); // Dismiss bottom sheet
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: 48,
            ),
          ),
          title: Text('Subscribed to $planName!'),
          content: const Text(
            'Thank you for upgrading! Subscriptions are simulated in this build, and full premium features have been unlocked.',
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(120, 48),
                ),
                child: const Text('Awesome'),
              ),
            ),
          ],
        );
      },
    );
  }

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
                  onPressed: () => _showSubscriptionPlans(context),
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

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.isPopular,
    required this.onTap,
  });

  final String title;
  final String price;
  final String period;
  final String description;
  final bool isPopular;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isPopular
                ? AppColors.premium
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular
              ? [
                  BoxShadow(
                    color: AppColors.premium.withValues(alpha: isDark ? 0.05 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.premium.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'BEST VALUE',
                          style: TextStyle(
                            color: AppColors.premium,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isPopular ? AppColors.premium : null,
                          ),
                    ),
                    Text(
                      period,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
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
