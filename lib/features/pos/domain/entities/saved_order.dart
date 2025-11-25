import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'cart_item.dart';

class SavedOrder extends Equatable {
  final String id;
  final String name;
  final List<CartItem> items;
  final List<CartLogEntry> logs;
  final double total;
  final DateTime createdAt;
  final String? clientName;

  const SavedOrder({
    required this.id,
    required this.name,
    required this.items,
    required this.logs,
    required this.total,
    required this.createdAt,
    this.clientName,
  });

  SavedOrder copyWith({
    String? id,
    String? name,
    List<CartItem>? items,
    List<CartLogEntry>? logs,
    double? total,
    DateTime? createdAt,
    String? clientName,
  }) {
    return SavedOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      logs: logs ?? this.logs,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      clientName: clientName ?? this.clientName,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, items, logs, total, createdAt, clientName];
}
