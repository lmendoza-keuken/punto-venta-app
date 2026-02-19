import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

abstract class PdvRemoteDataSource {
  Future<Map<String, dynamic>> fetchPdvConfig();
  Future<Map<String, dynamic>> updatePdvConfig();
}

class PdvRemoteDataSourceImpl implements PdvRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  PdvRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<Map<String, dynamic>> fetchPdvConfig() async {
    final url = ApiConfig.configPdvUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de config-pdv no configurada');
    }

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
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Error al obtener configuración del PDV: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al conectar con el servidor. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.unknown) {
        throw Exception(
            'Error de red. Verifica que el servidor esté disponible.');
      } else {
        throw Exception('Error al obtener configuración del PDV: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener PDV: $e');
    }
  }

  @override
  Future<PdvConfig> updatePdvConfig(PdvConfig config) async {
    final url = ApiConfig.configPdvUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de config-pdv no configurada');
    }

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

      if (response.statusCode == 200) {
        return PdvConfig.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
            'Error al obtener configuración del PDV: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al conectar con el servidor. Verifica tu conexión.');
      } else if (e.type == DioExceptionType.unknown) {
        throw Exception(
            'Error de red. Verifica que el servidor esté disponible.');
      } else {
        throw Exception('Error al obtener configuración del PDV: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener PDV: $e');
    }
  }
}
