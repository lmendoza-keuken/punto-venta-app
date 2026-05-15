import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class TokenInjectorInterceptor extends Interceptor {
  final Future<String?> Function() _getToken;
  TokenInjectorInterceptor(this._getToken);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }
}

class DynamicBaseUrlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      options.baseUrl = ApiConfig.validatedBaseUrl;
    } catch (_) {
      // If URL is not yet configured, we let it fail or use placeholder
    }
    handler.next(options);
  }
}

void configureDioWithInterceptors(Dio dio, {bool injectToken = true}) {
  dio.interceptors.add(DynamicBaseUrlInterceptor());
  
  dio.interceptors.add(LogInterceptor(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  if (injectToken) {
    dio.interceptors.add(TokenInjectorInterceptor(
      () => di.sl<AuthLocalDataSource>().getToken(),
    ));
  }
}
