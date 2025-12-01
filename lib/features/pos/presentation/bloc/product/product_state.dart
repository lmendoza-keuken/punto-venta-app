import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final int currentPriceList;

  const ProductLoaded({
    required this.products,
    required this.categories,
    this.selectedCategory = 'Todo',
    this.searchQuery = '',
    this.currentPriceList = 13, 
  });

  ProductLoaded copyWith({
    List<Product>? products,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    int? currentPriceList,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPriceList: currentPriceList ?? this.currentPriceList,
    );
  }

  @override
  List<Object> get props =>
      [products, categories, selectedCategory, searchQuery, currentPriceList];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
