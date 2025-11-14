import 'package:json_annotation/json_annotation.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/completed_order.dart';
import 'cart_item_model.dart';

part 'completed_order_model.g.dart';

@JsonSerializable()
class CompletedOrderModel {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final List<CartItemModel> items;
  final double total;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  @JsonKey(name: 'client_name')
  final String? clientName;
  @JsonKey(name: 'cashier_name')
  final String cashierName;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'total_tax')
  final double totalTax;
  @JsonKey(name: 'total_items')
  final int totalItems;

  const CompletedOrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.completedAt,
    this.clientName,
    required this.cashierName,
    required this.paymentMethod,
    required this.totalTax,
    required this.totalItems,
  });

  factory CompletedOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CompletedOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedOrderModelToJson(this);

  CompletedOrder toEntity() {
    return CompletedOrder(
      id: id,
      orderNumber: orderNumber,
      items: items.map((item) => item.toEntity()).toList(),
      total: total,
      completedAt: completedAt,
      clientName: clientName,
      cashierName: cashierName,
      paymentMethod: paymentMethod,
      totalTax: totalTax,
      totalItems: totalItems,
    );
  }

  factory CompletedOrderModel.fromEntity(CompletedOrder order) {
    return CompletedOrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      items: order.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      total: order.total,
      completedAt: order.completedAt,
      clientName: order.clientName,
      cashierName: order.cashierName,
      paymentMethod: order.paymentMethod,
      totalTax: order.totalTax,
      totalItems: order.totalItems,
    );
  }
}
