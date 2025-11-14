import 'package:equatable/equatable.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/product.dart';

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

  const ProductLoaded({
    required this.products,
    required this.categories,
    this.selectedCategory = 'Todo',
    this.searchQuery = '',
  });

  ProductLoaded copyWith({
    List<Product>? products,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object> get props =>
      [products, categories, selectedCategory, searchQuery];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
