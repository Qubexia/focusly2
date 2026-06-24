part of 'pomodoro_cubit.dart';

const Object _selectedSubjectSentinel = Object();

enum PomodoroFeedbackType { none, success, error }

enum PomodoroTimerPhase { idle, focus, breakTime }

class PomodoroState extends Equatable {
  const PomodoroState({
    this.subjects = const [],
    this.today,
    this.activeSession,
    this.isLoading = false,
    this.isSaving = false,
    this.isRunning = false,
    this.selectedSubjectId,
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.sessionMinutes = 120,
    this.breakMode = pomodoroBreakModeCycles,
    this.remainingSeconds = 1500,
    this.phaseTotalSeconds = 1500,
    this.sessionElapsedSeconds = 0,
    this.timerPhase = PomodoroTimerPhase.idle,
    this.errorMessage,
    this.feedbackType = PomodoroFeedbackType.none,
    this.feedbackMessage,
  });

  final List<SubjectModel> subjects;
  final PomodoroTodayModel? today;
  final PomodoroSessionModel? activeSession;
  final bool isLoading;
  final bool isSaving;
  final bool isRunning;
  final String? selectedSubjectId;
  final int focusMinutes;
  final int breakMinutes;
  final int sessionMinutes;
  final String breakMode;
  final int remainingSeconds;
  final int phaseTotalSeconds;
  final int sessionElapsedSeconds;
  final PomodoroTimerPhase timerPhase;
  final String? errorMessage;
  final PomodoroFeedbackType feedbackType;
  final String? feedbackMessage;

  PomodoroState copyWith({
    List<SubjectModel>? subjects,
    PomodoroTodayModel? today,
    PomodoroSessionModel? activeSession,
    bool clearActiveSession = false,
    bool? isLoading,
    bool? isSaving,
    bool? isRunning,
    Object? selectedSubjectId = _selectedSubjectSentinel,
    int? focusMinutes,
    int? breakMinutes,
    int? sessionMinutes,
    String? breakMode,
    int? remainingSeconds,
    int? phaseTotalSeconds,
    int? sessionElapsedSeconds,
    PomodoroTimerPhase? timerPhase,
    String? errorMessage,
    PomodoroFeedbackType? feedbackType,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return PomodoroState(
      subjects: subjects ?? this.subjects,
      today: today ?? this.today,
      activeSession: clearActiveSession
          ? null
          : activeSession ?? this.activeSession,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isRunning: isRunning ?? this.isRunning,
      selectedSubjectId: identical(
        selectedSubjectId,
        _selectedSubjectSentinel,
      )
          ? this.selectedSubjectId
          : selectedSubjectId as String?,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      breakMode: breakMode ?? this.breakMode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phaseTotalSeconds: phaseTotalSeconds ?? this.phaseTotalSeconds,
      sessionElapsedSeconds: sessionElapsedSeconds ?? this.sessionElapsedSeconds,
      timerPhase: timerPhase ?? this.timerPhase,
      errorMessage: errorMessage,
      feedbackType: clearFeedback
          ? PomodoroFeedbackType.none
          : feedbackType ?? this.feedbackType,
      feedbackMessage: clearFeedback ? null : feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        subjects,
        today,
        activeSession,
        isLoading,
        isSaving,
        isRunning,
        selectedSubjectId,
        focusMinutes,
        breakMinutes,
        sessionMinutes,
        breakMode,
        remainingSeconds,
        phaseTotalSeconds,
        sessionElapsedSeconds,
        timerPhase,
        errorMessage,
        feedbackType,
        feedbackMessage,
      ];
}
