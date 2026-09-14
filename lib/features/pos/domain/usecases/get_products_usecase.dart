import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/repositories/product_images_repository.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/product_repository.dart';

class GetProductsUsecase {
  final ProductRepository repository;
  final ProductImagesRepository productImagesRepository;
  final AuthLocalDataSource authLocalDataSource;

  GetProductsUsecase(
    this.repository,
    this.productImagesRepository,
    this.authLocalDataSource,
  );

  Stream<List<Product>> call() async* {
    final imagesFuture = _loadImageMap();
    await for (final products in repository.getProducts()) {
      final images = await imagesFuture;
      yield _attachImages(products, images);
    }
  }

  Future<List<Product>> getByCategory(String category) async {
    final imagesFuture = _loadImageMap();
    final List<Product> products;
    if (category.toLowerCase() == 'todo') {
      products = await repository.getProducts().last;
    } else {
      products = await repository.getProductsByCategory(category);
    }
    final images = await imagesFuture;
    return _attachImages(products, images);
  }

  Future<List<Product>> search(String query) async {
    final imagesFuture = _loadImageMap();
    final products = await repository.searchProducts(query);
    final images = await imagesFuture;
    return _attachImages(products, images);
  }

  Future<Product?> searchByBarcode(String barcode) async {
    return await repository.searchByBarcode(barcode);
  }

  Future<Product?> searchByArticleId(int articleId) async {
    return await repository.searchByArticleId(articleId);
  }

  Future<List<String>> getCategories() async {
    return await repository.getCategories();
  }

  Future<void> updatePriceList(int listId) async {
    await repository.updatePriceList(listId);
  }

  Future<Map<String, String>> _loadImageMap() async {
    try {
      final enterprise = await authLocalDataSource.getCachedEnterprise();
      if (enterprise == null) return {};
      return await productImagesRepository
          .fetchProductImages(enterprise.id.toString());
    } catch (_) {
      return {};
    }
  }

  List<Product> _attachImages(
    List<Product> products,
    Map<String, String> images,
  ) {
    if (images.isEmpty) return products;
    return products
        .map((product) {
          final url = images[product.id.toString()];
          if (url == null || url.isEmpty) return product;
          return product.copyWith(imageUrl: url);
        })
        .toList();
  }
}
