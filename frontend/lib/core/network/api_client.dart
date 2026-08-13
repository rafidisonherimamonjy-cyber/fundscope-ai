import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'api_exception.dart';

/// Client HTTP unique de l'application, construit autour de Dio.
///
/// Responsabilités :
///  - préfixer toutes les requêtes avec [AppConstants.apiBaseUrl] ;
///  - injecter automatiquement le header `Authorization: Bearer <token>` ;
///  - transformer les erreurs Dio en [ApiException] avec un message
///    directement affichable (extrait du champ `detail` de FastAPI).
///
/// Cette classe est le SEUL point de contact avec `package:dio` dans toute
/// l'application : les datasources ne connaissent que [ApiClient].
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        handler.next(options);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _request(
        () => _dio.get(path, queryParameters: query),
      );

  Future<dynamic> post(String path, {Object? data}) => _request(
        () => _dio.post(path, data: data),
      );

  Future<dynamic> put(String path, {Object? data}) => _request(
        () => _dio.put(path, data: data),
      );

  Future<dynamic> delete(String path) => _request(
        () => _dio.delete(path),
      );

  Future<dynamic> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    String message = "Une erreur est survenue. Vérifiez votre connexion et réessayez.";
    if (data is Map && data["detail"] != null) {
      message = data["detail"].toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      message = "Impossible de joindre le serveur. Vérifiez votre connexion internet.";
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
