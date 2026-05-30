import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/core/network/exceptions.dart';
import 'package:punto_venta_app/features/pos/data/models/pdv_config_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/branch_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'pdv_remote_datasource.g.dart';

@RestApi()
abstract class PdvService {
  factory PdvService(Dio dio, {String baseUrl}) = _PdvService;

  @GET('/configuration/')
  Future<PdvConfigResponseModel> fetchPdvConfig();

  @PUT('/configuration/')
  Future<PdvConfigResponseModel> updatePdvConfig(@Body() Map<String, dynamic> body);

  @GET('/branches/')
  Future<List<BranchResponseModel>> fetchBranches(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 100});
}

abstract class PdvRemoteDataSource {
  Future<PdvConfigResponseModel> fetchPdvConfig();
  Future<PdvConfigResponseModel> updatePdvConfig(PdvConfig config);
  Future<PdvConfigResponseModel> updateOfflineMode(PdvConfig config);
  Future<List<BranchResponseModel>> fetchBranches();
}

class PdvRemoteDataSourceImpl implements PdvRemoteDataSource {
  PdvService get _apiService => di.sl<PdvService>();

  PdvRemoteDataSourceImpl();

  @override
  Future<PdvConfigResponseModel> fetchPdvConfig() async {
    try {
      return await _apiService.fetchPdvConfig();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        throw NotFoundException('Configuración del PDV no encontrada');
      }
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener configuración del PDV'));
    }
  }

  @override
  Future<PdvConfigResponseModel> updatePdvConfig(PdvConfig config) async {
    try {
      return await _apiService.updatePdvConfig(config.toUpdateJson());
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al actualizar configuración del PDV'));
    }
  }

  @override
  Future<PdvConfigResponseModel> updateOfflineMode(PdvConfig config) async {
    try {
      return await _apiService.updatePdvConfig(config.toUpdateOfflineModeJson());
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al actualizar modo offline'));
    }
  }

  @override
  Future<List<BranchResponseModel>> fetchBranches() async {
    try {
      return await _apiService.fetchBranches();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener sucursales'));
    }
  }
}
