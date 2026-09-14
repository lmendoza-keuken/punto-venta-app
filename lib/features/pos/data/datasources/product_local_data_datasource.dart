import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/features/pos/data/models/category_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:retrofit/retrofit.dart';

part 'product_local_data_datasource.g.dart';

// =============================================================================
// Retrofit API Service
// =============================================================================

@RestApi()
abstract class ProductService {
  factory ProductService(Dio dio, {String baseUrl}) = _ProductService;

  @GET('/articles/')
  Future<List<ProductModel>> getProducts({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 1000,
    @Query('is_suspended_sale') String? isSuspendedSale,
    @Query('list_id') int? listId,
  });

  @GET('/articles/{article_id}')
  Future<ProductModel> getProductById({
    @Path('article_id') required int articleId,
    @Query('list_id') required int listId,
  });

  @GET('/barcodes/')
  Future<List<BarcodeModel>> getBarcodes({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });

  @GET('/barcodes/{barcode_id}')
  Future<ProductModel> getProductByBarcode({
    @Path('barcode_id') required String barcodeId,
    @Query('list_id') required int listId,
  });

  @GET('/prices_list/')
  Future<List<PrecioArticuloModel>> getPricesList({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });

  @GET('/categories/')
  Future<List<CategoryModel>> getCategories({
    @Query('skip') int skip = 0,
    @Query('limit') int limit = 10000,
  });
}

// =============================================================================
// Local Data Source Interface
// =============================================================================

abstract class ProductLocalDataSource {
  Stream<List<ProductModel>> getProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> searchByBarcode(String barcode);
  Future<ProductModel?> searchByArticleId(int articleId);
  Future<List<CategoryModel>> getCategories();

  // Legacy / Compatibility methods
  Future<List<PrecioArticuloModel>> getPreciosArticulos();
  Future<Map<int, PrecioArticuloModel>> getPreciosByLista(int listaPrecio);

  void setListaPrecio(int lista);
  int getListaPrecio();
}

// =============================================================================
// Local Data Source Implementation
// =============================================================================

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final ProductService _apiService;
  int _listaActual;

  // Raw API response caches
  List<ProductModel>? _cachedProducts;
  List<BarcodeModel>? _cachedBarcodes;
  List<PrecioArticuloModel>? _cachedPrecios;
  List<CategoryModel>? _cachedCategories;

  // Optimized lookup caches
  List<ProductModel>? _cachedMappedProducts;
  Map<String, ProductModel>? _cachedBarcodeToProductMap;
  bool _isAllProductsLoaded = false;

  ProductLocalDataSourceImpl({
    int listaInicial = 1,
    ProductService? apiService,
  })  : _listaActual = listaInicial,
        _apiService = apiService ?? di.sl<ProductService>();

  // ---------------------------------------------------------------------------
  // Price List Getters & Setters
  // ---------------------------------------------------------------------------

  @override
  int getListaPrecio() => _listaActual;

  @override
  void setListaPrecio(int lista) {
    if (_listaActual == lista) return;
    _listaActual = lista;
    clearCache();
  }

  // ---------------------------------------------------------------------------
  // Core Business Methods
  // ---------------------------------------------------------------------------

  @override
  Stream<List<ProductModel>> getProducts() async* {
    debugPrint('DEBUG: ProductLocalDataSourceImpl.getProducts() started');
    if (_cachedMappedProducts != null && _cachedMappedProducts!.isNotEmpty) {
      debugPrint('DEBUG: getProducts() yielding cached products. Count: ${_cachedMappedProducts!.length}');
      yield _cachedMappedProducts!;
    }

    debugPrint('DEBUG: getProducts() fetching barcodes...');
    final barcodes = await _fetchBarcodes();
    debugPrint('DEBUG: getProducts() barcodes fetched. Count: ${barcodes.length}');

    // Agrupar los códigos de barras por id de producto para una asociación rápida
    final barcodesByProduct = <int, List<BarcodeModel>>{};
    for (var barcode in barcodes) {
      final articleId = barcode.articleId;
      if (articleId != null) {
        if (!barcodesByProduct.containsKey(articleId)) {
          barcodesByProduct[articleId] = [];
        }
        barcodesByProduct[articleId]!.add(barcode);
      }
    }

    const int chunkSize = 400;
    int skip = 0;
    bool hasMore = true;
    final Set<int> seenIds = {};
    DateTime? firstChunkResponseAt;
    DateTime? lastChunkResponseAt;
    int chunkCount = 0;

    // Inicializar cachés si es la primera carga
    _cachedMappedProducts ??= [];
    _cachedBarcodeToProductMap ??= {};

    debugPrint('DEBUG: getProducts() chunk loop starting...');
    while (hasMore) {
      try {
        debugPrint('DEBUG: getProducts() requesting chunk skip: $skip, limit: $chunkSize');
        final productsChunk = await _apiService.getProducts(
          skip: skip,
          limit: chunkSize,
          listId: _listaActual,
          isSuspendedSale: 'N',
        );
        final chunkReceivedAt = DateTime.now();
        firstChunkResponseAt ??= chunkReceivedAt;
        lastChunkResponseAt = chunkReceivedAt;
        chunkCount++;
        debugPrint(
          'DEBUG: getProducts() chunk #$chunkCount received. '
          'Count: ${productsChunk.length}, skip: $skip, at: $chunkReceivedAt',
        );

        if (productsChunk.isEmpty) {
          hasMore = false;
          _isAllProductsLoaded = true;
          break;
        }

        bool hasNewProduct = false;
        for (var p in productsChunk) {
          if (p.id != null && !seenIds.contains(p.id)) {
            seenIds.add(p.id!);
            hasNewProduct = true;
          }
        }

        if (!hasNewProduct) {
          hasMore = false;
          _isAllProductsLoaded = true;
          break;
        }

        // Si el caché fue limpiado en medio de la petición asíncrona, abortamos para evitar excepciones de nulo
        if (_cachedMappedProducts == null || _cachedBarcodeToProductMap == null) {
          hasMore = false;
          break;
        }

        final mappedChunk = productsChunk.map((product) {
          final productBarcodes = barcodesByProduct[product.id] ?? [];
          final fractional = product.fractional ?? 1;

          final productPrice =
              product.price == null ? null : product.price! * fractional;

          final productRegularPrice = product.regularPrice == null
              ? null
              : product.regularPrice! * fractional;

          final mappedProduct = product.copyWith(
            barcodes: productBarcodes,
            price: productPrice,
            regularPrice: productRegularPrice,
          );

          // Poblar el mapa de búsqueda rápida por código de barras
          for (var barcodeObj in productBarcodes) {
            if (barcodeObj.barcode != null && _cachedBarcodeToProductMap != null) {
              _cachedBarcodeToProductMap![barcodeObj.barcode.toString()] =
                  mappedProduct;
            }
          }

          return mappedProduct;
        }).toList();

        // Evitar duplicados por concurrencia y verificar nulabilidad del caché, actualizando si ya existe
        if (_cachedMappedProducts != null) {
          for (var p in mappedChunk) {
            final existingIndex =
                _cachedMappedProducts!.indexWhere((cached) => cached.id == p.id);
            if (existingIndex != -1) {
              _cachedMappedProducts![existingIndex] = p;
            } else {
              _cachedMappedProducts!.add(p);
            }
          }
          yield List<ProductModel>.from(_cachedMappedProducts!);
        } else {
          hasMore = false;
          break;
        }

        if (productsChunk.length < chunkSize) {
          hasMore = false;
          _isAllProductsLoaded = true;
        } else {
          skip += chunkSize;
        }
      } catch (e) {
        hasMore = false;
        rethrow;
      }
    }

    if (firstChunkResponseAt != null && lastChunkResponseAt != null) {
      final elapsed =
          lastChunkResponseAt.difference(firstChunkResponseAt);
      debugPrint(
        'DEBUG: getProducts() TIMING first→last chunk response: '
        '${elapsed.inMilliseconds} ms '
        '(${elapsed.inSeconds}s) | chunks: $chunkCount | '
        'products: ${_cachedMappedProducts?.length ?? 0} | '
        'first: $firstChunkResponseAt | last: $lastChunkResponseAt',
      );
    }
  }

  @override
  Future<ProductModel?> searchByBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;

    _cachedBarcodeToProductMap ??= {};
    _cachedMappedProducts ??= [];

    final cached = _cachedBarcodeToProductMap![normalized];
    if (cached != null) {
      debugPrint(
        'BARCODE_FALLBACK: DS cache HIT key=$normalized productId=${cached.id}',
      );
      return cached;
    }

    try {
        debugPrint(
        'BARCODE_FALLBACK: DS calling GET /barcodes/$normalized?list_id=$_listaActual',
      );
      final remote = await _apiService.getProductByBarcode(
        barcodeId: normalized,
        listId: _listaActual,
      );

      final fractional = remote.fractional ?? 1;
      final productPrice =
          remote.price == null ? null : remote.price! * fractional;
      final productRegularPrice = remote.regularPrice == null
          ? null
          : remote.regularPrice! * fractional;

      final barcodeValue = int.tryParse(normalized);
      final synthesizedBarcode = BarcodeModel(
        articleId: remote.id,
        barcode: barcodeValue,
        units: remote.barcodeUnits ?? 1,
        type: remote.barcodeType ?? 1,
      );

      final mappedProduct = remote.copyWith(
        barcodes: [synthesizedBarcode],
        price: productPrice,
        regularPrice: productRegularPrice,
        barcodeUnits: null,
        barcodeType: null,
      );

      _upsertMappedProduct(mappedProduct, lookupKey: normalized);
      debugPrint(
        'BARCODE_FALLBACK: DS API OK (barcode) productId=${mappedProduct.id} '
        'desc=${mappedProduct.description} price=${mappedProduct.price}',
      );
      return mappedProduct;
    } on DioException catch (e) {
      debugPrint(
        'BARCODE_FALLBACK: DS API FAIL (barcode) key=$normalized '
        'status=${e.response?.statusCode} error=$e',
      );
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<ProductModel?> searchByArticleId(int articleId) async {
    _cachedMappedProducts ??= [];
    _cachedBarcodeToProductMap ??= {};

    final byId = _cachedMappedProducts!
        .cast<ProductModel?>()
        .firstWhere((p) => p?.id == articleId, orElse: () => null);
    if (byId != null) {
      debugPrint(
        'BARCODE_FALLBACK: DS article HIT id=$articleId',
      );
      return byId;
    }

    try {
      debugPrint(
        'BARCODE_FALLBACK: DS calling GET /articles/$articleId?list_id=$_listaActual',
      );
      final remote = await _apiService.getProductById(
        articleId: articleId,
        listId: _listaActual,
      );

      final fractional = remote.fractional ?? 1;
      final productPrice =
          remote.price == null ? null : remote.price! * fractional;
      final productRegularPrice = remote.regularPrice == null
          ? null
          : remote.regularPrice! * fractional;

      // Conservar barcodes si el artículo ya venía con alguno; si no, lista vacía
      final mappedProduct = remote.copyWith(
        barcodes: remote.barcodes ?? const [],
        price: productPrice,
        regularPrice: productRegularPrice,
      );

      _upsertMappedProduct(mappedProduct);
      debugPrint(
        'BARCODE_FALLBACK: DS API OK (article) productId=${mappedProduct.id} '
        'desc=${mappedProduct.description} price=${mappedProduct.price}',
      );
      return mappedProduct;
    } on DioException catch (e) {
      debugPrint(
        'BARCODE_FALLBACK: DS API FAIL (article) id=$articleId '
        'status=${e.response?.statusCode} error=$e',
      );
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  void _upsertMappedProduct(
    ProductModel product, {
    String? lookupKey,
  }) {
    _cachedMappedProducts ??= [];
    _cachedBarcodeToProductMap ??= {};

    if (product.id != null) {
      final existingIndex =
          _cachedMappedProducts!.indexWhere((cached) => cached.id == product.id);
      if (existingIndex != -1) {
        // Si el chunk ya tenía barcodes y el fallback article no, conservar los existentes
        final existing = _cachedMappedProducts![existingIndex];
        final merged = (product.barcodes == null || product.barcodes!.isEmpty) &&
                existing.barcodes != null &&
                existing.barcodes!.isNotEmpty
            ? product.copyWith(barcodes: existing.barcodes)
            : product;
        _cachedMappedProducts![existingIndex] = merged;
        product = merged;
      } else {
        _cachedMappedProducts!.add(product);
      }
    }

    if (lookupKey != null) {
      _cachedBarcodeToProductMap![lookupKey] = product;
    }
    if (product.barcodes != null) {
      for (final barcodeObj in product.barcodes!) {
        if (barcodeObj.barcode != null) {
          _cachedBarcodeToProductMap![barcodeObj.barcode.toString()] = product;
        }
      }
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (_cachedMappedProducts == null || !_isAllProductsLoaded) {
      await getProducts().last;
    }
    final products = _cachedMappedProducts ?? [];

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where((product) =>
            product.categoryDescription?.toLowerCase() ==
            category.toLowerCase())
        .toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    if (_cachedMappedProducts == null || !_isAllProductsLoaded) {
      await getProducts().last;
    }
    final products = _cachedMappedProducts ?? [];

    if (query.isEmpty) return products;

    final lowerQuery = query.toLowerCase();
    return products
        .where((product) =>
            (product.description ?? "").toLowerCase().contains(lowerQuery) ||
            product.id.toString().contains(lowerQuery) ||
            (product.categoryDescription ?? "")
                .toLowerCase()
                .contains(lowerQuery) ||
            _hasMatchingBarcode(product, lowerQuery))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      _cachedCategories = await _apiService.getCategories();
      return _cachedCategories!;
    } catch (e) {
      _cachedCategories = [];
      return _cachedCategories!;
    }
  }

  // ---------------------------------------------------------------------------
  // Helper / Private Fetching Methods
  // ---------------------------------------------------------------------------

  Future<List<BarcodeModel>> _fetchBarcodes() async {
    debugPrint('DEBUG: _fetchBarcodes() started');
    if (_cachedBarcodes != null) {
      debugPrint('DEBUG: _fetchBarcodes() returning cached barcodes. Count: ${_cachedBarcodes!.length}');
      return _cachedBarcodes!;
    }

    try {
      debugPrint('DEBUG: _fetchBarcodes() calling API getBarcodes...');
      _cachedBarcodes = await _apiService.getBarcodes();
      debugPrint('DEBUG: _fetchBarcodes() API call success. Count: ${_cachedBarcodes!.length}');
      return _cachedBarcodes!;
    } catch (e) {
      debugPrint('DEBUG: _fetchBarcodes() API call failed. Error: $e');
      _cachedBarcodes = [];
      return _cachedBarcodes!;
    }
  }

  bool _hasMatchingBarcode(ProductModel product, String query) {
    if (product.barcodes == null) return false;
    return product.barcodes!
        .any((barcode) => barcode.barcode.toString().contains(query));
  }

  // ---------------------------------------------------------------------------
  // Cache Management
  // ---------------------------------------------------------------------------

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
    _cachedBarcodes = null;
    _cachedCategories = null;
    _cachedMappedProducts = null;
    _cachedBarcodeToProductMap = null;
    _isAllProductsLoaded = false;
  }

  // ---------------------------------------------------------------------------
  // Legacy / Compatibility Methods (Prices list are now handled by backend)
  // ---------------------------------------------------------------------------

  @override
  Future<List<PrecioArticuloModel>> getPreciosArticulos() async {
    if (_cachedPrecios != null) {
      return _cachedPrecios!;
    }

    try {
      _cachedPrecios = await _apiService.getPricesList();
      return _cachedPrecios!;
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al cargar precios'));
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
}
