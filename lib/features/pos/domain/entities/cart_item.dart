import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final double iva;
  final bool? isWeighted;
  final double? weightKg;
  final double? pricePerKg;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.iva,
    this.isWeighted,
    this.weightKg,
    this.pricePerKg,
  });

  double get totalPrice => (product.price ?? 0.0) * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? iva,
    bool? isWeighted,
    double? weightKg,
    double? pricePerKg,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      iva: iva ?? this.iva,
      isWeighted: isWeighted ?? this.isWeighted,
      weightKg: weightKg ?? this.weightKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
    );
  }

  @override
  List<Object?> get props => [product, quantity, isWeighted, weightKg, pricePerKg];
}
