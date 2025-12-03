import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> searchByBarcode(String barcode);
  Future<List<String>> getCategories();
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
  int _listaActual;

  ProductLocalDataSourceImpl({
    Dio? dio,
    int listaInicial = 13,
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
        ApiConfig.barcode,
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
            .where((product) => product.suspendidoVenta == 'N')
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
      if (precio.listaPrecio == listaPrecio) {
        preciosByProducto[precio.producto] = precio;
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
      if (!barcodesByProduct.containsKey(barcode.codigo)) {
        barcodesByProduct[barcode.codigo] = [];
      }
      barcodesByProduct[barcode.codigo]!.add(barcode);
    }

    Map<int, PrecioArticuloModel>? precios;
    try {
      precios = await getPreciosByLista(_listaActual);
    } catch (e) {
      precios = null;
    }

    return products.map((product) {
      final productBarcodes = barcodesByProduct[product.codigo] ?? [];
      final precio = precios?[product.codigo];

      return product.copyWith(
        barcodes: productBarcodes,
        precio: precio?.precio,
        oferta: precio?.oferta ?? '0',
      );
    }).toList();
  }

  @override
  Future<ProductModel?> searchByBarcode(String barcode) async {
    final products = await getProducts();

    for (var product in products) {
      if (product.barcodes != null) {
        for (var productBarcode in product.barcodes!) {
          if (productBarcode.codigoBarra.toString() == barcode) {
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
            (product) => product.rubro?.toLowerCase() == category.toLowerCase())
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
            (product.rubro ?? "").toLowerCase().contains(lowerQuery) ||
            _hasMatchingBarcode(product, lowerQuery))
        .toList();
  }

  bool _hasMatchingBarcode(ProductModel product, String query) {
    if (product.barcodes == null) return false;

    return product.barcodes!
        .any((barcode) => barcode.codigoBarra.toString().contains(query));
  }

  @override
  Future<List<String>> getCategories() async {
    final products = await _fetchProducts();

    final categories = products
        .map((product) => product.rubro!)
        .where((rubro) => rubro.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();
    categories.insert(0, 'Todo');

    return categories;
  }

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
    _cachedBarcodes = null;
  }
}
