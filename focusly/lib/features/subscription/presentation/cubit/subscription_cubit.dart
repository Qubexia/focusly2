import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paymob/paymob.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/premium/premium_status.dart';
import '../../../../core/services/premium_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
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
      emit(state.copyWith(isLoading: false, subscription: subscription));
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
      final checkout = await _repository.createPaymobCheckout(plan: plan);
      final publicKey = (checkout['publicKey'] as String?)?.trim() ?? '';
      final clientSecret = (checkout['clientSecret'] as String?)?.trim() ?? '';
      final canUseNativeSdk =
          checkout['canUseNativeSdk'] == true ||
          clientSecret.startsWith('egy_csk_') ||
          clientSecret.startsWith('csk_');

      if (publicKey.isEmpty || clientSecret.isEmpty) {
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: SubscriptionFeedbackType.error,
            feedbackMessage: 'Paymob SDK session data is incomplete.',
          ),
        );
        return;
      }

      if (!canUseNativeSdk) {
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: SubscriptionFeedbackType.error,
            feedbackMessage:
                'Paymob is still configured with a legacy integration on the server. '
                'To use the in-app Flutter SDK, switch PAYMOB_INTEGRATION_ID to an Online Card '
                '(MIGS) integration that returns a client secret from Intention API.',
          ),
        );
        return;
      }

      final result = await Paymob.pay(
        publicKey: publicKey,
        clientSecret: clientSecret,
        appName: 'Zakerly',
        buttonBackgroundColor: AppColors.premium,
        buttonTextColor: Colors.white,
        saveCardDefault: false,
        showSaveCard: true,
      );

      final status = result.status;
      final isSuccess = result.isSuccessful;
      final isPending = status == PaymobTransactionStatus.pending;
      final isRejected = status == PaymobTransactionStatus.rejected;
      final message = result.errorMessage?.trim();

      if (isSuccess || isPending) {
        if (isSuccess) {
          try {
            await _repository.confirmPaymobSdk(
              plan: plan,
              transactionId: extractPaymobTransactionId(
                result.transactionDetails,
              ),
            );
            await PremiumRefreshService.instance.refreshSessionTokens();
          } catch (_) {
            // Webhook may still activate premium; continue syncing below.
          }
        }
        await load();
      }

      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: (isSuccess || isPending)
              ? SubscriptionFeedbackType.success
              : SubscriptionFeedbackType.error,
          feedbackMessage: isSuccess
              ? 'Payment completed successfully.'
              : isPending
              ? 'Payment submitted and is pending confirmation.'
              : isRejected
              ? (message?.isNotEmpty == true
                    ? message!
                    : 'Payment was rejected.')
              : (message?.isNotEmpty == true
                    ? message!
                    : 'Could not complete Paymob payment.'),
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      final result = await _repository.cancelSubscription();
      await load();
      final serverMessage = (result['message'] as String?)?.trim();
      emit(
        state.copyWith(
          isLoading: false,
          feedbackType: SubscriptionFeedbackType.cancelSuccess,
          feedbackMessage: serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'Subscription canceled. Premium access has ended.',
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
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: 'Could not cancel subscription.',
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
