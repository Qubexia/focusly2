import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Remote data source for all auth-related API calls.
class AuthRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? deviceId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
      options: Options(
        headers: deviceId != null ? {'x-device-id': deviceId} : null,
      ),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> googleLogin({
    required String idToken,
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.googleLogin,
      data: {
        'idToken': idToken,
        'deviceId': deviceId,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.usersMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
