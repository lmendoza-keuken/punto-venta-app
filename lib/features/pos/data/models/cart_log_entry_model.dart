import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cart_log_entry.dart';
import 'cart_item_model.dart';

part 'cart_log_entry_model.g.dart';

@JsonSerializable()
class CartLogEntryModel {
  final String id;
  final String type; // 'add'|'remove'
  final CartItemModel item;
  final DateTime timestamp;

  CartLogEntryModel({
    required this.id,
    required this.type,
    required this.item,
    required this.timestamp,
  });

  factory CartLogEntryModel.fromJson(Map<String, dynamic> json) =>
      _$CartLogEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CartLogEntryModelToJson(this);

  CartLogEntry toEntity() {
    final t = type == 'add' ? CartActionType.add : CartActionType.remove;
    return CartLogEntry(
      id: id,
      type: t,
      item: item.toEntity(),
      timestamp: timestamp,
    );
  }

  factory CartLogEntryModel.fromEntity(CartLogEntry entry) {
    return CartLogEntryModel(
      id: entry.id,
      type: entry.type == CartActionType.add ? 'add' : 'remove',
      item: CartItemModel.fromEntity(entry.item),
      timestamp: entry.timestamp,
    );
  }
}
