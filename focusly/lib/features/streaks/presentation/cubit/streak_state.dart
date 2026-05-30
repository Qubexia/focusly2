import 'package:equatable/equatable.dart';

import '../../data/models/streak_model.dart';

class StreakState extends Equatable {
  const StreakState({
    this.streak,
    this.isLoading = false,
    this.errorMessage,
  });

  final StreakModel? streak;
  final bool isLoading;
  final String? errorMessage;

  int get current => streak?.current ?? 0;

  StreakState copyWith({
    StreakModel? streak,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StreakState(
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [streak, isLoading, errorMessage];
}
