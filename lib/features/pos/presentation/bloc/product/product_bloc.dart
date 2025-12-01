import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUsecase getProductsUsecase;
  final PriceListLocalDataSource priceListLocalDataSource;

  ProductBloc({
    required this.getProductsUsecase,
    required this.priceListLocalDataSource,
  }) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
    on<ChangePriceList>(_onChangePriceList);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      int currentList = await priceListLocalDataSource.getCurrentPriceList();
      if (currentList <= 0) {
        currentList = 13;
        await priceListLocalDataSource.savePriceList(currentList);
      }
      
      await getProductsUsecase.updatePriceList(currentList);
      
      final products = await getProductsUsecase();
      final categories = await getProductsUsecase.getCategories();

      emit(ProductLoaded(
        products: products,
        categories: categories,
        currentPriceList: currentList,
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      emit(ProductLoading());

      try {
        final products = await getProductsUsecase.getByCategory(event.category);

        emit(currentState.copyWith(
          products: products,
          selectedCategory: event.category,
          searchQuery: '',
        ));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;

      try {
        final products = await getProductsUsecase.search(event.query);

        emit(currentState.copyWith(
          products: products,
          searchQuery: event.query,
          selectedCategory:
              event.query.isEmpty ? currentState.selectedCategory : 'Todo',
        ));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
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
    emit(ProductLoading());
    
    try {
      final listId = event.listId > 0 ? event.listId : 13;
      
      await priceListLocalDataSource.savePriceList(listId);
      await getProductsUsecase.updatePriceList(listId);
      
      final products = await getProductsUsecase();
      final categories = await getProductsUsecase.getCategories();

      emit(ProductLoaded(
        products: products,
        categories: categories,
        currentPriceList: listId,
      ));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
