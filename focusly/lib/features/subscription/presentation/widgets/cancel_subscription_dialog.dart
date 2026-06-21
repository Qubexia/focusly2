import 'package:flutter/material.dart';

import 'package:zakerly/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Returns `true` when the user confirms cancellation.
Future<bool> confirmCancelSubscription(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.subscriptionCancelDialogTitle),
        content: Text(l10n.subscriptionCancelDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.subscriptionKeepPremium),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.subscriptionCancelAction),
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
