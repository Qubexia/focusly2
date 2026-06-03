import 'package:dio/dio.dart';
import 'dart:io';

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

  Future<void> verifyEmail({required String token}) async {
    await _dio.post(
      ApiEndpoints.verifyEmail,
      data: {'token': token},
    );
  }

  /// Re-sends the verification email to the authenticated user.
  Future<void> resendVerificationEmail() async {
    await _dio.post(ApiEndpoints.resendVerification);
  }

  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.usersMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateFcmToken({required String fcmToken}) async {
    await _dio.post(
      ApiEndpoints.usersFcmToken,
      data: {'fcmToken': fcmToken},
    );
  }

  Future<UserModel> updateProfile({
    required String name,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.usersMe,
      data: {'name': name},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadAvatar({
    required String filePath,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post(
      ApiEndpoints.usersAvatar,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    final data = response.data as Map<String, dynamic>;
    return (data['avatarUrl'] ?? '') as String;
  }
}
