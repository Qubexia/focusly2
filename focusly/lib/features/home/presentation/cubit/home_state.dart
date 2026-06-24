part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.subjects = const [],
    this.pomodoroToday,
    this.todaySchedules = const [],
    this.todayTasks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SubjectModel> subjects;
  final PomodoroTodayModel? pomodoroToday;
  final List<StudyScheduleModel> todaySchedules;
  final List<PlannedItemModel> todayTasks;
  final bool isLoading;
  final String? errorMessage;

  int get todayFocusMinutes => pomodoroToday?.totalFocusMinutes ?? 0;

  // Only count finished sessions — canceled/aborted (and still-running) ones
  // must not inflate the daily sessions tally.
  int get todaySessionCount =>
      pomodoroToday?.sessions
          .where((s) => s.status == 'completed')
          .length ??
      0;

  HomeState copyWith({
    List<SubjectModel>? subjects,
    PomodoroTodayModel? pomodoroToday,
    List<StudyScheduleModel>? todaySchedules,
    List<PlannedItemModel>? todayTasks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      subjects: subjects ?? this.subjects,
      pomodoroToday: pomodoroToday ?? this.pomodoroToday,
      todaySchedules: todaySchedules ?? this.todaySchedules,
      todayTasks: todayTasks ?? this.todayTasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        subjects,
        pomodoroToday,
        todaySchedules,
        todayTasks,
        isLoading,
        errorMessage,
      ];
}
