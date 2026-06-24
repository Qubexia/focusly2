import 'package:equatable/equatable.dart';
import '../../data/models/schedule_model.dart';

enum SchedulesFeedbackType { none, success, error }

class SchedulesState extends Equatable {
  const SchedulesState({
    required this.focusedDay,
    this.schedules = const [],
    this.completedKeys = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.feedbackType = SchedulesFeedbackType.none,
    this.feedbackMessage,
  });

  final DateTime focusedDay;
  final List<StudyScheduleModel> schedules;

  /// Completed occurrences as `scheduleId|YYYY-MM-DD` keys.
  final Set<String> completedKeys;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final SchedulesFeedbackType feedbackType;
  final String? feedbackMessage;

  SchedulesState copyWith({
    DateTime? focusedDay,
    List<StudyScheduleModel>? schedules,
    Set<String>? completedKeys,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    SchedulesFeedbackType? feedbackType,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return SchedulesState(
      focusedDay: focusedDay ?? this.focusedDay,
      schedules: schedules ?? this.schedules,
      completedKeys: completedKeys ?? this.completedKeys,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackType:
          clearFeedback ? SchedulesFeedbackType.none : (feedbackType ?? this.feedbackType),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        focusedDay,
        schedules,
        completedKeys,
        isLoading,
        isSaving,
        errorMessage,
        feedbackType,
        feedbackMessage,
      ];
}
