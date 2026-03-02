import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'cart_item.dart';

class CompletedOrder extends Equatable {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final List<CartLogEntry> logs;
  final double total;
  final DateTime completedAt;
  final String? clientName;
  final String cashierName;
  final PaymentMethod? paymentMethod;
  final double totalTax;
  final int totalItems;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final double? receivedAmount;
  final double? change;
  final String? typeCode;

  const CompletedOrder({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.logs,
    required this.total,
    required this.completedAt,
    this.clientName,
    required this.cashierName,
    required this.paymentMethod,
    required this.totalTax,
    required this.totalItems,
    this.showSubtotalAndTax = false,
    this.showPricesWithTax = true,
    this.receivedAmount,
    this.change,
    this.typeCode,
  });

  CompletedOrder copyWith({
    String? id,
    String? orderNumber,
    List<CartItem>? items,
    List<CartLogEntry>? logs,
    double? total,
    DateTime? completedAt,
    String? clientName,
    String? cashierName,
    PaymentMethod? paymentMethod,
    double? totalTax,
    int? totalItems,
    bool? showSubtotalAndTax,
    bool? showPricesWithTax,
    double? receivedAmount,
    double? change,
    String? typeCode,
  }) {
    return CompletedOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      logs: logs ?? this.logs,
      total: total ?? this.total,
      completedAt: completedAt ?? this.completedAt,
      clientName: clientName ?? this.clientName,
      cashierName: cashierName ?? this.cashierName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalTax: totalTax ?? this.totalTax,
      totalItems: totalItems ?? this.totalItems,
      showSubtotalAndTax: showSubtotalAndTax ?? this.showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax ?? this.showPricesWithTax,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      change: change ?? this.change,
      typeCode: typeCode ?? this.typeCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        items,
        logs,
        total,
        completedAt,
        clientName,
        cashierName,
        paymentMethod,
        totalTax,
        totalItems,
        showSubtotalAndTax,
        showPricesWithTax,
        receivedAmount,
        change,
        typeCode,
      ];
}
