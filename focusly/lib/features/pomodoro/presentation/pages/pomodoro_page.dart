import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../cubit/pomodoro_cubit.dart';

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PomodoroCubit()..load(),
      child: const _PomodoroView(),
    );
  }
}

class _PomodoroView extends StatelessWidget {
  const _PomodoroView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PomodoroCubit, PomodoroState>(
      listener: (context, state) {
        if (state.feedbackType == PomodoroFeedbackType.none ||
            state.feedbackMessage == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.feedbackMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<PomodoroCubit>().clearFeedback();
      },
      builder: (context, state) {
        final activeSubject = _findSubject(
          state.subjects,
          state.activeSession?.subjectId ?? state.selectedSubjectId,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Focus Timer'),
            actions: [
              IconButton(
                onPressed: () => context.push('/pomodoro/history'),
                icon: const Icon(Icons.history_rounded),
                tooltip: 'History',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<PomodoroCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 62),
              children: [
                _PomodoroHeroCard(
                  remainingSeconds: state.remainingSeconds,
                  isRunning: state.isRunning,
                  activeSubject: activeSubject,
                  hasSession: state.activeSession != null,
                  focusMinutes: state.focusMinutes,
                  breakMinutes: state.breakMinutes,
                ),
                const SizedBox(height: 20),
                _PomodoroControlsCard(
                  state: state,
                  onSubjectChanged: context.read<PomodoroCubit>().selectSubject,
                  onFocusChanged: context
                      .read<PomodoroCubit>()
                      .updateFocusMinutes,
                  onBreakChanged: context
                      .read<PomodoroCubit>()
                      .updateBreakMinutes,
                ),
                const SizedBox(height: 20),
                _PomodoroActionsRow(state: state),
                const SizedBox(height: 24),
                _TodaySummaryCard(state: state, activeSubject: activeSubject),
                const SizedBox(height: 20),
                _TodaySessionsCard(
                  sessions: state.today?.sessions ?? const [],
                  subjects: state.subjects,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  SubjectModel? _findSubject(List<SubjectModel> subjects, String? subjectId) {
    if (subjectId == null) return null;
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }
}

class _PomodoroHeroCard extends StatelessWidget {
  const _PomodoroHeroCard({
    required this.remainingSeconds,
    required this.isRunning,
    required this.activeSubject,
    required this.hasSession,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  final int remainingSeconds;
  final bool isRunning;
  final SubjectModel? activeSubject;
  final bool hasSession;
  final int focusMinutes;
  final int breakMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timer_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasSession
                      ? (isRunning ? 'Focus in progress' : 'Session paused')
                      : 'Ready to focus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 12,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(remainingSeconds),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeSubject?.name ?? 'General focus',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroInfoChip(
                  label: 'Focus',
                  value: '$focusMinutes min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroInfoChip(
                  label: 'Break',
                  value: '$breakMinutes min',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroControlsCard extends StatelessWidget {
  const _PomodoroControlsCard({
    required this.state,
    required this.onSubjectChanged,
    required this.onFocusChanged,
    required this.onBreakChanged,
  });

  final PomodoroState state;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<double> onFocusChanged;
  final ValueChanged<double> onBreakChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = state.activeSession != null;
    final subjectItems = _buildUniqueSubjectItems(state.subjects);
    final subjectValues = subjectItems
        .map((item) => item.value)
        .whereType<String>()
        .toSet();
    final selectedSubjectId = subjectValues.contains(state.selectedSubjectId)
        ? state.selectedSubjectId
        : null;

    return Container(
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
          Text(
            'Session Setup',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: selectedSubjectId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('General Focus'),
              ),
              ...subjectItems,
            ],
            onChanged: locked ? null : onSubjectChanged,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: 'Focus minutes',
            value: state.focusMinutes,
            min: 15,
            max: 90,
            divisions: 15,
            onChanged: locked ? null : onFocusChanged,
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Break minutes',
            value: state.breakMinutes,
            min: 5,
            max: 30,
            divisions: 5,
            onChanged: locked ? null : onBreakChanged,
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String?>> _buildUniqueSubjectItems(
    List<SubjectModel> subjects,
  ) {
    final seenIds = <String>{};
    final items = <DropdownMenuItem<String?>>[];

    for (final subject in subjects) {
      if (subject.id.isEmpty || !seenIds.add(subject.id)) {
        continue;
      }
      items.add(
        DropdownMenuItem<String?>(
          value: subject.id,
          child: Text(subject.name),
        ),
      );
    }

    return items;
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final int value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '$value min',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: '$value min',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PomodoroActionsRow extends StatelessWidget {
  const _PomodoroActionsRow({required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PomodoroCubit>();

    if (state.activeSession == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: state.isSaving ? null : cubit.startSession,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Focus Session'),
        ),
      );
    }

    final isPaused = state.activeSession!.status == 'paused';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: state.isSaving
                ? null
                : (isPaused ? cubit.resumeSession : cubit.pauseSession),
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            label: Text(isPaused ? 'Resume' : 'Pause'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.isSaving ? null : cubit.completeSession,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Complete'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.isSaving ? null : cubit.abortSession,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Stop'),
          ),
        ),
      ],
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.state, required this.activeSubject});

  final PomodoroState state;
  final SubjectModel? activeSubject;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFocus = state.today?.totalFocusMinutes ?? 0;
    final completed = (state.today?.sessions ?? const [])
        .where((session) => session.status == 'completed')
        .length;

    return Container(
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
          Text(
            'Today',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TodayStat(label: 'Focus Minutes', value: '$totalFocus'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayStat(
                  label: 'Completed Sessions',
                  value: '$completed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayStat(
                  label: 'Current Subject',
                  value: (activeSubject?.name ?? '').trim().isNotEmpty
                      ? activeSubject!.name
                      : 'General',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  const _TodayStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySessionsCard extends StatelessWidget {
  const _TodaySessionsCard({required this.sessions, required this.subjects});

  final List<PomodoroSessionModel> sessions;
  final List<SubjectModel> subjects;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Text(
            'Today Sessions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            Text(
              'No sessions yet today. Start one to build momentum.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          else
            ...sessions.map((session) {
              final subject = _matchSubject(subjects, session.subjectId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject?.name ?? 'General focus',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${session.totalFocusMinutes} min - ${session.status}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
            }),
        ],
      ),
    );
  }

  SubjectModel? _matchSubject(List<SubjectModel> subjects, String? subjectId) {
    if (subjectId == null) return null;
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject;
    }
    return null;
  }
}
