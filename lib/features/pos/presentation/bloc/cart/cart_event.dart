import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object> get props => [product, quantity];
}

class ReplaceCart extends CartEvent {
  final List<CartItem> items;
  final List<CartLogEntry> log;

  const ReplaceCart({required this.items, this.log = const []});

  @override
  List<Object> get props => [items, log];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object> get props => [productId];
}

class RemoveQuantityFromCart extends CartEvent {
  final String productId;
  final int quantity;

  const RemoveQuantityFromCart(this.productId, this.quantity);

  @override
  List<Object> get props => [productId, quantity];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object> get props => [productId, quantity];
}

class ClearCart extends CartEvent {}
