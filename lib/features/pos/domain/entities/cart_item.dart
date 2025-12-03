import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double iva;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.iva,
  });

  double get totalPrice => (product.precio ?? 0.0) * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? iva,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      iva: iva ?? this.iva,
    );
  }

  @override
  List<Object> get props => [product, quantity];
}
