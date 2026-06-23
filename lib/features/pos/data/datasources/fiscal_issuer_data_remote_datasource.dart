import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/fiscal_issuer_data_model.dart';

abstract class FiscalIssuerDataRemoteDatasource {
  Future<FiscalIssuerDataModel> getFiscalIssuerData(int branchId);
}

class FiscalIssuerDataRemoteDatasourceImpl
    implements FiscalIssuerDataRemoteDatasource {
  Dio get _dio => di.sl<Dio>();
  final Duration timeout;

  FiscalIssuerDataRemoteDatasourceImpl({
    this.timeout = const Duration(seconds: 15),
  });

  @override
  Future<FiscalIssuerDataModel> getFiscalIssuerData(int branchId) async {
    final url = ApiConfig.fiscalDataUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de datos fiscales no configurada');
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
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;

        data['branchId'] = branchId;

        return FiscalIssuerDataModel.fromJson(data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message:
              'Error al obtener datos fiscales: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al obtener datos fiscales después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al obtener datos fiscales: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception(
            'Error desconocido al obtener datos fiscales: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error al procesar respuesta de datos fiscales: $e');
    }
  }
}
