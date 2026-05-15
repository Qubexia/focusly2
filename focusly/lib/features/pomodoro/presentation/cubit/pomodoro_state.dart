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
    this.remainingSeconds = 1500,
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
  final int remainingSeconds;
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
    int? remainingSeconds,
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
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
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
        remainingSeconds,
        timerPhase,
        errorMessage,
        feedbackType,
        feedbackMessage,
      ];
}
