import 'package:dio/dio.dart';

import 'config.dart';

/// Thin Dio wrapper that injects the bearer token and the Accept-Language
/// header (so the API localizes responses) on every request.
class ApiClient {
  ApiClient({required this.tokenProvider, required this.localeProvider}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] = localeProvider();
        handler.next(options);
      },
    ));
  }

  final String? Function() tokenProvider;
  final String Function() localeProvider;
  late final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  /// Best-effort extraction of a human-readable API error message.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] is String) return data['message'];
        if (data['errors'] is Map) {
          final first = (data['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
    }
    return e.toString();
  }
}
