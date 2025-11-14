import 'package:json_annotation/json_annotation.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';
import 'cart_item_model.dart';

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

  const SavedOrderModel({
    required this.id,
    required this.name,
    required this.items,
    required this.total,
    required this.createdAt,
    this.clientName,
  });

  factory SavedOrderModel.fromJson(Map<String, dynamic> json) =>
      _$SavedOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$SavedOrderModelToJson(this);

  SavedOrder toEntity() {
    return SavedOrder(
      id: id,
      name: name,
      items: items.map((item) => item.toEntity()).toList(),
      total: total,
      createdAt: createdAt,
      clientName: clientName,
    );
  }

  factory SavedOrderModel.fromEntity(SavedOrder order) {
    return SavedOrderModel(
      id: order.id,
      name: order.name,
      items: order.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      total: order.total,
      createdAt: order.createdAt,
      clientName: order.clientName,
    );
  }
}
