import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class SavedOrder extends Equatable {
  final String id;
  final String name;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String? clientName;

  const SavedOrder({
    required this.id,
    required this.name,
    required this.items,
    required this.total,
    required this.createdAt,
    this.clientName,
  });

  SavedOrder copyWith({
    String? id,
    String? name,
    List<CartItem>? items,
    double? total,
    DateTime? createdAt,
    String? clientName,
  }) {
    return SavedOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      clientName: clientName ?? this.clientName,
    );
  }

  @override
  List<Object?> get props => [id, name, items, total, createdAt, clientName];
}
