import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final checkoutUrl = (checkout['checkoutUrl'] as String?)?.trim() ?? '';
      final canUseNativeSdk =
          checkout['canUseNativeSdk'] == true ||
          clientSecret.startsWith('egy_csk_') ||
          clientSecret.startsWith('csk_');

      if (canUseNativeSdk) {
        if (publicKey.isEmpty || clientSecret.isEmpty) {
          emit(
            state.copyWith(
              isPurchasing: false,
              feedbackType: SubscriptionFeedbackType.error,
              feedbackMessage:
                  AppL10n.current.subscriptionPaymobSessionIncomplete,
            ),
          );
          return;
        }
        await _payWithNativeSdk(
          plan: plan,
          publicKey: publicKey,
          clientSecret: clientSecret,
        );
        return;
      }

      // Legacy / VPC integrations cannot use the native SDK — open hosted page.
      if (checkoutUrl.isNotEmpty) {
        final opened = await _openHostedCheckout(checkoutUrl);
        emit(
          state.copyWith(
            isPurchasing: false,
            feedbackType: opened
                ? SubscriptionFeedbackType.success
                : SubscriptionFeedbackType.error,
            feedbackMessage: opened
                ? AppL10n.current.subscriptionPaymentReceived
                : AppL10n.current.subscriptionCheckoutFailed,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: AppL10n.current.subscriptionPaymobUnavailable,
        ),
      );
    } on DioException catch (e) {
      debugPrint(
        '[Paymob] DioException type=${e.type} status=${e.response?.statusCode} '
        'url=${e.requestOptions.uri} data=${e.response?.data}',
      );
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (e, st) {
      debugPrint('[Paymob] Unexpected error: $e\n$st');
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: AppL10n.current.subscriptionCheckoutFailed,
        ),
      );
    }
  }

  Future<void> _payWithNativeSdk({
    required String plan,
    required String publicKey,
    required String clientSecret,
  }) async {
    final PaymobPaymentResult result;
    try {
      result = await Paymob.pay(
        publicKey: publicKey,
        clientSecret: clientSecret,
        appName: 'Zakerly',
        buttonBackgroundColor: AppColors.premium,
        buttonTextColor: Colors.white,
        saveCardDefault: false,
        showSaveCard: true,
      );
    } on PlatformException catch (e) {
      debugPrint(
        '[Paymob] PlatformException code=${e.code} message=${e.message} '
        'details=${e.details}',
      );
      final cleanMessage = (e.message?.trim().isNotEmpty == true)
          ? e.message!.trim()
          : AppL10n.current.subscriptionPaymentFailed;
      emit(
        state.copyWith(
          isPurchasing: false,
          feedbackType: SubscriptionFeedbackType.error,
          feedbackMessage: '[${e.code}] $cleanMessage',
        ),
      );
      return;
    }

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
  }

  Future<bool> _openHostedCheckout(String checkoutUrl) async {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[Paymob] Failed to open hosted checkout: $e');
      return false;
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
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (message is List && message.isNotEmpty) {
        return message.map((e) => e.toString()).join('; ');
      }
    }
    return AppL10n.current.commonError;
  }
}
