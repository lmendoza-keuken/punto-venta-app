import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/dispose_reason_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'stock_dispose_remote_datasource.g.dart';

@RestApi()
abstract class StockDisposeService {
  factory StockDisposeService(Dio dio, {String baseUrl}) = _StockDisposeService;

  @GET('/stock/dispose/reasons')
  Future<List<DisposeReasonModel>> getDisposeReasons();

  /// Response placeholder: same shape as GET /articles/
  @POST('/stock/dispose')
  Future<List<ProductModel>> disposeStock(@Body() Map<String, dynamic> body);
}

abstract class StockDisposeRemoteDataSource {
  Future<List<DisposeReasonModel>> getDisposeReasons();
  Future<List<ProductModel>> disposeStock(StockDisposeRequestModel request);
}

class StockDisposeRemoteDataSourceImpl implements StockDisposeRemoteDataSource {
  StockDisposeService get _apiService => di.sl<StockDisposeService>();

  StockDisposeRemoteDataSourceImpl();

  @override
  Future<List<DisposeReasonModel>> getDisposeReasons() async {
    try {
      return await _apiService.getDisposeReasons();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener motivos de descarte'));
    }
  }

  @override
  Future<List<ProductModel>> disposeStock(
      StockDisposeRequestModel request) async {
    try {
      return await _apiService.disposeStock(request.toJson());
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al procesar el descarte de stock'));
    }
  }
}
