import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<List<String>> getCategories();
  Future<List<PrecioArticuloModel>> getPreciosArticulos();
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(int listaPrecio);
  void setListaPrecio(int lista);
  int getListaPrecio();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  List<ProductModel>? _cachedProducts;
  List<PrecioArticuloModel>? _cachedPrecios;
  int _listaActual;

  ProductLocalDataSourceImpl({int listaInicial = 13}) : _listaActual = listaInicial;

  @override
  int getListaPrecio() => _listaActual;

  @override
  void setListaPrecio(int lista) {
    _listaActual = lista;
    clearCache();
  }

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
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE, HEAD",
        },
      );

      if (response.statusCode == 200) {
        // Decodificar con UTF-8
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(responseBody);

        _cachedProducts = jsonData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .where((product) => product.suspendidoVenta == 'N') // Solo productos activos
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
  Future<List<PrecioArticuloModel>> getPreciosArticulos() async {
    if (_cachedPrecios != null) {
      return _cachedPrecios!;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.preciosArticulosUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE, HEAD",
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> jsonData = json.decode(responseBody);

        _cachedPrecios = jsonData
            .map((json) => PrecioArticuloModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return _cachedPrecios!;
      } else {
        throw Exception('Error al cargar precios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(int listaPrecio) async {
    final precios = await getPreciosArticulos();
    
    final preciosByProducto = <int, PrecioArticuloModel>{};
    
    for (var precio in precios) {
      if (precio.listaPrecio == listaPrecio) {
        preciosByProducto[precio.producto] = precio;
      }
    }
    
    return preciosByProducto;
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final products = await _fetchProducts();
    final precios = await getPreciosByLista(_listaActual);
    
    return products.map((product) {
      if (precios.containsKey(product.codigo)) {
        final precio = precios[product.codigo]!;
        return ProductModel.fromJson({
          ...product.toJson(),
          
          'lista13': precio.precio,
          'oferta13': precio.oferta,
        });
      }
      return product;
    }).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await getProducts();

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where((product) => product.rubro?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getProducts();

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
    categories.insert(0, 'Todo');

    return categories;
  }

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
  }
}
