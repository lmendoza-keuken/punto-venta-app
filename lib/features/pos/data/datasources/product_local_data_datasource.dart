import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/features/pos/data/models/category_model.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/precio_articulo_model.dart';
import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'product_local_data_datasource.g.dart';

@RestApi()
abstract class ProductService {
  factory ProductService(Dio dio, {String baseUrl}) = _ProductService;

  @GET('/articles/')
  Future<List<ProductModel>> getProducts(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});

  @GET('/barcodes/')
  Future<List<BarcodeModel>> getBarcodes(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});

  @GET('/prices_list/')
  Future<List<PrecioArticuloModel>> getPricesList(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});

  @GET('/categories/')
  Future<List<CategoryModel>> getCategories(
      {@Query('skip') int skip = 0, @Query('limit') int limit = 10000});
}

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
  ProductService get _apiService => di.sl<ProductService>();
  List<ProductModel>? _cachedProducts;
  List<PrecioArticuloModel>? _cachedPrecios;
  List<BarcodeModel>? _cachedBarcodes;
  List<CategoryModel>? _cachedCategories;
  int _listaActual;

  ProductLocalDataSourceImpl({
    int listaInicial = 1,
  })  : _listaActual = listaInicial;

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
      _cachedBarcodes = await _apiService.getBarcodes();
      return _cachedBarcodes!;
    } catch (e) {
      _cachedBarcodes = [];
      return _cachedBarcodes!;
    }
  }

  // get productos sin precios ni códigos de barras
  Future<List<ProductModel>> _fetchProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }

    try {
      final products = await _apiService.getProducts();

      // se filtran los productos no suspendidos para la venta (suspendedForSale == 'N')
      _cachedProducts =
          products.where((product) => product.suspendedForSale == 'N').toList();

      return _cachedProducts!;
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al cargar productos'));
    }
  }

  // get Lista de precios de articulos
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

  // get precios por lista de precios, se filtran los precios por el id de la lista de precios actual
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
  // se traen los productos y codigos de barras y precios según la lista de precios actual
  Future<List<ProductModel>> getProducts() async {
    // se traen los productos, códigos de barras y precios (si falla la carga de precios, se traen igual pero sin precios)
    final products = await _fetchProducts();
    final barcodes = await _fetchBarcodes();

    // se agrupan los códigos de barras por producto para facilitar la asignación a cada producto
    final barcodesByProduct = <int, List<BarcodeModel>>{};
    for (var barcode in barcodes) {
      if (!barcodesByProduct.containsKey(barcode.articleId)) {
        barcodesByProduct[barcode.articleId ?? 0] = [];
      }
      barcodesByProduct[barcode.articleId]!.add(barcode);
    }

    // se traen los precios según la lista de precios actual
    Map<int, PrecioArticuloModel>? prices;
    try {
      prices = await getPreciosByLista(_listaActual);
    } catch (e) {
      prices = null;
    }

    // se asignan los códigos de barras y precios a cada producto
    return products.map((product) {
      final productBarcodes = barcodesByProduct[product.id] ?? [];
      final price = prices?[product.id];
      final fractional = product.fractional ?? 1;

      // precio y precio regular con la cantidad fracional
      final productPrice = price?.priceAsDouble == null
          ? null
          : price!.priceAsDouble * fractional;
      final productRegularPrice = price?.regularPriceAsDouble == null
          ? null
          : price!.regularPriceAsDouble * fractional;

      return product.copyWith(
        barcodes: productBarcodes,
        price: productPrice,
        regularPrice: productRegularPrice,
        isOnSale: int.tryParse(price?.isOnSale ??
            '0'), // salePrice indica si está en oferta (ahora deberia ser con isOnSale )
      );
    }).toList();
  }

  // se busca un producto por código de barras
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

  // get productos por categoría, si la categoría es "Todo" o "All" se traen todos los productos
  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final products = await getProducts();

    if (category.toLowerCase() == 'todo' || category.toLowerCase() == 'all') {
      return products;
    }

    return products
        .where((product) =>
            product.categoryDescription?.toLowerCase() ==
            category.toLowerCase())
        .toList();
  }

  // se busca un producto por descripción, id, categoría o código de barras que contenga la query (si la query es vacía se traen todos los productos)
  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final products = await getProducts();

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

  bool _hasMatchingBarcode(ProductModel product, String query) {
    if (product.barcodes == null) return false;

    return product.barcodes!
        .any((barcode) => barcode.barcode.toString().contains(query));
  }

  // get categorías, se traen todas las categorías sin importar la lista de precios
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

  void clearCache() {
    _cachedProducts = null;
    _cachedPrecios = null;
    _cachedBarcodes = null;
    _cachedCategories = null;
  }
}
