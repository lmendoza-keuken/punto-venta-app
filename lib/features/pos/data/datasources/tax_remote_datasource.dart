import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/tax_model.dart';

part 'tax_remote_datasource.g.dart';

@RestApi()
abstract class TaxService {
  factory TaxService(Dio dio, {String baseUrl}) = _TaxService;

  @GET('/taxes/')
  Future<List<TaxModel>> getTaxes();
}

abstract class TaxRemoteDataSource {
  Future<List<TaxModel>> getTaxes();
}

class TaxRemoteDataSourceImpl implements TaxRemoteDataSource {
  TaxService get _apiService => di.sl<TaxService>();

  TaxRemoteDataSourceImpl();

  @override
  Future<List<TaxModel>> getTaxes() async {
    try {
      return await _apiService.getTaxes();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener impuestos'));
    }
  }
}
