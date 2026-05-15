part of 'subject_detail_cubit.dart';

enum SubjectDetailFeedbackType { none, success, error }

class SubjectDetailState extends Equatable {
  const SubjectDetailState({
    this.subject,
    this.progress,
    this.chapters = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.feedbackType = SubjectDetailFeedbackType.none,
    this.feedbackMessage,
  });

  final SubjectModel? subject;
  final SubjectProgressModel? progress;
  final List<ChapterModel> chapters;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final SubjectDetailFeedbackType feedbackType;
  final String? feedbackMessage;

  SubjectDetailState copyWith({
    SubjectModel? subject,
    SubjectProgressModel? progress,
    List<ChapterModel>? chapters,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    SubjectDetailFeedbackType? feedbackType,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return SubjectDetailState(
      subject: subject ?? this.subject,
      progress: progress ?? this.progress,
      chapters: chapters ?? this.chapters,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      feedbackType: clearFeedback
          ? SubjectDetailFeedbackType.none
          : feedbackType ?? this.feedbackType,
      feedbackMessage: clearFeedback ? null : feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        subject,
        progress,
        chapters,
        isLoading,
        isSaving,
        errorMessage,
        feedbackType,
        feedbackMessage,
      ];
}
