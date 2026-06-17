import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/return_reason_model.dart';
import 'package:punto_venta_app/features/pos/data/models/sale_return_model.dart';
import 'package:punto_venta_app/features/pos/data/models/total_return_create_model.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'returns_remote_datasource.g.dart';

@RestApi()
abstract class ReturnsService {
  factory ReturnsService(Dio dio, {String baseUrl}) = _ReturnsService;

  @GET('/returns/reasons')
  Future<List<ReturnReasonModel>> getReturnReasons();

  @GET('/returns/')
  Future<List<SaleReturnModel>> getReturns({@Query('date') String? date});

  @POST('/returns/total')
  Future<dynamic> processTotalReturn(@Body() Map<String, dynamic> body);

  @POST('/returns/partial')
  Future<dynamic> processPartialReturn(@Body() Map<String, dynamic> body);
}

abstract class ReturnsRemoteDataSource {
  Future<List<ReturnReasonModel>> getReturnReasons();
  Future<List<SaleReturnModel>> getReturns({String? date});
  Future<InvoicePayload> processTotalReturn(int saleId, int reasonId);
  Future<InvoicePayload> processPartialReturn(PartialReturnRequestModel request);
}

class ReturnsRemoteDataSourceImpl implements ReturnsRemoteDataSource {
  ReturnsService get _apiService => di.sl<ReturnsService>();

  ReturnsRemoteDataSourceImpl();

  @override
  Future<List<ReturnReasonModel>> getReturnReasons() async {
    try {
      return await _apiService.getReturnReasons();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener motivos de devolución'));
    }
  }

  @override
  Future<List<SaleReturnModel>> getReturns({String? date}) async {
    try {
      return await _apiService.getReturns(date: date);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener devoluciones'));
    }
  }

  @override
  Future<InvoicePayload> processTotalReturn(int saleId, int reasonId) async {
    try {
      final body = TotalReturnCreateModel(
        saleId: saleId,
        reasonId: reasonId,
      ).toJson();
      final Map<String, dynamic> data =
          await _apiService.processTotalReturn(body);
      return InvoicePayload.fromJson(data);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al procesar devolución total'));
    }
  }

  @override
  Future<InvoicePayload> processPartialReturn(PartialReturnRequestModel request) async {
    try {
      final body = request.toJson();
      final Map<String, dynamic> data =
          await _apiService.processPartialReturn(body);
      return InvoicePayload.fromJson(data);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al procesar devolución parcial'));
    }
  }
}
