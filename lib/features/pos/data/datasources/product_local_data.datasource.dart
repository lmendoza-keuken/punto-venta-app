import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/pos/data/models/category_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> searchByBarcode(String barcode);
  Future<List<CategoryModel>> getCategories();
  Future<List<PrecioArticuloModel>> getPreciosArticulos();
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(int listaPrecio);
  void setListaPrecio(int lista);
  int getListaPrecio();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Dio _dio;
  List<ProductModel>? _cachedProducts;
  List<PrecioArticuloModel>? _cachedPrecios;
  List<BarcodeModel>? _cachedBarcodes;
  List<CategoryModel>? _cachedCategories;
  int _listaActual;

  ProductLocalDataSourceImpl({
    Dio? dio,
    int listaInicial = 1,
  })  : _dio = dio ?? DioClient.instance,
        _listaActual = listaInicial;

  @override
  int getListaPrecio() => _listaActual;

  @override
  void setListaPrecio(int lista) {
    _listaActual = lista;
    clearCache();
  }

  Future<List<BarcodeModel>> _fetchBarcodes() async {
    if (_cachedBarcodes != null) {
      return _cachedBarcodes!;
    }

    try {
      final response = await _dio.get(
        ApiConfig.barcodeUrl,
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data is String
            ? json.decode(response.data)
            : response.data;

        _cachedBarcodes = jsonData
            .map((json) => BarcodeModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return _cachedBarcodes!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Error al cargar códigos de barras: ${response.statusCode}',
        );
      }
    } catch (e) {
      _cachedBarcodes = [];
      return _cachedBarcodes!;
    }
  }

  Future<List<ProductModel>> _fetchProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    try {
      final response = await _dio.get(
        ApiConfig.productosUrl,
        queryParameters: {'limit': 500},
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data is String
            ? json.decode(response.data)
            : response.data;

        _cachedProducts = jsonData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .where((product) => product.suspendedForSale == 'N')
            .toList();

        return _cachedProducts!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Error al cargar productos: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de respuesta agotado');
      } else if (e.response != null) {
        throw Exception(
            'Error del servidor: ${e.response?.statusCode} - ${e.response?.statusMessage}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<List<PrecioArticuloModel>> getPreciosArticulos() async {
    if (_cachedPrecios != null) {
      return _cachedPrecios!;
    }

    try {
      final response = await _dio.get(
        ApiConfig.preciosArticulosUrl,
        queryParameters: {'limit': 3500},
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data is String
            ? json.decode(response.data)
            : response.data;

        _cachedPrecios = jsonData
            .map((json) =>
                PrecioArticuloModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return _cachedPrecios!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Error al cargar precios: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Tiempo de conexión agotado');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de respuesta agotado');
      } else if (e.response != null) {
        throw Exception(
            'Error del servidor: ${e.response?.statusCode} - ${e.response?.statusMessage}');
      } else {
        throw Exception('Error de conexión: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(
      int listaPrecio) async {
    final precios = await getPreciosArticulos();

    final preciosByProducto = <int, PrecioArticuloModel>{};

    for (var precio in precios) {
      if (precio.listId == listaPrecio) {
        preciosByProducto[precio.productId] = precio;
      }
    }

    return preciosByProducto;
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    final products = await _fetchProducts();
    final barcodes = await _fetchBarcodes();

    final barcodesByProduct = <int, List<BarcodeModel>>{};
    for (var barcode in barcodes) {
      if (!barcodesByProduct.containsKey(barcode.articleId)) {
        barcodesByProduct[barcode.articleId ?? 0] = [];
      }
      barcodesByProduct[barcode.articleId]!.add(barcode);
    }

    Map<int, PrecioArticuloModel>? precios;
    try {
      precios = await getPreciosByLista(_listaActual);
    } catch (e) {
      precios = null;
    }

    return products.map((product) {
      final productBarcodes = barcodesByProduct[product.id] ?? [];
      final precio = precios?[product.id];

      return product.copyWith(
        barcodes: productBarcodes,
        precio: precio?.priceAsDouble,
        oferta: int.tryParse(precio?.salePrice ?? '0'),
      );
    }).toList();
  }

  @override
  Future<ProductModel?> searchByBarcode(String barcode) async {
    final products = await getProducts();

    for (var product in products) {
      if (product.barcodes != null) {
        for (var productBarcode in product.barcodes!) {
          if (productBarcode.barcode.toString() == barcode) {
            return product;
          }
        }
      }
    }
    return null;
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await getProducts();

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where(
            (product) => product.categoryDescription?.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getProducts();

    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products
        .where((product) =>
            (product.description ?? "").toLowerCase().contains(lowerQuery) ||
            product.id.toString().contains(lowerQuery) ||
            (product.categoryDescription ?? "").toLowerCase().contains(lowerQuery) ||
            _hasMatchingBarcode(product, lowerQuery))
        .toList();
  }

  bool _hasMatchingBarcode(ProductModel product, String query) {
    if (product.barcodes == null) return false;

    return product.barcodes!
        .any((barcode) => barcode.barcode.toString().contains(query));
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
   if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      final response = await _dio.get(
        ApiConfig.categoriesUrl,
        options: Options(
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = response.data is String
            ? json.decode(response.data)
            : response.data;

        _cachedCategories = jsonData
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return _cachedCategories!;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Error al cargar categorías: ${response.statusCode}',
        );
      }
    } catch (e) {
      _cachedCategories = [];
      return _cachedCategories!;
    }
  }

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
    _cachedBarcodes = null;
    _cachedCategories = null;
  }
}
