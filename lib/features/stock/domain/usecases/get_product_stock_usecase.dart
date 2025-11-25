import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class GetProductStockUsecase {
  final StockRepository repository;

  GetProductStockUsecase(this.repository);

  Future<int> call(int productCodigo) async {
    return await repository.getProductStock(productCodigo);
  }
}