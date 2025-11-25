import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/product_repository.dart';

class GetProductsUsecase {
  final ProductRepository repository;

  GetProductsUsecase(this.repository);

  Future<List<Product>> call() async {
    return await repository.getProducts();
  }

  Future<List<Product>> getByCategory(String category) async {
    if (category.toLowerCase() == 'todo') {
      return await repository.getProducts();
    }
    return await repository.getProductsByCategory(category);
  }

  Future<List<Product>> search(String query) async {
    return await repository.searchProducts(query);
  }

  Future<List<String>> getCategories() async {
    return await repository.getCategories();
  }
}
