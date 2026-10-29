import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class ProcessStockDisposeUseCase {
  final StockDisposeRepository repository;

  ProcessStockDisposeUseCase(this.repository);

  Future<List<ProductModel>> call(StockDisposeRequestModel request) {
    return repository.disposeStock(request);
  }
}
