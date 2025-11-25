import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class DeleteProductUsecase {
  final StockRepository repository;

  DeleteProductUsecase(this.repository);

  Future<void> call(int productId) async {
    return await repository.deleteProduct(productId);
  }
}