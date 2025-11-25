import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class UpdateProductUsecase {
  final StockRepository repository;

  UpdateProductUsecase(this.repository);

  Future<Product> call(Product product) async {
    return await repository.updateProduct(product);
  }
}