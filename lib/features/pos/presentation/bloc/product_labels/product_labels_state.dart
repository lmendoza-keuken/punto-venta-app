import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class ProductLabelsState extends Equatable {
  const ProductLabelsState();

  @override
  List<Object?> get props => [];
}

class ProductLabelsInitial extends ProductLabelsState {}

class ProductLabelsLoading extends ProductLabelsState {}

class ProductLabelsLoaded extends ProductLabelsState {
  final List<Product> products;
  final List<Product> selectedProducts;
  final List<String> categories;
  final String? selectedCategoryId;
  final String searchQuery;

  const ProductLabelsLoaded({
    required this.products,
    this.selectedProducts = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        products,
        selectedProducts,
        categories,
        selectedCategoryId,
        searchQuery,
      ];

  ProductLabelsLoaded copyWith({
    List<Product>? products,
    List<Product>? selectedProducts,
    List<String>? categories,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return ProductLabelsLoaded(
      products: products ?? this.products,
      selectedProducts: selectedProducts ?? this.selectedProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductLabelsError extends ProductLabelsState {
  final String message;

  const ProductLabelsError(this.message);

  @override
  List<Object> get props => [message];
}

class ProductLabelsPrinting extends ProductLabelsState {
  final List<Product> products;

  const ProductLabelsPrinting(this.products);

  @override
  List<Object> get props => [products];
}

class ProductLabelsPrintSuccess extends ProductLabelsState {
  final int count;

  const ProductLabelsPrintSuccess(this.count);

  @override
  List<Object> get props => [count];
}

class ProductLabelsPrintError extends ProductLabelsState {
  final String message;

  const ProductLabelsPrintError(this.message);

  @override
  List<Object> get props => [message];
}
