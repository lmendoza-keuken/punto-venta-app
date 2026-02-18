import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/models/app_config_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

abstract class AppConfigRemoteDataSource {
  Future<AppConfigModel> fetchAppConfig();
  Future<AppConfigModel> updateAppConfig(AppConfigModel config);
}

class AppConfigRemoteDataSourceImpl implements AppConfigRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  AppConfigRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 10),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<AppConfigModel> fetchAppConfig() async {
    final url = ApiConfig.appConfigUrl;

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      if (response.statusCode == 200) {
        return AppConfigModel.fromJson(response.data);
      } else {
        throw Exception('Error al obtener configuración: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout al obtener configuración después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica la red');
      } else if (e.response != null) {
        throw Exception('Error al obtener configuración: ${e.response?.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener configuración: $e');
    }
  }

  @override
  Future<AppConfigModel> updateAppConfig(AppConfigModel config) async {
    final url = ApiConfig.appConfigUrl;

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.put(
        url,
        data: config.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AppConfigModel.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar configuración: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Timeout al actualizar configuración después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Error de conexión. Verifica la red');
      } else if (e.response != null) {
        throw Exception('Error al actualizar configuración: ${e.response?.statusCode}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al actualizar configuración: $e');
    }
  }
}
