import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/premium/premium_status.dart';
import '../../../../core/services/payment_flow_guard.dart';
import '../../../../core/services/premium_refresh_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_gate_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../data/models/subscription_model.dart';
import '../cubit/subscription_cubit.dart';
import '../widgets/cancel_subscription_dialog.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key, this.paymentResult});

  /// `1` = success deep link, `0` = failure, null = normal open.
  final String? paymentResult;

  @override
  Widget build(BuildContext context) {
    return _PaywallView(paymentResult: paymentResult);
  }
}

class _PaywallView extends StatefulWidget {
  const _PaywallView({this.paymentResult});

  final String? paymentResult;

  @override
  State<_PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<_PaywallView> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionCubit>().load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePaymentReturn());
  }

  @override
  void didUpdateWidget(covariant _PaywallView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paymentResult != oldWidget.paymentResult &&
        widget.paymentResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePaymentReturn());
    }
  }

  void _handlePaymentReturn() {
    final result = widget.paymentResult;
    if (result == null) return;

    if (result == '1') {
      if (!PaymentFlowGuard.instance.claimSuccessHandling()) return;
      unawaited(_syncPremiumAfterPayment(showSnackBar: true));
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Payment was not completed.'),
          backgroundColor: AppColors.error,
        ),
      );
  }

  Future<void> _syncPremiumAfterPayment({required bool showSnackBar}) async {
    await PaymentFlowGuard.instance.runSync(() async {
      final authBloc = context.read<AuthBloc>();
      await context.read<SubscriptionCubit>().load();

      final becamePremium = await PremiumRefreshService.instance.refreshUntilPremium(
        authBloc,
      );

      if (!mounted) return;

      if (showSnackBar) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              becamePremium
                  ? 'Premium is active. Enjoy your upgraded study flow.'
                  : 'Payment received. Premium may take a moment to activate.',
            ),
            backgroundColor: becamePremium ? AppColors.secondary : AppColors.premium,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (becamePremium) {
        context.go('/home');
      }
    });
  }

  void _showFeedbackSnackBar({
    required String message,
    required SubscriptionFeedbackType type,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == SubscriptionFeedbackType.error
            ? AppColors.error
            : AppColors.secondary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static const _features = [
    ('Unlimited subjects', Icons.menu_book_rounded),
    ('Full analytics', Icons.insights_rounded),
    ('AI study notes', Icons.auto_awesome_rounded),
    ('Priority reminders', Icons.notifications_active_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      listenWhen: (previous, current) =>
          current.feedbackType != SubscriptionFeedbackType.none &&
          current.feedbackMessage != null &&
          (previous.feedbackType != current.feedbackType ||
              previous.feedbackMessage != current.feedbackMessage),
      listener: (context, state) {
        final feedbackType = state.feedbackType;
        final feedbackMessage = state.feedbackMessage!;
        context.read<SubscriptionCubit>().clearFeedback();

        Future<void> handleFeedback() async {
          if (feedbackType == SubscriptionFeedbackType.success) {
            if (!PaymentFlowGuard.instance.claimSuccessHandling()) return;
            _showFeedbackSnackBar(message: feedbackMessage, type: feedbackType);
            await _syncPremiumAfterPayment(showSnackBar: false);
            return;
          }

          _showFeedbackSnackBar(message: feedbackMessage, type: feedbackType);

          if (feedbackType == SubscriptionFeedbackType.cancelSuccess) {
            await PremiumRefreshService.instance.syncAfterSubscriptionChange(
              context.read<AuthBloc>(),
            );
            if (!context.mounted) return;
            await context.read<SubscriptionCubit>().load();
          }
        }

        unawaited(handleFeedback());
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;
        final subscription = state.subscription;
        final isPremium = hasPremiumAccess(
          authState: authState,
          subscription: subscription,
        );
        final canCancel = subscription?.isActive == true;
        final isPendingCancel =
            subscription?.isCanceled == true &&
            (user?.isPremium == true || subscription?.isActive == true);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Zakerly Premium'),
            actions: [
              IconButton(
                tooltip: 'Refresh status',
                onPressed: state.isLoading
                    ? null
                    : () {
                        context.read<SubscriptionCubit>().load();
                        context.read<AuthBloc>().add(const AuthRefreshUser());
                      },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: state.isLoading && state.subscription == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _HeroCard(isPremium: isPremium),
                    const SizedBox(height: 24),
                    ..._features.map(
                      (f) => _FeatureRow(title: f.$1, icon: f.$2),
                    ),
                    const SizedBox(height: 28),
                    if (!isPremium) ...[
                      Text(
                        'Choose payment method',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: state.isPurchasing
                            ? null
                            : () => context
                                  .read<SubscriptionCubit>()
                                  .payWithPaymob(plan: 'monthly'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.premium,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Pay with Paymob — Monthly (EGP)'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: state.isPurchasing
                            ? null
                            : () => context
                                  .read<SubscriptionCubit>()
                                  .payWithPaymob(plan: 'yearly'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Pay with Paymob — Yearly (EGP)'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cards, wallets, and local methods via Paymob. '
                        'Uses the native Paymob payment sheet inside the app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: state.isPurchasing
                            ? null
                            : () => context
                                  .read<SubscriptionCubit>()
                                  .payWithStripe(),
                        icon: const Icon(Icons.credit_card_rounded),
                        label: const Text('International card (Stripe)'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                    if (isPremium) ...[
                      _ActivePlanCard(
                        subscription: subscription,
                        premiumUntil: user?.premiumUntil,
                        isPendingCancel: isPendingCancel,
                      ),
                      if (canCancel) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => handleCancelSubscription(
                                    context,
                                    onConfirm: () => context
                                        .read<SubscriptionCubit>()
                                        .cancelSubscription(),
                                  ),
                          icon: const Icon(Icons.cancel_outlined),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          label: const Text('Cancel subscription'),
                        ),
                      ],
                      if (isPendingCancel) ...[
                        const SizedBox(height: 12),
                        Text(
                          user?.premiumUntil != null
                              ? 'Renewal canceled. Premium access until '
                                  '${_formatDate(user!.premiumUntil!)}.'
                              : 'Renewal canceled. Premium access remains for this period.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'You are Premium' : 'Upgrade your study flow',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'All premium features are unlocked on your account.'
                : 'Remove limits and unlock AI notes, analytics, and more.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.secondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.subscription,
    required this.premiumUntil,
    required this.isPendingCancel,
  });

  final SubscriptionModel? subscription;
  final DateTime? premiumUntil;
  final bool isPendingCancel;

  @override
  Widget build(BuildContext context) {
    final status = subscription?.status ?? (isPendingCancel ? 'canceled' : 'active');
    final provider = subscription?.provider;
    final renewsOn = subscription?.currentPeriodEnd ?? premiumUntil;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPendingCancel ? 'Premium (canceling)' : 'Premium active',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text('Status: $status'),
          if (provider != null) Text('Provider: $provider'),
          if (renewsOn != null)
            Text(
              isPendingCancel
                  ? 'Access until: ${_formatDate(renewsOn)}'
                  : 'Renews: ${_formatDate(renewsOn)}',
            ),
        ],
      ),
    );
  }
}

void showPaywallOrGate(BuildContext context, {String? message}) {
  if (message != null) {
    showPremiumGateSheet(context, message: message, upgradeRoute: '/premium');
    return;
  }
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
}
