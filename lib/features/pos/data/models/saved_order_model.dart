import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/saved_order.dart';
import 'cart_item_model.dart';
import 'cart_log_entry_model.dart';

part 'saved_order_model.g.dart';

@JsonSerializable()
class SavedOrderModel {
  final String id;
  final String name;
  final List<CartItemModel> items;
  final double total;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'client_name')
  final String? clientName;
  final List<CartLogEntryModel> log;

  const SavedOrderModel({
    required this.id,
    required this.name,
    required this.items,
    required this.total,
    required this.createdAt,
    this.clientName,
    this.log = const [],
  });

  factory SavedOrderModel.fromJson(Map<String, dynamic> json) =>
      _$SavedOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$SavedOrderModelToJson(this);

  SavedOrder toEntity() {
    return SavedOrder(
      id: id,
      name: name,
      items: items.map((m) => m.toEntity()).toList(),
      total: total,
      createdAt: createdAt,
      clientName: clientName,
      logs: log.map((l) => l.toEntity()).toList(),
    );
  }

  factory SavedOrderModel.fromEntity(SavedOrder order) {
    return SavedOrderModel(
      id: order.id,
      name: order.name,
      items: order.items.map((i) => CartItemModel.fromEntity(i)).toList(),
      total: order.total,
      createdAt: order.createdAt,
      clientName: order.clientName,
      log: order.logs.map((e) => CartLogEntryModel.fromEntity(e)).toList(),
    );
  }
}
