part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.subjects = const [],
    this.streak = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SubjectModel> subjects;
  final int streak;
  final bool isLoading;
  final String? errorMessage;

  HomeState copyWith({
    List<SubjectModel>? subjects,
    int? streak,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      subjects: subjects ?? this.subjects,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [subjects, streak, isLoading, errorMessage];
}
