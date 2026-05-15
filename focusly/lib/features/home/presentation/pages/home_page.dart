import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
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

    return BlocBuilder<HomeCubit, HomeState>(
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
        final leadSubject = _topSubject(subjects);

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
                const SizedBox(height: 32),
                _HomeFocusCard(
                  subject: leadSubject,
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
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

  static SubjectModel? _topSubject(List<SubjectModel> subjects) {
    if (subjects.isEmpty) return null;
    final sorted = [...subjects]
      ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));
    return sorted.first;
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
    required this.avatarUrl,
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
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubjectsBadge(compact: compact, subjectsCount: subjectsCount),
                const SizedBox(width: 10),
                _HeaderAvatar(avatarUrl: avatarUrl, fallbackName: name),
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

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.avatarUrl, required this.fallbackName});

  final String? avatarUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: hasAvatar
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarFallback(name: fallbackName),
              )
            : _AvatarFallback(name: fallbackName),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
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

class _HomeFocusCard extends StatelessWidget {
  const _HomeFocusCard({required this.subject});

  final SubjectModel? subject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = subject == null
        ? AppColors.primary
        : _HomeSubjectStyle.resolveColor(subject!.color);
    final title = subject == null ? 'Start your first subject' : subject!.name;
    final subtitle = subject == null
        ? 'Create a subject to unlock progress tracking and chapter planning.'
        : 'This subject currently leads your dashboard with ${subject!.progressPercent}% progress.';

    return Container(
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
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              subject == null
                  ? Icons.rocket_launch_rounded
                  : _HomeSubjectStyle.resolveIcon(subject!.icon),
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
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
