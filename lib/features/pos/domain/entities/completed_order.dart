import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class CompletedOrder extends Equatable {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final double total;
  final DateTime completedAt;
  final String? clientName;
  final String cashierName;
  final String paymentMethod;
  final double totalTax;
  final int totalItems;

  const CompletedOrder({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.completedAt,
    this.clientName,
    required this.cashierName,
    this.paymentMethod = 'Efectivo',
    required this.totalTax,
    required this.totalItems,
  });

  CompletedOrder copyWith({
    String? id,
    String? orderNumber,
    List<CartItem>? items,
    double? total,
    DateTime? completedAt,
    String? clientName,
    String? cashierName,
    String? paymentMethod,
    double? totalTax,
    int? totalItems,
  }) {
    return CompletedOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      total: total ?? this.total,
      completedAt: completedAt ?? this.completedAt,
      clientName: clientName ?? this.clientName,
      cashierName: cashierName ?? this.cashierName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalTax: totalTax ?? this.totalTax,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        items,
        total,
        completedAt,
        clientName,
        cashierName,
        paymentMethod,
        totalTax,
        totalItems
      ];
}
