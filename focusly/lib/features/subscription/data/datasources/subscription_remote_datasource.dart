import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<SubscriptionModel?> getMySubscription() async {
    final response = await _dio.get(ApiEndpoints.subscriptionMe);
    final data = response.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return SubscriptionModel.fromJson(data);
    }
    return null;
  }

  Future<void> cancelSubscription() async {
    await _dio.post(ApiEndpoints.subscriptionCancel);
  }

  Future<Map<String, dynamic>> createPaymobCheckout({
    required String plan,
    String? checkoutBaseUrl,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.subscriptionPaymobCheckout,
      data: {
        'plan': plan,
        if (checkoutBaseUrl != null && checkoutBaseUrl.isNotEmpty)
          'checkoutBaseUrl': checkoutBaseUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<String> createStripeCheckoutSession() async {
    final response = await _dio.post(ApiEndpoints.subscriptionStripeCheckout);
    final data = response.data as Map<String, dynamic>;
    return (data['url'] as String?) ?? '';
  }
}
