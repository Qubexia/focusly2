import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/analytics_cubit.dart';
import '../bloc/analytics_state.dart';
import '../widgets/focus_trend_chart.dart';
import '../widgets/performance_card.dart';
import '../widgets/subject_distribution_chart.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalyticsCubit()..loadAnalytics(range: AnalyticsDateRange.week),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isPremiumUser = authState is AuthAuthenticated && authState.user.isPremium;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        final wasPremium = previous is AuthAuthenticated && previous.user.isPremium;
        final isPremium = current is AuthAuthenticated && current.user.isPremium;
        return !wasPremium && isPremium;
      },
      listener: (context, state) {
        context.read<AnalyticsCubit>().loadAnalytics();
      },
      child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF2F4F8),
            appBar: _AnalyticsAppBar(
              state: state,
              isPremiumUser: isPremiumUser,
            ),
            body: _buildBody(context, state, isPremiumUser, isDark),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsState state,
    bool isPremiumUser,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading && state.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.summary == null) {
      final isPremiumError =
          state.errorMessage!.toLowerCase().contains('premium') && !isPremiumUser;
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () => context.read<AnalyticsCubit>().loadAnalytics(),
        isPremiumError: isPremiumError,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AnalyticsCubit>().loadAnalytics(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          if (state.summary != null) ...[
            _HeroFocusCard(
              totalMinutes: state.summary!.totalFocusMinutes,
              totalSessions: state.summary!.totalSessions,
            ),
            const SizedBox(height: 14),
            if (state.performance != null)
              _QuickStats(
                tasksCompleted: state.performance!.totalTasksCompleted,
                avgDailyMinutes: state.summary!.dailyFocus.isNotEmpty
                    ? (state.summary!.totalFocusMinutes /
                            state.summary!.dailyFocus.length)
                        .round()
                    : 0,
                score: (state.performance!.completionScore * 100).round(),
                isDark: isDark,
              ),
            const SizedBox(height: 28),
            _SectionLabel(title: l10n.analyticsFocusTrend),
            const SizedBox(height: 12),
            FocusTrendChart(dailyFocus: state.summary!.dailyFocus),
          ],
          if (state.bySubject.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionLabel(title: l10n.analyticsBySubject),
            const SizedBox(height: 12),
            SubjectDistributionChart(subjects: state.bySubject),
          ],
          if (state.performance != null) ...[
            const SizedBox(height: 28),
            _SectionLabel(title: l10n.analyticsPerformanceScore),
            const SizedBox(height: 12),
            PerformanceCard(performance: state.performance!),
          ],
          if (!isPremiumUser) ...[
            const SizedBox(height: 28),
            _PremiumBanner(isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AnalyticsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AnalyticsAppBar({
    required this.state,
    required this.isPremiumUser,
  });

  final AnalyticsState state;
  final bool isPremiumUser;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0055CC), Color(0xFF0099FF)],
          ),
        ),
      ),
      title: Text(
        AppLocalizations.of(context).analyticsTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          onPressed: () => context.read<AnalyticsCubit>().loadAnalytics(),
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _DateRangeSelector(
            currentRange: state.dateRange,
            isPremiumUser: isPremiumUser,
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroFocusCard extends StatelessWidget {
  const _HeroFocusCard({
    required this.totalMinutes,
    required this.totalSessions,
  });

  final int totalMinutes;
  final int totalSessions;

  String _formatTime(AppLocalizations l10n, int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0
          ? l10n.analyticsDurationHours(h)
          : l10n.analyticsDurationHoursMinutes(h, m);
    }
    return l10n.analyticsDurationMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0055CC), Color(0xFF0099FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.timer_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.analyticsTotalFocusTime,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _formatTime(l10n, totalMinutes),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.analyticsMinutesTotal(totalMinutes),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalSessions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.analyticsSessionsLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

// ─── Quick Stats Row ──────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.tasksCompleted,
    required this.avgDailyMinutes,
    required this.score,
    required this.isDark,
  });

  final int tasksCompleted;
  final int avgDailyMinutes;
  final int score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            icon: Icons.task_alt_rounded,
            value: '$tasksCompleted',
            label: l10n.analyticsTasksDone,
            color: const Color(0xFF00BB77),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.show_chart_rounded,
            value: l10n.analyticsMinutesShort(avgDailyMinutes),
            label: l10n.analyticsDailyAvg,
            color: AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStat(
            icon: Icons.stars_rounded,
            value: l10n.analyticsPercent(score),
            label: l10n.analyticsScore,
            color: score >= 70 ? const Color(0xFFFF9500) : AppColors.primary,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// ─── Premium Banner ───────────────────────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004C99), Color(0xFF0077CC)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.analyticsUnlockDeeperInsights,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.analyticsPremiumTrendsSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/premium'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.analyticsUpgrade,
                      style: const TextStyle(
                        color: Color(0xFF004C99),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
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

// ─── Error / Premium Lock View ────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isPremiumError,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isPremiumError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isPremiumError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.analyticsUnlockFullInsights,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/premium'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(l10n.analyticsUpgradeToPremium),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context
                    .read<AnalyticsCubit>()
                    .loadAnalytics(range: AnalyticsDateRange.week),
                child: Text(l10n.analyticsReturnToCurrentWeek),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}

// ─── Date Range Selector ──────────────────────────────────────────────────────

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.currentRange,
    required this.isPremiumUser,
  });

  final AnalyticsDateRange currentRange;
  final bool isPremiumUser;

  void _showPremiumSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.analyticsPremiumAnalyticsTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.analyticsPremiumAnalyticsBody,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    sheetContext.push('/premium');
                  },
                  child: Text(l10n.analyticsUpgradeToPremium),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _RangeBtn(
            label: l10n.analyticsRangeWeek,
            isSelected: currentRange == AnalyticsDateRange.week,
            onTap: () => context
                .read<AnalyticsCubit>()
                .loadAnalytics(range: AnalyticsDateRange.week),
          ),
          _RangeBtn(
            label: l10n.analyticsRangeMonth,
            isSelected: currentRange == AnalyticsDateRange.month,
            isLocked: !isPremiumUser,
            onTap: () {
              if (!isPremiumUser) {
                _showPremiumSheet(context);
                return;
              }
              context
                  .read<AnalyticsCubit>()
                  .loadAnalytics(range: AnalyticsDateRange.month);
            },
          ),
          _RangeBtn(
            label: l10n.analyticsRangeYear,
            isSelected: currentRange == AnalyticsDateRange.year,
            isLocked: !isPremiumUser,
            onTap: () {
              if (!isPremiumUser) {
                _showPremiumSheet(context);
                return;
              }
              context
                  .read<AnalyticsCubit>()
                  .loadAnalytics(range: AnalyticsDateRange.year);
            },
          ),
        ],
      ),
    );
  }
}

class _RangeBtn extends StatelessWidget {
  const _RangeBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLocked = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked) ...[
                const Icon(Icons.lock_rounded, size: 10, color: Colors.white54),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF0055CC)
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
