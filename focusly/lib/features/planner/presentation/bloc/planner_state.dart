part of 'planner_cubit.dart';

enum PlannerFeedbackType { none, success, error }

class PlannerState extends Equatable {
  const PlannerState({
    required this.selectedDate,
    this.tasks = const [],
    this.revisions = const [],
    this.lectures = const [],
    this.exams = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.feedbackType = PlannerFeedbackType.none,
    this.feedbackMessage,
  });

  final DateTime selectedDate;
  final List<PlannedItemModel> tasks;
  final List<PlannedItemModel> revisions;
  final List<PlannedItemModel> lectures;
  final List<PlannedItemModel> exams;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final PlannerFeedbackType feedbackType;
  final String? feedbackMessage;

  PlannerState copyWith({
    DateTime? selectedDate,
    List<PlannedItemModel>? tasks,
    List<PlannedItemModel>? revisions,
    List<PlannedItemModel>? lectures,
    List<PlannedItemModel>? exams,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    PlannerFeedbackType? feedbackType,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return PlannerState(
      selectedDate: selectedDate ?? this.selectedDate,
      tasks: tasks ?? this.tasks,
      revisions: revisions ?? this.revisions,
      lectures: lectures ?? this.lectures,
      exams: exams ?? this.exams,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackType: clearFeedback ? PlannerFeedbackType.none : (feedbackType ?? this.feedbackType),
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        selectedDate,
        tasks,
        revisions,
        lectures,
        exams,
        isLoading,
        isSaving,
        errorMessage,
        feedbackType,
        feedbackMessage,
      ];
}
