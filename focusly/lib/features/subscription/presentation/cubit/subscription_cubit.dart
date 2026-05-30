import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';

part 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({SubscriptionRepository? repository})
      : _repository = repository ?? SubscriptionRepository(),
        super(const SubscriptionState());

  final SubscriptionRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final subscription = await _repository.getMySubscription();
      emit(
        state.copyWith(
          isLoading: false,
          subscription: subscription,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load subscription info.',
        ),
      );
    }
  }

  Future<void> payWithPaymob({required String plan}) async {
    emit(state.copyWith(isPurchasing: true, clearFeedback: true));
    try {
      final result = await _repository.createPaymobCheckout(plan: plan);
      final checkoutUrl = (result['checkoutUrl'] as String?) ?? '';
      if (checkoutUrl.isEmpty) {
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: SubscriptionFeedbackType.error,
            feedbackMessage: 'Paymob checkout URL was empty.',
          ),
        );
        return;
      }
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: launched
              ? SubscriptionFeedbackType.success
              : SubscriptionFeedbackType.error,
          feedbackMessage: launched
              ? 'Complete payment in the browser, then return and tap Refresh.'
              : 'Could not open Paymob checkout.',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: 'Could not start Paymob checkout.',
        ),
      );
    }
  }

  Future<void> payWithStripe() async {
    emit(state.copyWith(isPurchasing: true, clearFeedback: true));
    try {
      final checkoutUrl = await _repository.createStripeCheckoutSession();
      if (checkoutUrl.isEmpty) {
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: SubscriptionFeedbackType.error,
            feedbackMessage:
                'Stripe is not configured on the server. Set STRIPE keys in backend .env.',
          ),
        );
        return;
      }
      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: launched
              ? SubscriptionFeedbackType.success
              : SubscriptionFeedbackType.error,
          feedbackMessage: launched
              ? 'Complete payment in the browser, then return and tap Refresh.'
              : 'Could not open the payment page.',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: 'Could not start card checkout.',
        ),
      );
    }
  }

  Future<void> cancelSubscription() async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.cancelSubscription();
      await load();
      emit(
        state.copyWith(
          feedbackType: SubscriptionFeedbackType.success,
          feedbackMessage: 'Subscription canceled.',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}
