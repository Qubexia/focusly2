part of 'subjects_cubit.dart';

enum SubjectsFeedbackType { none, success, error, premiumGate }

class SubjectsState extends Equatable {
  const SubjectsState({
    this.subjects = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.feedbackType = SubjectsFeedbackType.none,
    this.feedbackMessage,
  });

  final List<SubjectModel> subjects;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final SubjectsFeedbackType feedbackType;
  final String? feedbackMessage;

  SubjectsState copyWith({
    List<SubjectModel>? subjects,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    SubjectsFeedbackType? feedbackType,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      feedbackType: clearFeedback
          ? SubjectsFeedbackType.none
          : feedbackType ?? this.feedbackType,
      feedbackMessage: clearFeedback ? null : feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
    subjects,
    isLoading,
    isSaving,
    errorMessage,
    feedbackType,
    feedbackMessage,
  ];
}
