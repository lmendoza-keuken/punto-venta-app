import 'package:pos_flutter_app/features/pos/data/datasources/product_local_data.datasource.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/product.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Product>> getProducts() async {
    final productModels = await localDataSource.getProducts();
    return productModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    final productModels = await localDataSource.getProductsByCategory(category);
    return productModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    final productModels = await localDataSource.searchProducts(query);
    return productModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    return await localDataSource.getCategories();
  }
}
