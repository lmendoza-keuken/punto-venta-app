import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';

abstract class StockDisposeRepository {
  Future<List<DisposeReason>> fetchDisposeReasons();
  Future<StockDisposeResponseModel> disposeStock(
      StockDisposeRequestModel request);
}
