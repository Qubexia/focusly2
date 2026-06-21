import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../cubit/pomodoro_cubit.dart';

const _breakColor = Color(0xFF00C896);

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.read<PomodoroCubit>().clearFeedback();
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activeSubject = _findSubject(
          state.subjects,
          state.activeSession?.subjectId ?? state.selectedSubjectId,
        );
        final accentColor = state.timerPhase == PomodoroTimerPhase.breakTime
            ? _breakColor
            : AppColors.primary;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : const Color(0xFFF4F6FB),
          body: SafeArea(
            child: RefreshIndicator(
              color: accentColor,
              onRefresh: () => context.read<PomodoroCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                children: [
                  _HeaderRow(accentColor: accentColor, isDark: isDark),
                  const SizedBox(height: 28),
                  _TimerSection(
                    state: state,
                    activeSubject: activeSubject,
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),
                  _ActionButtons(state: state, accentColor: accentColor),
                  const SizedBox(height: 24),
                  _SessionSetupCard(
                    state: state,
                    accentColor: accentColor,
                    isDark: isDark,
                    onSubjectChanged:
                        context.read<PomodoroCubit>().selectSubject,
                    onFocusChanged:
                        context.read<PomodoroCubit>().updateFocusMinutes,
                    onBreakChanged:
                        context.read<PomodoroCubit>().updateBreakMinutes,
                  ),
                  const SizedBox(height: 20),
                  _TodayStatsRow(
                    state: state,
                    activeSubject: activeSubject,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _TodaySessionsList(
                    sessions: state.today?.sessions ?? const [],
                    subjects: state.subjects,
                    isDark: isDark,
                  ),
                ],
              ),
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

// ─────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.accentColor, required this.isDark});

  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.pomodoroFocusTimer,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
        ),
        GestureDetector(
          onTap: () => context.push('/pomodoro/history'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.history_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Timer Ring
// ─────────────────────────────────────────────────────

class _TimerSection extends StatelessWidget {
  const _TimerSection({
    required this.state,
    required this.activeSubject,
    required this.accentColor,
    required this.isDark,
  });

  final PomodoroState state;
  final SubjectModel? activeSubject;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalSeconds = state.timerPhase == PomodoroTimerPhase.breakTime
        ? state.breakMinutes * 60
        : state.focusMinutes * 60;

    final progress = totalSeconds > 0
        ? (1.0 - (state.remainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    final phaseLabel = switch (state.timerPhase) {
      PomodoroTimerPhase.focus => l10n.pomodoroPhaseFocus,
      PomodoroTimerPhase.breakTime => l10n.pomodoroPhaseBreak,
      PomodoroTimerPhase.idle => l10n.pomodoroPhaseReady,
    };

    return Column(
      children: [
        // Phase badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: state.isRunning
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                phaseLabel,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Ring
        SizedBox(
          width: 230,
          height: 230,
          child: CustomPaint(
            painter: _TimerRingPainter(
              progress: progress,
              accentColor: accentColor,
              isDark: isDark,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(state.remainingSeconds),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeSubject?.name ?? l10n.pomodoroGeneralFocus,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Focus / Break info chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PhaseChip(
              label: l10n.pomodoroFocus,
              value: l10n.pomodoroMinutesShort(state.focusMinutes),
              isActive: state.timerPhase == PomodoroTimerPhase.focus,
              accentColor: AppColors.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _PhaseChip(
              label: l10n.pomodoroBreak,
              value: l10n.pomodoroMinutesShort(state.breakMinutes),
              isActive: state.timerPhase == PomodoroTimerPhase.breakTime,
              accentColor: _breakColor,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  static String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.accentColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isActive;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? accentColor.withValues(alpha: 0.12)
            : isDark
                ? AppColors.surfaceDark
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.4)
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isActive
                  ? accentColor
                  : isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Ring Painter
// ─────────────────────────────────────────────────────

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({
    required this.progress,
    required this.accentColor,
    required this.isDark,
  });

  final double progress;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    // Track ring
    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc
    final sweepAngle = 2 * pi * progress;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: [
          accentColor.withValues(alpha: 0.65),
          accentColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot at arc end
    final endAngle = -pi / 2 + sweepAngle;
    final dotPos = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );

    canvas.drawCircle(
      dotPos,
      9,
      Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dotPos,
      6,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dotPos,
      3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress ||
      old.accentColor != accentColor ||
      old.isDark != isDark;
}

// ─────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state, required this.accentColor});

  final PomodoroState state;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PomodoroCubit>();

    if (state.activeSession == null) {
      return Center(
        child: _PrimaryBtn(
          label: l10n.pomodoroStartSession,
          icon: Icons.play_arrow_rounded,
          accentColor: accentColor,
          onTap: state.isSaving ? null : cubit.startSession,
        ),
      );
    }

    final isPaused = state.activeSession!.status == 'paused';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SecondaryBtn(
          icon: Icons.close_rounded,
          label: l10n.pomodoroStop,
          onTap: state.isSaving ? null : cubit.abortSession,
        ),
        const SizedBox(width: 12),
        _PrimaryBtn(
          label: isPaused ? l10n.pomodoroResume : l10n.pomodoroPause,
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          accentColor: accentColor,
          compact: true,
          onTap: state.isSaving
              ? null
              : (isPaused ? cubit.resumeSession : cubit.pauseSession),
        ),
        const SizedBox(width: 12),
        _SecondaryBtn(
          icon: Icons.check_rounded,
          label: l10n.commonDone,
          onTap: state.isSaving ? null : cubit.completeSession,
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 22 : 36,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [Colors.grey.shade400, Colors.grey.shade300]
                : [
                    accentColor,
                    Color.lerp(accentColor, Colors.black, 0.18)!,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: disabled
                  ? Colors.grey.shade400
                  : isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: disabled
                    ? Colors.grey.shade400
                    : isDark
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

// ─────────────────────────────────────────────────────
// Session Setup Card
// ─────────────────────────────────────────────────────

class _SessionSetupCard extends StatelessWidget {
  const _SessionSetupCard({
    required this.state,
    required this.accentColor,
    required this.isDark,
    required this.onSubjectChanged,
    required this.onFocusChanged,
    required this.onBreakChanged,
  });

  final PomodoroState state;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<double> onFocusChanged;
  final ValueChanged<double> onBreakChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = state.activeSession != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                l10n.pomodoroSessionSetup,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (locked) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.pomodoroLocked,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pomodoroSubject,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          _SubjectChips(
            state: state,
            locked: locked,
            accentColor: accentColor,
            isDark: isDark,
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeStepper(
                  label: l10n.pomodoroFocus,
                  icon: Icons.timer_outlined,
                  value: state.focusMinutes,
                  min: 15,
                  max: 90,
                  step: 5,
                  locked: locked,
                  accentColor: AppColors.primary,
                  isDark: isDark,
                  onChanged: (v) => onFocusChanged(v.toDouble()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeStepper(
                  label: l10n.pomodoroBreak,
                  icon: Icons.coffee_outlined,
                  value: state.breakMinutes,
                  min: 5,
                  max: 30,
                  step: 5,
                  locked: locked,
                  accentColor: _breakColor,
                  isDark: isDark,
                  onChanged: (v) => onBreakChanged(v.toDouble()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectChips extends StatelessWidget {
  const _SubjectChips({
    required this.state,
    required this.locked,
    required this.accentColor,
    required this.isDark,
    required this.onChanged,
  });

  final PomodoroState state;
  final bool locked;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  List<SubjectModel> _uniqueSubjects() {
    final seen = <String>{};
    return state.subjects
        .where((s) => s.id.isNotEmpty && seen.add(s.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subjects = _uniqueSubjects();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SubjectChip(
            label: l10n.pomodoroGeneral,
            isSelected: state.selectedSubjectId == null,
            accentColor: accentColor,
            isDark: isDark,
            onTap: locked ? null : () => onChanged(null),
          ),
          ...subjects.map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SubjectChip(
                label: s.name,
                isSelected: state.selectedSubjectId == s.id,
                accentColor: accentColor,
                isDark: isDark,
                onTap: locked ? null : () => onChanged(s.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor
              : isDark
                  ? AppColors.cardDark
                  : const Color(0xFFF0F2F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.locked,
    required this.accentColor,
    required this.isDark,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool locked;
  final Color accentColor;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                enabled: !locked && value > min,
                isDark: isDark,
                onTap: () => onChanged(value - step),
              ),
              Flexible(
                child: Text(
                  l10n.pomodoroMinutesUnit(value),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add_rounded,
                enabled: !locked && value < max,
                isDark: isDark,
                onTap: () => onChanged(value + step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Today Stats Row
// ─────────────────────────────────────────────────────

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({
    required this.state,
    required this.activeSubject,
    required this.isDark,
  });

  final PomodoroState state;
  final SubjectModel? activeSubject;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalFocus = state.today?.totalFocusMinutes ?? 0;
    final sessions = state.today?.sessions ?? const [];
    final completed = sessions.where((s) => s.status == 'completed').length;
    final subjectName = activeSubject?.name ?? l10n.pomodoroGeneral;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: l10n.pomodoroFocusTime,
            value: l10n.pomodoroMinutesShort(totalFocus),
            icon: Icons.timer_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: l10n.pomodoroSessions,
            value: '$completed',
            icon: Icons.check_circle_outline_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: l10n.pomodoroSubject,
            value: subjectName,
            icon: Icons.book_outlined,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Today Sessions List
// ─────────────────────────────────────────────────────

class _TodaySessionsList extends StatelessWidget {
  const _TodaySessionsList({
    required this.sessions,
    required this.subjects,
    required this.isDark,
  });

  final List<PomodoroSessionModel> sessions;
  final List<SubjectModel> subjects;
  final bool isDark;

  SubjectModel? _matchSubject(String? subjectId) {
    if (subjectId == null) return null;
    for (final s in subjects) {
      if (s.id == subjectId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pomodoroTodaysSessions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (sessions.isNotEmpty)
                Text(
                  l10n.pomodoroSessionsTotal(sessions.length),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer_off_outlined,
                      size: 36,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.pomodoroNoSessionsToday,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sessions.asMap().entries.map((entry) {
              final i = entry.key;
              final session = entry.value;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i < sessions.length - 1 ? 12 : 0),
                child: _SessionTile(
                  session: session,
                  subject: _matchSubject(session.subjectId),
                  isDark: isDark,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.subject,
    required this.isDark,
  });

  final PomodoroSessionModel session;
  final SubjectModel? subject;
  final bool isDark;

  Color get _statusColor => switch (session.status) {
        'completed' => _breakColor,
        'aborted' => const Color(0xFFFF5252),
        _ => AppColors.primary,
      };

  IconData get _statusIcon => switch (session.status) {
        'completed' => Icons.check_circle_rounded,
        'aborted' => Icons.cancel_rounded,
        _ => Icons.pause_circle_rounded,
      };

  String _statusLabel(AppLocalizations l10n) {
    switch (session.status) {
      case 'completed':
        return l10n.pomodoroStatusCompleted;
      case 'aborted':
        return l10n.pomodoroStatusAborted;
      case 'paused':
        return l10n.pomodoroStatusPaused;
      case 'active':
        return l10n.pomodoroStatusActive;
    }
    final s = session.status;
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_statusIcon, size: 20, color: _statusColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject?.name ?? l10n.pomodoroGeneralFocus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.pomodoroSessionMinutesStatus(
                  session.totalFocusMinutes,
                  _statusLabel(l10n),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _statusColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
