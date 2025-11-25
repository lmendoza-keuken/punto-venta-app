import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_products_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductsUsecase getProductsUsecase;

  ProductBloc({required this.getProductsUsecase}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await getProductsUsecase();
      final categories = await getProductsUsecase.getCategories();

      emit(ProductLoaded(
        products: products,
        categories: categories,
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
}
