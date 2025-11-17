import 'package:equatable/equatable.dart';
import 'cart_item.dart';

enum CartActionType { add, remove }

class CartLogEntry extends Equatable {
  final String id;
  final CartActionType type;
  final CartItem item;
  final DateTime timestamp;

  const CartLogEntry({
    required this.id,
    required this.type,
    required this.item,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, type, item, timestamp];
}
