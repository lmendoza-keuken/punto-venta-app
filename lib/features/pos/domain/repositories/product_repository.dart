import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<List<Product>> getProductsByCategory(String category);
  Future<List<Product>> searchProducts(String query);
  Future<List<String>> getCategories();
}
