import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUsecase getProductsUsecase;
  final PriceListLocalDataSource priceListLocalDataSource;
  final FetchBranchesUsecase fetchBranchesUsecase;
  final FetchReturnReasonsUsecase fetchReturnReasonsUsecase;
  StreamSubscription<List<Product>>? _productsSubscription;

  ProductBloc({
    required this.getProductsUsecase,
    required this.priceListLocalDataSource,
    required this.fetchBranchesUsecase,
    required this.fetchReturnReasonsUsecase,
  }) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProductsUpdated>(_onProductsUpdated);
    on<ProductsErrorOccurred>(_onProductsErrorOccurred);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
    on<ChangePriceList>(_onChangePriceList);
    on<UpsertProduct>(_onUpsertProduct);
  }

  void _prefetchCheckoutLookups({required bool forceRefresh}) {
    unawaited(() async {
      try {
        await fetchBranchesUsecase(forceRefresh: forceRefresh);
      } catch (_) {}
    }());
    unawaited(() async {
      try {
        await fetchReturnReasonsUsecase(forceRefresh: forceRefresh);
      } catch (_) {}
    }());
  }

  /// Lookup local/API por barcode. Upsertea en el estado si hay producto.
  Future<Product?> findByBarcode(String code) async {
    try {
      final product = await getProductsUsecase.searchByBarcode(code);
      if (product == null) return null;
      add(UpsertProduct(product));
      return product;
    } catch (_) {
      return null;
    }
  }

  /// Lookup local/API por id de artículo (PLU de códigos de peso).
  Future<Product?> findByArticleId(int articleId) async {
    try {
      final product = await getProductsUsecase.searchByArticleId(articleId);
      if (product == null) return null;
      add(UpsertProduct(product));
      return product;
    } catch (_) {
      return null;
    }
  }

  void _onUpsertProduct(
    UpsertProduct event,
    Emitter<ProductState> emit,
  ) {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    final products = List<Product>.from(currentState.allProducts);
    final existingIndex =
        products.indexWhere((p) => p.id == event.product.id);
    if (existingIndex != -1) {
      products[existingIndex] = event.product;
    } else {
      products.add(event.product);
    }
    emit(currentState.copyWith(allProducts: products));
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    await _productsSubscription?.cancel();
    _productsSubscription = null;

    final forceRefresh = event.forceRefresh;

    // Branches / motivos: remote solo con refresh manual de productos.
    _prefetchCheckoutLookups(forceRefresh: forceRefresh);

    try {
      int currentList;
      if (event.priceListId != null && event.priceListId! > 0) {
        currentList = event.priceListId!;
      } else {
        currentList = await priceListLocalDataSource.getCurrentPriceList();
        if (currentList <= 0) {
          currentList = 1;
          await priceListLocalDataSource.savePriceList(currentList);
        }
      }

      // Cambia lista → limpia cache interno; misma lista conserva cache.
      await getProductsUsecase.updatePriceList(currentList);

      final readingFromCache =
          !forceRefresh && getProductsUsecase.hasFullCatalogCached;
      if (!readingFromCache) {
        emit(ProductLoading());
      }

      final categories = await getProductsUsecase.getCategories();

      _productsSubscription =
          getProductsUsecase(forceRefresh: forceRefresh).listen(
        (products) {
          add(ProductsUpdated(
            products: products,
            categories: categories,
            priceListId: currentList,
          ));
        },
        onError: (error, stackTrace) {
          add(ProductsErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void _onProductsUpdated(
    ProductsUpdated event,
    Emitter<ProductState> emit,
  ) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      if (currentState.currentPriceList == event.priceListId) {
        emit(currentState.copyWith(
          allProducts: event.products,
          categories: event.categories,
        ));
      }
    } else {
      emit(ProductLoaded(
        allProducts: event.products,
        categories: event.categories,
        currentPriceList: event.priceListId,
      ));
    }
  }

  void _onProductsErrorOccurred(
    ProductsErrorOccurred event,
    Emitter<ProductState> emit,
  ) {
    if (state is! ProductLoaded) {
      emit(ProductError(event.error));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        searchQuery: '',
      ));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(currentState.copyWith(
        searchQuery: event.query,
        selectedCategory:
            event.query.isEmpty ? currentState.selectedCategory : 'Todo',
      ));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await getProductsUsecase.getCategories();

      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        emit(currentState.copyWith(categories: categories));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onChangePriceList(
    ChangePriceList event,
    Emitter<ProductState> emit,
  ) async {
    await _productsSubscription?.cancel();
    _productsSubscription = null;

    emit(ProductLoading());

    try {
      final listId = event.listId > 0 ? event.listId : 1;

      await priceListLocalDataSource.savePriceList(listId);
      await getProductsUsecase.updatePriceList(listId);

      // se traen las categorías primero
      final categories = await getProductsUsecase.getCategories();

      // Cambio de lista invalida cache; forzar remote.
      _productsSubscription =
          getProductsUsecase(forceRefresh: true).listen(
        (products) {
          add(ProductsUpdated(
            products: products,
            categories: categories,
            priceListId: listId,
          ));
        },
        onError: (error, stackTrace) {
          add(ProductsErrorOccurred(error.toString()));
        },
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
