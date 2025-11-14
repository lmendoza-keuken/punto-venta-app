import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos_flutter_app/core/config/api_config.dart';
import 'package:pos_flutter_app/features/pos/data/models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<String>> getCategories();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  List<ProductModel>? _cachedProducts;

  Future<List<ProductModel>> _fetchProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.productosUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods":
              "POST, GET, OPTIONS, PUT, DELETE, HEAD",
        },
      );

      if (response.statusCode == 200) {
        // Decodificar con UTF-8
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(responseBody);

        _cachedProducts = jsonData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .where((product) =>
                product.suspendidoVenta == 'N') // Solo productos activos
            .toList();

        return _cachedProducts!;
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    return await _fetchProducts();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await _fetchProducts();

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where(
            (product) => product.rubro?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await _fetchProducts();

    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products
        .where((product) =>
            (product.descripcion ?? "").toLowerCase().contains(lowerQuery) ||
            product.codigo.toString().contains(lowerQuery) ||
            (product.marca ?? "").toLowerCase().contains(lowerQuery) ||
            (product.rubro ?? "").toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final products = await _fetchProducts();

    final categories = products
        .map((product) => product.rubro!)
        .where((rubro) => rubro.isNotEmpty)
        .toSet()
        .toList();

    categories.sort(); // Ordenar alfabéticamente

    // Agregar "Todo" al inicio
    categories.insert(0, 'Todo');

    return categories;
  }

  // Método para limpiar caché cuando sea necesario
  void clearCache() {
    _cachedProducts = null;
  }
}
