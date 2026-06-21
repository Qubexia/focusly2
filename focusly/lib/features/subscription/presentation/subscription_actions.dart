import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/l10n/app_localizations.dart';
import '../../../core/services/premium_refresh_service.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event_state.dart';
import 'cubit/subscription_cubit.dart';
import '../data/repositories/subscription_repository.dart';
import 'widgets/cancel_subscription_dialog.dart';

class SubscriptionActions {
  SubscriptionActions._();

  static final SubscriptionRepository _repository = SubscriptionRepository();

  static Future<void> cancelFromContext(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final subscription = context.read<SubscriptionCubit>().state.subscription;
    final canCancel =
        authState.user.isPremium || subscription?.isActive == true;
    if (!canCancel) return;

    await handleCancelSubscription(
      context,
      onConfirm: () async {
        try {
          final result = await _repository.cancelSubscription();
          if (!context.mounted) return;

          await PremiumRefreshService.instance.syncAfterSubscriptionChange(
            context.read<AuthBloc>(),
          );
          if (!context.mounted) return;

          await context.read<SubscriptionCubit>().load();

          if (!context.mounted) return;
          final message = (result['message'] as String?)?.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message?.isNotEmpty == true
                    ? message!
                    : AppLocalizations.of(context).subscriptionCanceled,
              ),
            ),
          );
        } on DioException catch (e) {
          if (!context.mounted) return;
          final l10n = AppLocalizations.of(context);
          final data = e.response?.data;
          final message = data is Map<String, dynamic>
              ? (data['message'] as String?) ?? l10n.subscriptionCancelError
              : l10n.subscriptionCancelError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).subscriptionCancelError,
              ),
            ),
          );
        }
      },
    );
  }
}
