import 'package:dio/dio.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE, HEAD',
        },
        responseType: ResponseType.json,
      ),
    );

    // Agregar interceptors para logging (opcional)
    _instance!.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return _instance!;
  }

  static void clearInstance() {
    _instance = null;
  }
}