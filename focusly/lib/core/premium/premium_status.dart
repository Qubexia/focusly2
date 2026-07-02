import '../../features/auth/presentation/bloc/auth_event_state.dart';
import '../../features/subscription/data/models/subscription_model.dart';
import '../config/platform_config.dart';

/// Unified premium gate used across the app UI.
bool hasPremiumAccess({
  required AuthState authState,
  SubscriptionModel? subscription,
}) {
  if (!PlatformConfig.current.premiumGatingEnabled) {
    return true;
  }

  if (subscription != null) {
    if (subscription.isCanceled || subscription.status == 'expired') {
      return false;
    }
    if (subscription.isActive) {
      return true;
    }
  }

  if (authState is AuthAuthenticated && authState.user.isPremium) {
    return true;
  }

  return false;
}



String? extractPaymobTransactionId(Map<String, dynamic>? details) {

  if (details == null || details.isEmpty) return null;



  for (final key in const [

    'id',

    'transaction_id',

    'transactionId',

    'transactionID',

  ]) {

    final value = details[key];

    if (value == null) continue;

    final text = value.toString().trim();

    if (text.isNotEmpty) return text;

  }



  return null;

}


