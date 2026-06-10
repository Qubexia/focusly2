import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Returns `true` when the user confirms cancellation.
Future<bool> confirmCancelSubscription(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text(
          'Your subscription will stop renewing. '
          'You keep Premium access until the end of the current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Premium'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel subscription'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<void> handleCancelSubscription(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await confirmCancelSubscription(context);
  if (!confirmed || !context.mounted) return;
  await onConfirm();
}
