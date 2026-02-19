import 'package:json_annotation/json_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/cart_log_entry_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'cart_item_model.dart';

part 'completed_order_model.g.dart';

@JsonSerializable()
class CompletedOrderModel {
  final String id;
  @JsonKey(name: 'order_number')
  final String orderNumber;
  final List<CartItemModel> items;
  final List<CartLogEntryModel> logs;
  final double total;
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;
  @JsonKey(name: 'client_name')
  final String? clientName;
  @JsonKey(name: 'cashier_name')
  final String cashierName;
  @JsonKey(
    name: 'payment_method',
    fromJson: _paymentMethodFromJson,
    toJson: _paymentMethodToJson,
  )
  final PaymentMethod? paymentMethod;
  @JsonKey(name: 'total_tax')
  final double totalTax;
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'show_subtotal_and_tax')
  final bool showSubtotalAndTax;
  @JsonKey(name: 'show_prices_with_tax')
  final bool showPricesWithTax;
  @JsonKey(name: 'received_amount')
  final double? receivedAmount;
  @JsonKey(name: 'change')
  final double? change;

  const CompletedOrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.logs,
    required this.total,
    required this.completedAt,
    this.clientName,
    required this.cashierName,
    this.paymentMethod,
    required this.totalTax,
    required this.totalItems,
    this.showSubtotalAndTax = false,
    this.showPricesWithTax = true,
    this.receivedAmount,
    this.change,
  });

  factory CompletedOrderModel.fromJson(Map<String, dynamic> json) =>
      _$CompletedOrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$CompletedOrderModelToJson(this);

  CompletedOrder toEntity() {
    return CompletedOrder(
      id: id,
      orderNumber: orderNumber,
      items: items.map((item) => item.toEntity()).toList(),
      logs: logs.map((log) => log.toEntity()).toList(),
      total: total,
      completedAt: completedAt,
      clientName: clientName,
      cashierName: cashierName,
      paymentMethod: paymentMethod,
      totalTax: totalTax,
      totalItems: totalItems,
      showSubtotalAndTax: showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax,
      change: change,
      receivedAmount: receivedAmount,
    );
  }

  factory CompletedOrderModel.fromEntity(CompletedOrder order) {
    return CompletedOrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      items: order.items.map((item) => CartItemModel.fromEntity(item)).toList(),
      logs: order.logs.map((log) => CartLogEntryModel.fromEntity(log)).toList(),
      total: order.total,
      completedAt: order.completedAt,
      clientName: order.clientName,
      cashierName: order.cashierName,
      paymentMethod: order.paymentMethod,
      totalTax: order.totalTax,
      totalItems: order.totalItems,
      showSubtotalAndTax: order.showSubtotalAndTax,
      showPricesWithTax: order.showPricesWithTax,
      change: order.change,
      receivedAmount: order.receivedAmount,
    );
  }
}

PaymentMethod? _paymentMethodFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return PaymentMethod(
    id: json['id'] as int,
    description: json['description'] as String,
    shortDescription: json['short_description'] as String,
    deleteAt: json['delete_at'] as String,
  );
}

Map<String, dynamic>? _paymentMethodToJson(PaymentMethod? paymentMethod) {
  if (paymentMethod == null) return null;
  return {
    'id': paymentMethod.id,
    'description': paymentMethod.description,
    'short_description': paymentMethod.shortDescription,
    'delete_at': paymentMethod.deleteAt,
  };
}
