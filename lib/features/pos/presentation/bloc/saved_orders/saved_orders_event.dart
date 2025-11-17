import 'package:equatable/equatable.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/cart_item.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/cart_log_entry.dart';

abstract class SavedOrdersEvent extends Equatable {
  const SavedOrdersEvent();

  @override
  List<Object> get props => [];
}

class LoadSavedOrders extends SavedOrdersEvent {}

class SaveCurrentOrder extends SavedOrdersEvent {
  final String name;
  final List<CartItem> items;
  final List<CartLogEntry> logItems;
  final double total;
  final String? clientName;

  const SaveCurrentOrder({
    required this.name,
    required this.items,
    required this.logItems,
    required this.total,
    this.clientName,
  });

  @override
  List<Object> get props => [name, items, logItems, total, clientName ?? ''];
}

class DeleteSavedOrder extends SavedOrdersEvent {
  final String orderId;

  const DeleteSavedOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class LoadOrderById extends SavedOrdersEvent {
  final String orderId;

  const LoadOrderById(this.orderId);

  @override
  List<Object> get props => [orderId];
}
