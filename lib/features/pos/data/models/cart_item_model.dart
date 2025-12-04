import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart';

@JsonSerializable()
class CartItemModel {
  final ProductModel product;
  final int quantity;
  @JsonKey(defaultValue: 0.0)
  final double iva;
  final bool? isWeighted;
  final double? weightKg;
  final double? pricePerKg;

  const CartItemModel({
    required this.product,
    required this.quantity,
    this.iva = 0.0,
    this.isWeighted,
    this.weightKg,
    this.pricePerKg,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  CartItem toEntity() {
    return CartItem(
      product: product.toEntity(),
      quantity: quantity,
      iva: iva,
      isWeighted: isWeighted,
      weightKg: weightKg,
      pricePerKg: pricePerKg,
    );
  }

  factory CartItemModel.fromEntity(CartItem cartItem) {
    return CartItemModel(
      product: ProductModel.fromEntity(cartItem.product),
      quantity: cartItem.quantity,
      iva: cartItem.iva,
      isWeighted: cartItem.isWeighted,
      weightKg: cartItem.weightKg,
      pricePerKg: cartItem.pricePerKg,
    );
  }
}
