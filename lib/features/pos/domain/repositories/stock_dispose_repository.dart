import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';

abstract class StockDisposeRepository {
  Future<List<DisposeReason>> fetchDisposeReasons();
  Future<List<ProductModel>> disposeStock(StockDisposeRequestModel request);
}
