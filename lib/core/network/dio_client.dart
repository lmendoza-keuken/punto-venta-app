import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/network/interceptors.dart';

class DioClient {
  static Dio? _instance;

  static final Dio instance = _createInstance();

  static Dio _createInstance() {
    final d = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods':
              'POST, GET, OPTIONS, PUT, DELETE, HEAD',
        },
        responseType: ResponseType.json,
      ),
    );

    configureDioWithInterceptors(d, injectToken: true);

    return d;
  }

  static void clearInstance() {
    _instance = null;
  }
}
