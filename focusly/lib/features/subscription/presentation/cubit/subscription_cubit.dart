import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paymob/paymob.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_l10n.dart';
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
          errorMessage: AppL10n.current.subscriptionLoadFailed,
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
            feedbackMessage: AppL10n.current.subscriptionPaymobSessionIncomplete,
          ),
        );
        return;
      }

      if (!canUseNativeSdk) {
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: SubscriptionFeedbackType.error,
            feedbackMessage: AppL10n.current.subscriptionPaymobUnavailable,
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
              ? AppL10n.current.subscriptionPaymentCompleted
              : isPending
              ? AppL10n.current.subscriptionPaymentPending
              : isRejected
              ? (message?.isNotEmpty == true
                    ? message!
                    : AppL10n.current.subscriptionPaymentRejected)
              : (message?.isNotEmpty == true
                    ? message!
                    : AppL10n.current.subscriptionPaymentFailed),
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
          feedbackMessage: AppL10n.current.subscriptionCheckoutFailed,
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
            feedbackMessage: AppL10n.current.subscriptionStripeUnavailable,
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
              ? AppL10n.current.subscriptionStripeBrowserPrompt
              : AppL10n.current.subscriptionPaymentPageFailed,
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
          feedbackMessage: AppL10n.current.subscriptionCardCheckoutFailed,
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
              : AppL10n.current.subscriptionCanceledEnded,
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
          feedbackMessage: AppL10n.current.subscriptionCancelError,
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
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }
}
