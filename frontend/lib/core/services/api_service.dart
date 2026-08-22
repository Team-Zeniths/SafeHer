import 'package:dio/dio.dart';
import '../../constants.dart';
import 'storage_service.dart';

/// Thin wrapper around [Dio] that centralizes base configuration,
/// auth-header injection and error normalization.
class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.instance.getAuthToken();
          if (token != null && token.isNotEmpty) {
            final scheme = await StorageService.instance.getAuthScheme();
            // 'Token <key>' for DRF dev-auth, 'Bearer <idToken>' for Firebase.
            options.headers['Authorization'] = '$scheme $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._internal();

  late final Dio _dio;
  Dio get client => _dio;

  // ---- Generic verbs -------------------------------------------------

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
