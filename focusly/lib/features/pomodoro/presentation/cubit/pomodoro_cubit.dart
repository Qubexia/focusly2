import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../../data/models/pomodoro_today_model.dart';
import '../../data/repositories/pomodoro_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/schedule_focus_bus.dart';
import '../../../../core/localization/app_l10n.dart';
import '../../../schedules/data/datasources/schedules_remote_datasource.dart';
import 'pomodoro_schedule.dart';

part 'pomodoro_state.dart';

class PomodoroCubit extends Cubit<PomodoroState> {
  PomodoroCubit({
    PomodoroRepository? repository,
    SubjectsRepository? subjectsRepository,
  })  : _repository = repository ?? PomodoroRepository(),
        _subjectsRepository = subjectsRepository ?? SubjectsRepository(),
        super(const PomodoroState());

  final PomodoroRepository _repository;
  final SubjectsRepository _subjectsRepository;
  final NotificationService _notificationService = NotificationService();
  final SchedulesRemoteDataSource _schedulesDataSource =
      SchedulesRemoteDataSource();
  Timer? _ticker;

  // When the focus session was launched from a study-schedule row, these link it
  // back so the row gets marked complete once the session finishes.
  String? _linkedScheduleId;
  String? _linkedScheduleDate;

  // Wall-clock anchoring so the countdown survives the screen locking or the app
  // being backgrounded: instead of decrementing a counter every second (which
  // freezes when the OS suspends our timer), we re-derive elapsed time from these
  // anchors against the real clock on every tick and on app resume.
  double _elapsedBaseSeconds = 0; // active seconds banked before the current run
  int? _runningSinceMs; // epoch ms the current running stretch began (null=paused)
  bool _lastIsBreak = false; // last emitted phase, to detect break/focus changes
  bool _autoCompleting = false; // guards the auto-complete at the session's end

  int _currentElapsedSeconds() {
    final base = _elapsedBaseSeconds;
    final since = _runningSinceMs;
    if (since == null) return base.floor();
    final runningSeconds =
        (DateTime.now().millisecondsSinceEpoch - since) / 1000.0;
    return (base + runningSeconds).floor().clamp(0, 1 << 31);
  }

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      final subjects = await _subjectsRepository.getSubjects();
      PomodoroTodayModel today = const PomodoroTodayModel(
        sessions: [],
        totalFocusMinutes: 0,
      );

      try {
        today = await _repository.getToday();
      } on DioException catch (_) {
        // Keep the Focus page usable even if today's sessions fail to load.
      } catch (_) {
        // Keep the Focus page usable even if today's sessions fail to load.
      }

      final subjectIds = subjects.map((subject) => subject.id).toSet();
      final activeSession = today.activeSession ?? _extractActiveSession(today.sessions);
      final selectedSubjectId = _resolveSelectedSubjectId(
        currentSelectedSubjectId: state.selectedSubjectId,
        activeSubjectId: activeSession?.subjectId,
        subjectIds: subjectIds,
      );

      if (activeSession == null) {
        _resetAnchors(running: false);
        _stopTicker();
        emit(
          state.copyWith(
            isLoading: false,
            subjects: subjects,
            today: today,
            clearActiveSession: true,
            selectedSubjectId: selectedSubjectId,
            timerPhase: PomodoroTimerPhase.idle,
            remainingSeconds: state.focusMinutes * 60,
            phaseTotalSeconds: state.focusMinutes * 60,
            sessionElapsedSeconds: 0,
            isRunning: false,
            errorMessage: null,
          ),
        );
        return;
      }

      // Re-anchor the running session against the real clock so the countdown is
      // accurate even after the app was suspended (screen locked / backgrounded).
      final isActive = activeSession.status == 'active';
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final anchorMs = isActive
          ? activeSession.startedAt.millisecondsSinceEpoch
          : activeSession.lastTickAt.millisecondsSinceEpoch;
      final elapsed = (nowMs - anchorMs) / 1000.0;
      _elapsedBaseSeconds = elapsed < 0 ? 0 : elapsed;
      _runningSinceMs = isActive ? nowMs : null;
      _autoCompleting = false;

      final tick = computePomodoroTick(
        elapsedSeconds: _currentElapsedSeconds(),
        focusMinutes: activeSession.focusMinutes,
        breakMinutes: activeSession.breakMinutes,
        sessionMinutes: activeSession.sessionMinutes,
        breakMode: activeSession.breakMode,
      );
      _lastIsBreak = tick.isBreak;

      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          today: today,
          selectedSubjectId: selectedSubjectId,
          activeSession: activeSession,
          focusMinutes: activeSession.focusMinutes,
          breakMinutes: activeSession.breakMinutes,
          sessionMinutes: activeSession.sessionMinutes,
          breakMode: activeSession.breakMode,
          timerPhase: tick.isBreak
              ? PomodoroTimerPhase.breakTime
              : PomodoroTimerPhase.focus,
          remainingSeconds: tick.remainingSeconds,
          phaseTotalSeconds: tick.phaseTotalSeconds,
          sessionElapsedSeconds: tick.sessionElapsedSeconds,
          isRunning: isActive && !tick.isDone,
          errorMessage: null,
        ),
      );

      if (isActive && tick.isDone) {
        _handleSessionDone();
      } else {
        _restartTickerIfNeeded();
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _extractMessage(e),
          feedbackMessage: null,
          feedbackType: PomodoroFeedbackType.error,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppL10n.current.pomodoroLoadFailed,
          feedbackMessage: null,
          feedbackType: PomodoroFeedbackType.error,
        ),
      );
    }
  }

  void selectSubject(String? subjectId) {
    final subjectIds = state.subjects.map((subject) => subject.id).toSet();
    emit(
      state.copyWith(
        selectedSubjectId: subjectIds.contains(subjectId) ? subjectId : null,
      ),
    );
  }

  void updateFocusMinutes(double value) {
    if (state.activeSession != null) return;
    final focus = value.round();
    // A session can never be shorter than a single focus block.
    final session =
        state.sessionMinutes < focus ? focus : state.sessionMinutes;
    emit(
      state.copyWith(
        focusMinutes: focus,
        sessionMinutes: session,
        remainingSeconds: focus * 60,
        phaseTotalSeconds: focus * 60,
      ),
    );
  }

  void updateBreakMinutes(double value) {
    if (state.activeSession != null) return;
    emit(state.copyWith(breakMinutes: value.round()));
  }

  void updateSessionMinutes(double value) {
    if (state.activeSession != null) return;
    final session = value.round();
    emit(
      state.copyWith(
        sessionMinutes:
            session < state.focusMinutes ? state.focusMinutes : session,
      ),
    );
  }

  /// Switches between the repeating-cycles layout and a single mid-session break.
  void updateBreakMode(String mode) {
    if (state.activeSession != null) return;
    if (mode != pomodoroBreakModeCycles && mode != pomodoroBreakModeMiddle) {
      return;
    }
    emit(state.copyWith(breakMode: mode));
  }

  /// Pre-configures the timer for a study-schedule occurrence the user tapped,
  /// and links it so completing the session marks that occurrence done.
  void applyScheduleLaunch(ScheduleFocusLaunch launch) {
    _linkedScheduleId = launch.scheduleId;
    _linkedScheduleDate = launch.date;

    // Don't reconfigure a session that is already running; just keep the link.
    if (state.activeSession != null) return;

    final session = launch.sessionMinutes < state.focusMinutes
        ? state.focusMinutes
        : launch.sessionMinutes;
    emit(
      state.copyWith(
        selectedSubjectId: launch.subjectId,
        sessionMinutes: session,
      ),
    );
  }

  Future<void> _markLinkedScheduleDone() async {
    final id = _linkedScheduleId;
    final date = _linkedScheduleDate;
    if (id == null || date == null) return;
    _linkedScheduleId = null;
    _linkedScheduleDate = null;
    try {
      await _schedulesDataSource.completeSchedule(id: id, date: date);
      ScheduleFocusBus.instance.markCompleted(ScheduleCompletion(id, date));
    } catch (_) {
      // Marking the schedule is best-effort; never fail the focus completion.
    }
  }

  Future<void> startSession() async {
    if (state.activeSession != null) return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final session = await _repository.startSession(
        subjectId: state.selectedSubjectId,
        focusMinutes: state.focusMinutes,
        breakMinutes: state.breakMinutes,
        sessionMinutes: state.sessionMinutes,
        breakMode: state.breakMode,
      );
      _resetAnchors(running: true);
      final tick = computePomodoroTick(
        elapsedSeconds: 0,
        focusMinutes: session.focusMinutes,
        breakMinutes: session.breakMinutes,
        sessionMinutes: session.sessionMinutes,
        breakMode: session.breakMode,
      );
      _lastIsBreak = tick.isBreak;
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: session,
          breakMode: session.breakMode,
          timerPhase: PomodoroTimerPhase.focus,
          remainingSeconds: tick.remainingSeconds,
          phaseTotalSeconds: tick.phaseTotalSeconds,
          sessionElapsedSeconds: 0,
          isRunning: true,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: AppL10n.current.pomodoroSessionStarted,
        ),
      );
      await _refreshTodaySafely();
      _restartTickerIfNeeded();
    } on DioException catch (e) {
      final code = _extractCode(e);
      if (code == 'POMODORO_ALREADY_ACTIVE') {
        await load();
        emit(
          state.copyWith(
            isSaving: false,
            feedbackType: PomodoroFeedbackType.success,
            feedbackMessage: AppL10n.current.pomodoroSessionRestored,
          ),
        );
        _restartTickerIfNeeded();
        return;
      }
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: AppL10n.current.pomodoroStartFailed,
        ),
      );
    }
  }

  Future<void> pauseSession() async {
    final session = state.activeSession;
    if (session == null || session.status != 'active') return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.pauseSession(session.id);
      _stopTicker();
      // Bank the elapsed active time and stop the clock so paused time is not
      // counted toward the countdown.
      _elapsedBaseSeconds = _currentElapsedSeconds().toDouble();
      _runningSinceMs = null;
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: updated,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: AppL10n.current.pomodoroSessionPaused,
        ),
      );
      await _refreshTodaySafely();
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<void> resumeSession() async {
    final session = state.activeSession;
    if (session == null || session.status != 'paused') return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.resumeSession(session.id);
      // Restart the wall clock from now; banked elapsed time is preserved.
      _runningSinceMs = DateTime.now().millisecondsSinceEpoch;
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: updated,
          isRunning: true,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: AppL10n.current.pomodoroSessionResumed,
        ),
      );
      await _refreshTodaySafely();
      _restartTickerIfNeeded();
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<void> completeSession() async {
    final session = state.activeSession;
    if (session == null) return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.completeSession(session.id);
      _stopTicker();
      _resetAnchors(running: false);
      emit(
        state.copyWith(
          isSaving: false,
          clearActiveSession: true,
          timerPhase: PomodoroTimerPhase.idle,
          remainingSeconds: state.focusMinutes * 60,
          phaseTotalSeconds: state.focusMinutes * 60,
          sessionElapsedSeconds: 0,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: AppL10n.current.pomodoroSessionCompleted,
        ),
      );
      await _markLinkedScheduleDone();
      await _refreshTodaySafely();
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    }
  }

  Future<void> abortSession() async {
    final session = state.activeSession;
    if (session == null) return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.abortSession(session.id);
      _stopTicker();
      _resetAnchors(running: false);
      // Aborting does not count toward the schedule; drop any link.
      _linkedScheduleId = null;
      _linkedScheduleDate = null;
      emit(
        state.copyWith(
          isSaving: false,
          clearActiveSession: true,
          timerPhase: PomodoroTimerPhase.idle,
          remainingSeconds: state.focusMinutes * 60,
          phaseTotalSeconds: state.focusMinutes * 60,
          sessionElapsedSeconds: 0,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: AppL10n.current.pomodoroSessionStopped,
        ),
      );
      await _refreshTodaySafely();
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: PomodoroFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> _refreshToday() async {
    final today = await _repository.getToday();
    final activeSession = today.activeSession ?? _extractActiveSession(today.sessions);
    final subjectIds = state.subjects.map((subject) => subject.id).toSet();
    emit(
      state.copyWith(
        today: today,
        selectedSubjectId: _resolveSelectedSubjectId(
          currentSelectedSubjectId: state.selectedSubjectId,
          activeSubjectId: activeSession?.subjectId,
          subjectIds: subjectIds,
        ),
        activeSession: activeSession ?? state.activeSession,
        clearActiveSession: activeSession == null && state.activeSession == null,
        isRunning: activeSession?.status == 'active',
      ),
    );
  }

  Future<void> _refreshTodaySafely() async {
    try {
      await _refreshToday();
    } catch (_) {
      // Keep the mutation successful even if the follow-up refresh fails.
    }
  }

  PomodoroSessionModel? _extractActiveSession(
    List<PomodoroSessionModel> sessions,
  ) {
    for (final session in sessions) {
      if (session.status == 'active' || session.status == 'paused') {
        return session;
      }
    }
    return null;
  }

  String? _resolveSelectedSubjectId({
    required String? currentSelectedSubjectId,
    required String? activeSubjectId,
    required Set<String> subjectIds,
  }) {
    if (currentSelectedSubjectId != null &&
        subjectIds.contains(currentSelectedSubjectId)) {
      return currentSelectedSubjectId;
    }
    if (activeSubjectId != null && subjectIds.contains(activeSubjectId)) {
      return activeSubjectId;
    }
    return null;
  }

  void _resetAnchors({required bool running}) {
    _elapsedBaseSeconds = 0;
    _runningSinceMs = running ? DateTime.now().millisecondsSinceEpoch : null;
    _lastIsBreak = false;
    _autoCompleting = false;
  }

  void _restartTickerIfNeeded() {
    _stopTicker();
    if (!state.isRunning || state.activeSession == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  /// Recomputes the countdown from the wall clock. Safe to call on every timer
  /// tick and when the app returns to the foreground.
  void refreshTick() {
    if (state.activeSession == null || !state.isRunning) return;
    _onTick();
  }

  void _onTick() {
    if (state.activeSession == null) return;
    final tick = computePomodoroTick(
      elapsedSeconds: _currentElapsedSeconds(),
      focusMinutes: state.focusMinutes,
      breakMinutes: state.breakMinutes,
      sessionMinutes: state.sessionMinutes,
      breakMode: state.breakMode,
    );

    if (tick.isDone) {
      emit(
        state.copyWith(
          remainingSeconds: 0,
          phaseTotalSeconds: tick.phaseTotalSeconds,
          sessionElapsedSeconds: tick.sessionTotalSeconds,
          isRunning: false,
        ),
      );
      _handleSessionDone();
      return;
    }

    // Announce focus↔break transitions as they happen.
    if (tick.isBreak != _lastIsBreak) {
      _lastIsBreak = tick.isBreak;
      _notificationService.showNotification(
        title: tick.isBreak
            ? AppL10n.current.pomodoroBreakStartTitle
            : AppL10n.current.pomodoroFocusStartTitle,
        body: tick.isBreak
            ? AppL10n.current.pomodoroBreakStartBody
            : AppL10n.current.pomodoroFocusStartBody,
      );
    }

    emit(
      state.copyWith(
        remainingSeconds: tick.remainingSeconds,
        phaseTotalSeconds: tick.phaseTotalSeconds,
        sessionElapsedSeconds: tick.sessionElapsedSeconds,
        timerPhase: tick.isBreak
            ? PomodoroTimerPhase.breakTime
            : PomodoroTimerPhase.focus,
      ),
    );
  }

  void _handleSessionDone() {
    _stopTicker();
    if (_autoCompleting) return;
    _autoCompleting = true;
    _notificationService.showNotification(
      title: AppL10n.current.pomodoroSessionDoneTitle,
      body: AppL10n.current.pomodoroSessionDoneBody,
    );
    completeSession();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
      return AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }

  String? _extractCode(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code'] as String?;
    }
    return null;
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
