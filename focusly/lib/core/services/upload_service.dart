import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class UploadService {
  UploadService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<String> uploadFile({
    required File file,
    required String kind,
    String? mimeType,
  }) async {
    final length = await file.length();
    final resolvedMime = mimeType ?? _guessMime(file.path);

    final presignResponse = await _dio.post(
      ApiEndpoints.uploadsPresign,
      data: {
        'kind': kind,
        'mimeType': resolvedMime,
        'sizeBytes': length,
      },
    );

    final presign = presignResponse.data as Map<String, dynamic>;
    final url = presign['url'] as String;
    final key = presign['key'] as String;

    final bytes = await file.readAsBytes();
    await Dio().put(
      url,
      data: bytes,
      options: Options(
        headers: {'Content-Type': resolvedMime},
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    await _dio.post(
      ApiEndpoints.uploadsConfirm,
      data: {'key': key},
    );

    return key;
  }

  String _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
