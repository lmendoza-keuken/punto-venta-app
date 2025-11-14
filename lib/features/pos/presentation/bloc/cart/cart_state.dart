import 'package:equatable/equatable.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final double total;
  final int totalItems;

  const CartLoaded({
    required this.items,
    required this.total,
    required this.totalItems,
  });

  @override
  List<Object> get props => [items, total, totalItems];
}
