import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/analytics_cubit.dart';
import '../bloc/analytics_state.dart';
import '../widgets/kpi_card.dart';
import '../widgets/focus_trend_chart.dart';
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
    final isPremiumUser =
        authState is AuthAuthenticated && authState.user.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            onPressed: () => context.read<AnalyticsCubit>().loadAnalytics(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          final isPremiumError = (state.errorMessage ?? '').toLowerCase().contains(
            'premium',
          );

          if (state.isLoading && state.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.summary == null) {
            if (isPremiumError) {
              return _PremiumLockView(message: state.errorMessage!);
            }
            return Center(child: Text(state.errorMessage!));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AnalyticsCubit>().loadAnalytics(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _DateRangeSelector(
                  currentRange: state.dateRange,
                  isPremiumUser: isPremiumUser,
                ),
                if (state.summary != null) ...[
                  const SizedBox(height: 16),
                  _InsightsTeaserCard(
                    lockedRequest: isPremiumError,
                    message: state.errorMessage,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        title: 'Focus Time',
                        value: '${state.summary?.totalFocusMinutes ?? 0}',
                        unit: 'min',
                        icon: Icons.timer_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        title: 'Sessions',
                        value: '${state.summary?.totalSessions ?? 0}',
                        unit: 'total',
                        icon: Icons.bolt_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FocusTrendChart(dailyFocus: state.summary?.dailyFocus ?? []),
                const SizedBox(height: 24),
                SubjectDistributionChart(subjects: state.bySubject),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    required this.currentRange,
    required this.isPremiumUser,
  });

  final AnalyticsDateRange currentRange;
  final bool isPremiumUser;

  void _showPremiumAnalyticsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Month and Year insights are available for premium users only. Upgrade to unlock broader trends and comparisons.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Upgrade to Premium'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _RangeButton(
            label: 'Week',
            isSelected: currentRange == AnalyticsDateRange.week,
            onTap: () => context.read<AnalyticsCubit>().loadAnalytics(range: AnalyticsDateRange.week),
          ),
          _RangeButton(
            label: 'Month',
            isSelected: currentRange == AnalyticsDateRange.month,
            isLocked: !isPremiumUser,
            onTap: () {
              if (!isPremiumUser) {
                _showPremiumAnalyticsSheet(context);
                return;
              }
              context.read<AnalyticsCubit>().loadAnalytics(
                    range: AnalyticsDateRange.month,
                  );
            },
          ),
          _RangeButton(
            label: 'Year',
            isSelected: currentRange == AnalyticsDateRange.year,
            isLocked: !isPremiumUser,
            onTap: () {
              if (!isPremiumUser) {
                _showPremiumAnalyticsSheet(context);
                return;
              }
              context.read<AnalyticsCubit>().loadAnalytics(
                    range: AnalyticsDateRange.year,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isLocked ? '$label  Lock' : label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumLockView extends StatelessWidget {
  const _PremiumLockView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Unlock Full Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Open Paywall
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Upgrade to Premium'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<AnalyticsCubit>().loadAnalytics(range: AnalyticsDateRange.week),
              child: const Text('Return to current week'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsTeaserCard extends StatelessWidget {
  const _InsightsTeaserCard({
    required this.lockedRequest,
    required this.message,
  });

  final bool lockedRequest;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = lockedRequest
        ? 'Weekly insights are available now'
        : 'Go deeper with premium insights';
    final subtitle = lockedRequest
        ? 'You are viewing your current week. Monthly and yearly breakdowns unlock with premium.'
        : 'Track broader trends, compare months, and unlock richer study analytics as you grow.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lockedRequest && message != null ? '$subtitle\n\n$message' : subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Open paywall
                    },
                    child: const Text('Upgrade to Premium'),
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
