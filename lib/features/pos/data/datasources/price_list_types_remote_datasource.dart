import 'package:dio/dio.dart';
import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'price_list_types_remote_datasource.g.dart';

@RestApi()
abstract class PriceListTypesService {
  factory PriceListTypesService(Dio dio, {String baseUrl}) =
      _PriceListTypesService;

  @GET('/price-list-types/')
  Future<List<PriceListTypeResponseModel>> fetchPriceListTypes(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 100});
}

abstract class PriceListTypesRemoteDataSource {
  Future<List<PriceListTypeResponseModel>> fetchPriceListTypes();
}

class PriceListTypesRemoteDataSourceImpl
    implements PriceListTypesRemoteDataSource {
  PriceListTypesService get _apiService => di.sl<PriceListTypesService>();

  PriceListTypesRemoteDataSourceImpl();

  @override
  Future<List<PriceListTypeResponseModel>> fetchPriceListTypes() async {
    try {
      return await _apiService.fetchPriceListTypes();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener tipos de listas de precios'));
    }
  }
}
