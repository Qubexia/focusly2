import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  SubscriptionRepository({SubscriptionRemoteDataSource? remote})
    : _remote = remote ?? SubscriptionRemoteDataSource();

  final SubscriptionRemoteDataSource _remote;

  Future<SubscriptionModel?> getMySubscription() => _remote.getMySubscription();

  Future<void> cancelSubscription() => _remote.cancelSubscription();

  Future<String> createStripeCheckoutSession() =>
      _remote.createStripeCheckoutSession();

  Future<Map<String, dynamic>> createPaymobCheckout({required String plan}) =>
      _remote.createPaymobCheckout(plan: plan);
}
