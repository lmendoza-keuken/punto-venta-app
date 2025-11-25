import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/domain/repositories/stock_repository.dart';

class GetAllProductsUsecase {
  final StockRepository repository;

  GetAllProductsUsecase(this.repository);

  Future<List<Product>> call() async {
    return await repository.getAllProducts();
  }
}