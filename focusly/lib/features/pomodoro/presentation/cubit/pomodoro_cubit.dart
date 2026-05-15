import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../../data/models/pomodoro_today_model.dart';
import '../../data/repositories/pomodoro_repository.dart';

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
  Timer? _ticker;

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

      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          today: today,
          clearActiveSession: activeSession == null,
          selectedSubjectId: selectedSubjectId,
          activeSession: activeSession,
          timerPhase: activeSession != null
              ? PomodoroTimerPhase.focus
              : PomodoroTimerPhase.idle,
          remainingSeconds: _initialRemainingSeconds(activeSession),
          isRunning: activeSession?.status == 'active',
          errorMessage: null,
        ),
      );

      _restartTickerIfNeeded();
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
          errorMessage: 'Failed to load focus data: $e',
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
    emit(state.copyWith(focusMinutes: value.round()));
    if (state.activeSession == null) {
      emit(state.copyWith(remainingSeconds: value.round() * 60));
    }
  }

  void updateBreakMinutes(double value) {
    emit(state.copyWith(breakMinutes: value.round()));
  }

  Future<void> startSession() async {
    if (state.activeSession != null) return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final session = await _repository.startSession(
        subjectId: state.selectedSubjectId,
        focusMinutes: state.focusMinutes,
        breakMinutes: state.breakMinutes,
      );
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: session,
          timerPhase: PomodoroTimerPhase.focus,
          remainingSeconds: session.focusMinutes * 60,
          isRunning: true,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: 'Focus session started.',
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
            feedbackMessage: 'An active focus session was restored.',
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
          feedbackMessage: 'Failed to start session: $e',
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
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: updated,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: 'Session paused.',
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
      emit(
        state.copyWith(
          isSaving: false,
          activeSession: updated,
          isRunning: true,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: 'Session resumed.',
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
      emit(
        state.copyWith(
          isSaving: false,
          clearActiveSession: true,
          timerPhase: PomodoroTimerPhase.idle,
          remainingSeconds: state.focusMinutes * 60,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: 'Session completed successfully.',
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

  Future<void> abortSession() async {
    final session = state.activeSession;
    if (session == null) return;
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.abortSession(session.id);
      _stopTicker();
      emit(
        state.copyWith(
          isSaving: false,
          clearActiveSession: true,
          timerPhase: PomodoroTimerPhase.idle,
          remainingSeconds: state.focusMinutes * 60,
          isRunning: false,
          feedbackType: PomodoroFeedbackType.success,
          feedbackMessage: 'Session stopped.',
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

  int _initialRemainingSeconds(PomodoroSessionModel? session) {
    if (session == null) return state.focusMinutes * 60;
    return session.focusMinutes * 60;
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

  void _restartTickerIfNeeded() {
    _stopTicker();
    if (!state.isRunning || state.activeSession == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        emit(
          state.copyWith(
            remainingSeconds: 0,
            isRunning: false,
          ),
        );
        _stopTicker();
        return;
      }
      emit(state.copyWith(remainingSeconds: next));
    });
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
      return 'Something went wrong.';
    }
    return 'Something went wrong.';
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
