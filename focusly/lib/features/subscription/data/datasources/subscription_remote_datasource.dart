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

  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _dio.post(ApiEndpoints.subscriptionCancel);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return const {};
  }

  Future<Map<String, dynamic>> createPaymobCheckout({
    required String plan,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.subscriptionPaymobCheckout,
      data: {'plan': plan},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmPaymobSdk({
    required String plan,
    String? transactionId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.subscriptionPaymobConfirmSdk,
      data: {
        'plan': plan,
        if (transactionId != null && transactionId.isNotEmpty)
          'transactionId': transactionId,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return const {};
  }

  Future<String> createStripeCheckoutSession() async {
    final response = await _dio.post(ApiEndpoints.subscriptionStripeCheckout);
    final data = response.data as Map<String, dynamic>;
    return (data['url'] as String?) ?? '';
  }
}
