import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/return_reason_model.dart';

part 'returns_remote_datasource.g.dart';

@RestApi()
abstract class ReturnsService {
  factory ReturnsService(Dio dio, {String baseUrl}) = _ReturnsService;

  @GET('/returns/reasons')
  Future<List<ReturnReasonModel>> getReturnReasons();

  @POST('/returns/partial')
  Future<Map<String, dynamic>> createPartialReturn(@Body() Map<String, dynamic> body);
}

abstract class ReturnsRemoteDataSource {
  Future<List<ReturnReasonModel>> getReturnReasons();
  Future<Map<String, dynamic>> createPartialReturn(Map<String, dynamic> body);
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
  Future<Map<String, dynamic>> createPartialReturn(Map<String, dynamic> body) async {
    try {
      return await _apiService.createPartialReturn(body);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al confirmar la devolución'));
    }
  }
}
