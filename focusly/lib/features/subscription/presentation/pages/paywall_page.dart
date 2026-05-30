import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_gate_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../data/models/subscription_model.dart';
import '../cubit/subscription_cubit.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key, this.paymentResult});

  /// `1` = success deep link, `0` = failure, null = normal open.
  final String? paymentResult;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionCubit()..load(),
      child: _PaywallView(paymentResult: paymentResult),
    );
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePaymentReturn());
  }

  void _handlePaymentReturn() {
    final result = widget.paymentResult;
    if (result == null) return;

    context.read<AuthBloc>().add(const AuthCheckStatus());
    context.read<SubscriptionCubit>().load();

    final success = result == '1';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Payment received. If Premium is not active yet, wait a moment and tap Refresh.'
              : 'Payment was not completed.',
        ),
        backgroundColor: success ? AppColors.secondary : AppColors.error,
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
      listener: (context, state) {
        if (state.feedbackType == SubscriptionFeedbackType.none ||
            state.feedbackMessage == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.feedbackMessage!),
            backgroundColor: state.feedbackType == SubscriptionFeedbackType.error
                ? AppColors.error
                : AppColors.secondary,
          ),
        );
        if (state.feedbackType == SubscriptionFeedbackType.success) {
          context.read<AuthBloc>().add(const AuthCheckStatus());
        }
        context.read<SubscriptionCubit>().clearFeedback();
      },
      builder: (context, state) {
        final isPremium = state.subscription?.isActive == true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Focusly Premium'),
            actions: [
              IconButton(
                tooltip: 'Refresh status',
                onPressed: state.isLoading
                    ? null
                    : () {
                        context.read<SubscriptionCubit>().load();
                        context.read<AuthBloc>().add(const AuthCheckStatus());
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
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
                        'Opens secure checkout in your browser.',
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
                      _ActivePlanCard(subscription: state.subscription!),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: state.isLoading
                            ? null
                            : () => context
                                .read<SubscriptionCubit>()
                                .cancelSubscription(),
                        child: const Text('Cancel subscription'),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
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
          const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
        ],
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Status: ${subscription.status}'
        '${subscription.currentPeriodEnd != null ? '\nRenews: ${subscription.currentPeriodEnd}' : ''}',
      ),
    );
  }
}

void showPaywallOrGate(BuildContext context, {String? message}) {
  if (message != null) {
    showPremiumGateSheet(
      context,
      message: message,
      upgradeRoute: '/premium',
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PaywallPage()),
  );
}
