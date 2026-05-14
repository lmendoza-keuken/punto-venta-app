import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/models/pdv_config_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/branch_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

abstract class PdvRemoteDataSource {
  Future<PdvConfigResponseModel> fetchPdvConfig();
  Future<PdvConfigResponseModel> updatePdvConfig(PdvConfig config);
  Future<PdvConfigResponseModel> updateOfflineMode(PdvConfig config);
  Future<List<BranchResponseModel>> fetchBranches();
}

class PdvRemoteDataSourceImpl implements PdvRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  PdvRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<PdvConfigResponseModel> fetchPdvConfig() async {
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
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return PdvConfigResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
            'Error al obtener configuración del PDV: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener configuración del PDV: ${e.message}'));
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error inesperado al obtener PDV: $e'));
    }
  }

  @override
  Future<PdvConfigResponseModel> updatePdvConfig(PdvConfig config) async {
    final url = ApiConfig.configPdvUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de config-pdv no configurada');
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    final jsonData = config.toUpdateJson();

    try {
      final response = await _dio.put(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return PdvConfigResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
            'Error al obtener configuración del PDV: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al actualizar configuración del PDV: ${e.message}'));
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error inesperado al actualizar PDV: $e'));
    }
  }

  @override
  Future<PdvConfigResponseModel> updateOfflineMode(PdvConfig config) async {
    final url = ApiConfig.configPdvUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de config-pdv no configurada');
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    final jsonData = config.toUpdateOfflineModeJson();

    try {
      final response = await _dio.put(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
        ),
      );


      if (response.statusCode == 200) {
        return PdvConfigResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
            'Error al actualizar modo offline: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al actualizar modo offline: ${e.message}'));
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error inesperado al actualizar modo offline: $e'));
    }
  }

  @override
  Future<List<BranchResponseModel>> fetchBranches() async {
    final url = ApiConfig.branchesUrl;

    if (url.isEmpty) {
      throw Exception('URL del endpoint de branches no configurada');
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'skip': 0,
          'limit': 100,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => BranchResponseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al obtener sucursales: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener sucursales: ${e.message}'));
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error inesperado al obtener sucursales: $e'));
    }
  }
}
