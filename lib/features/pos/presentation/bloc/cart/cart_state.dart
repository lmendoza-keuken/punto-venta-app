import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';

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
  final List<CartLogEntry> log;

  const CartLoaded({
    required this.items,
    required this.total,
    required this.totalItems,
    required this.log,
  });

  CartLoaded copyWith({
    List<CartItem>? items,
    double? total,
    int? totalItems,
    List<CartLogEntry>? log,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      total: total ?? this.total,
      totalItems: totalItems ?? this.totalItems,
      log: log ?? this.log,
    );
  }

  @override
  List<Object> get props => [items, total, totalItems, log];
}
