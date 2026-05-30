part of 'subscription_cubit.dart';

enum SubscriptionFeedbackType { none, success, error }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.subscription,
    this.isLoading = false,
    this.isPurchasing = false,
    this.feedbackType = SubscriptionFeedbackType.none,
    this.feedbackMessage,
    this.errorMessage,
  });

  final SubscriptionModel? subscription;
  final bool isLoading;
  final bool isPurchasing;
  final SubscriptionFeedbackType feedbackType;
  final String? feedbackMessage;
  final String? errorMessage;

  SubscriptionState copyWith({
    SubscriptionModel? subscription,
    bool? isLoading,
    bool? isPurchasing,
    SubscriptionFeedbackType? feedbackType,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      feedbackType:
          clearFeedback ? SubscriptionFeedbackType.none : (feedbackType ?? this.feedbackType),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        subscription,
        isLoading,
        isPurchasing,
        feedbackType,
        feedbackMessage,
        errorMessage,
      ];
}
